package io.github.andi_0309.easyhof

import android.content.Context
import androidx.health.services.client.HealthServices
import androidx.health.services.client.ExerciseUpdateCallback
import androidx.health.services.client.data.*
import com.google.common.util.concurrent.ListenableFuture

/** Health Services owns sensor configuration; we never supersede another app's workout. */
class PlatformHeartRateSource(
    context: Context,
    private val sample: (Int, Long) -> Unit,
    private val status: (String) -> Unit,
) : HeartRateSource {
    private val client = HealthServices.getClient(context).exerciseClient
    private val executor = context.mainExecutor
    private var closed = false
    private var owned = false
    private var registered = false
    private var resuming = false
    private var lastSample = -1L
    private var config: ExerciseConfig? = null
    private fun <T> after(future: ListenableFuture<T>, block: (T) -> Unit) {
        future.addListener({
            try { if (!closed) block(future.get()) } catch (_: Exception) { if (!closed) status("unavailable") }
        }, executor)
    }
    private val callback = object : ExerciseUpdateCallback {
        override fun onRegistered() {
            if (closed) { client.clearUpdateCallbackAsync(this); return }
            registered = true
            if (resuming) { status("waiting"); return }
            val future = client.startExerciseAsync(config ?: return)
            future.addListener({
                try {
                    future.get()
                    if (closed) client.endExerciseAsync() else { owned = true; status("waiting") }
                } catch (_: Exception) { if (!closed) status("unavailable") }
            }, executor)
        }
        override fun onRegistrationFailed(throwable: Throwable) { if (!closed) status("unavailable") }
        override fun onExerciseUpdateReceived(update: ExerciseUpdate) {
            if (closed) return
            if (update.exerciseStateInfo.state.isEnded) { owned = false; status("unavailable"); return }
            for (point in update.latestMetrics.getData(DataType.HEART_RATE_BPM).sortedBy { it.timeDurationFromBoot }) {
                val time = point.timeDurationFromBoot.toMillis()
                val value = point.value
                if (!value.isFinite() || value !in 25.0..240.0 || time <= lastSample) continue
                lastSample = time
                sample(value.toInt(), time)
            }
        }
        override fun onLapSummaryReceived(lapSummary: ExerciseLapSummary) { }
        override fun onAvailabilityChanged(dataType: DataType<*, *>, availability: Availability) {
            if (!closed && dataType == DataType.HEART_RATE_BPM && availability != DataTypeAvailability.AVAILABLE) status("waiting")
        }
    }
    override fun start() {
        status("waiting")
        try {
            after(client.getCurrentExerciseInfoAsync()) { info ->
                if (info.exerciseTrackedStatus == ExerciseTrackedStatus.OTHER_APP_IN_PROGRESS) {
                    status("busy"); return@after
                }
                resuming = info.exerciseTrackedStatus == ExerciseTrackedStatus.OWNED_EXERCISE_IN_PROGRESS
                owned = resuming
                after(client.getCapabilitiesAsync()) { capabilities ->
                    val type = ExerciseType.WORKOUT
                    if (type !in capabilities.supportedExerciseTypes || DataType.HEART_RATE_BPM !in capabilities.getExerciseTypeCapabilities(type).supportedDataTypes) {
                        status("unavailable"); return@after
                    }
                    config = ExerciseConfig(type, setOf(DataType.HEART_RATE_BPM), isAutoPauseAndResumeEnabled = false, isGpsEnabled = false)
                    client.setUpdateCallback(executor, callback)
                }
            }
        } catch (_: Exception) { status("unavailable") }
    }
    override fun stop() {
        if (closed) return
        closed = true
        try {
            if (owned) client.endExerciseAsync()
            if (registered) client.clearUpdateCallbackAsync(callback)
        } catch (_: Exception) { }
    }
}
