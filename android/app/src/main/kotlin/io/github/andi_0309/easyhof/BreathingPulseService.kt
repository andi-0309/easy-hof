package io.github.andi_0309.easyhof

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.*
import org.json.JSONObject

/** Started only by a visible watch activity after explicit sensor consent. */
class BreathingPulseService : Service() {
    companion object { var instance: BreathingPulseService? = null; private set }
    private val handler = Handler(Looper.getMainLooper())
    private var heart: HeartRateSource? = null
    private var hrStatus = "waiting"
    private lateinit var record: JSONObject
    private lateinit var request: JSONObject
    private val bootEpoch = System.currentTimeMillis() - SystemClock.elapsedRealtime()
    private val timeline = PulseTimeline()
    private var armedAt = 0L
    private var receivedAt = 0L
    private var sampleAt = 0L
    private var bpm: Int? = null
    private var wake: PowerManager.WakeLock? = null
    private val beat = object : Runnable {
        override fun run() {
            val now = SystemClock.elapsedRealtime()
            if ((!::record.isInitialized && now - armedAt > 180000) ||
                (::record.isInitialized && now - receivedAt > 90000)) { finish(); return }
            publish()
            handler.postDelayed(this, 5000)
        }
    }
    override fun onCreate() { super.onCreate() }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (instance != null) return START_NOT_STICKY
        val pending = BreathingPulse.request(this)
        val permission = if (Build.VERSION.SDK_INT >= 36) "android.permission.health.READ_HEART_RATE" else Manifest.permission.BODY_SENSORS
        if (!BreathingPulse.watch(this) || ColdService.instance != null || checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
            stopSelf(); return START_NOT_STICKY
        }
        armedAt = SystemClock.elapsedRealtime()
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel("breathing-pulse", "Easy Hof · Puls", NotificationManager.IMPORTANCE_LOW))
        val open = PendingIntent.getActivity(this, 3, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val notification = Notification.Builder(this, "breathing-pulse").setSmallIcon(R.drawable.ic_stat_cold)
            .setContentTitle(if (JSONObject(SessionStore.setting(this).ifBlank { "{}" }).optString("language") == "de") "Pulsmessung auf der Uhr" else "Watch heart-rate recording")
            .setContentIntent(open).setOngoing(true).build()
        if (Build.VERSION.SDK_INT >= 34) startForeground(42, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH)
        else startForeground(42, notification)
        instance = this
        wake = (getSystemService(POWER_SERVICE) as PowerManager).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "EasyHof:BreathingPulse")
            .apply { acquire(7200000L + 10000) }
        if (pending != null && !pending.optBoolean("ended") && System.currentTimeMillis() - pending.optLong("sentAt") in 0..30000) update(pending)
        handler.post(beat)
        return START_NOT_STICKY
    }
    @Synchronized fun update(next: JSONObject) {
        if (!BreathingPulse.validRequest(next)) return
        if (!::record.isInitialized) {
            if (next.optBoolean("ended") || System.currentTimeMillis() - next.optLong("sentAt") !in 0..30000) return
            request = next
            receivedAt = SystemClock.elapsedRealtime()
            timeline.update(receivedAt, next.optLong("elapsedMs"), next.optBoolean("paused"))
            record = JSONObject().put("id", next.getString("id")).put("kind", next.optString("kind", "breathing")).put("startedAt", next.getString("startedAt")).put("durationMs", next.optLong("elapsedMs"))
                .put("hrCount", 0).put("hrSum", 0)
            heart = PlatformHeartRateSource(this, { rate, time -> acceptSample(rate, time) }, { next ->
                hrStatus = next; if (next != "ok") bpm = null
            }).also { it.start() }
            return
        }
        if (next.optString("id") != request.optString("id")) { finish(); return }
        if (next.optLong("sentAt") < request.optLong("sentAt")) return
        request = next
        receivedAt = SystemClock.elapsedRealtime()
        timeline.update(receivedAt, next.optLong("elapsedMs"), next.optBoolean("paused"))
        record.put("durationMs", next.optLong("elapsedMs"))
        if (next.optBoolean("ended")) finish()
    }
    private fun acceptSample(rate: Int, time: Long) {
        if (!::record.isInitialized || time - sampleAt < 1000) return
        val duration = timeline.activeAt(time) ?: return
        sampleAt = time; bpm = rate; hrStatus = "ok"
        record.put("durationMs", maxOf(record.optLong("durationMs"), duration))
        val before = record.optJSONArray("hrSamples")?.length() ?: 0
        HeartRateTrace.append(record, duration, rate)
        if ((record.optJSONArray("hrSamples")?.length() ?: 0) > before) {
            val epochs = record.optJSONArray("hrEpochSamples") ?: org.json.JSONArray().also { record.put("hrEpochSamples", it) }
            epochs.put(org.json.JSONArray().put(bootEpoch + time).put(rate))
        }
        record.put("hrCount", record.optInt("hrCount") + 1).put("hrSum", record.optLong("hrSum") + rate)
        record.put("hrMin", minOf(record.optInt("hrMin", rate), rate)).put("hrMax", maxOf(record.optInt("hrMax", rate), rate))
        BreathingPulse.publishLive(this, snapshot())
    }
    fun snapshot(): JSONObject = (if (::record.isInitialized) JSONObject(record.toString()) else JSONObject().put("waiting", true)).put("sentAt", System.currentTimeMillis())
        .put("hrStatus", hrStatus)
        .put("bpm", if (SystemClock.elapsedRealtime() - sampleAt < 15000) bpm else JSONObject.NULL)
    private fun publish() { if (::record.isInitialized) BreathingPulse.publish(this, snapshot()) }
    fun finish() {
        if (instance !== this) return
        handler.removeCallbacks(beat); heart?.stop(); bpm = null; hrStatus = "stopped"
        if (::record.isInitialized) record.put("ended", true)
        publish(); instance = null; if (wake?.isHeld == true) wake?.release(); stopForeground(STOP_FOREGROUND_REMOVE); stopSelf()
    }
    override fun onDestroy() {
        handler.removeCallbacks(beat); heart?.stop()
        if (instance === this) { publish(); instance = null }
        if (wake?.isHeld == true) wake?.release()
        super.onDestroy()
    }
}
