package io.github.andi_0309.easyhof

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.wear.ongoing.OngoingActivity

/** Keeps an active workout as the Wear resume target without keeping the display awake. */
object TrainingNotification {
    fun build(c: Context, id: Int, channel: String, title: String, text: String? = null, stop: PendingIntent? = null, stopLabel: String = "Finish"): Notification {
        val open = PendingIntent.getActivity(c, id,
            Intent(c, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val watch = BreathingPulse.watch(c)
        val builder = NotificationCompat.Builder(c, channel)
            .setSmallIcon(R.drawable.ic_stat_cold).setContentTitle(title).setContentText(text)
            .setContentIntent(open).setOngoing(true).setOnlyAlertOnce(true)
            .setCategory(if (watch) "workout" else Notification.CATEGORY_SERVICE)
        if (stop != null) builder.addAction(0, stopLabel, stop)
        if (watch) {
            OngoingActivity.Builder(c, id, builder).setOngoingActivityId(id)
                .setStaticIcon(R.drawable.ic_stat_cold).setTouchIntent(open).build().apply(c)
        }
        return builder.build()
    }
}
