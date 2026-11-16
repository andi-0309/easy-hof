package io.github.andi_0309.easyhof

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import androidx.wear.ongoing.OngoingActivity
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.ConscryptMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
@ConscryptMode(ConscryptMode.Mode.OFF)
class TrainingNotificationTest {
    @Test fun watchWorkoutsKeepTheSameResumeTargetAcrossNotificationUpdates() {
        val c = RuntimeEnvironment.getApplication()
        shadowOf(c.packageManager).setSystemFeature("android.hardware.type.watch", true)
        val manager = c.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel("test", "Training", NotificationManager.IMPORTANCE_LOW))
        for (id in listOf(41, 42)) {
            for (text in listOf("0:01", "3:00")) {
                val notification = TrainingNotification.build(c, id, "test", "Training", text)
                manager.notify(id, notification)
                val ongoing = OngoingActivity.recoverOngoingActivity(c, id)
                assertNotNull(ongoing)
                val intent = shadowOf(ongoing!!.touchIntent).savedIntent
                assertEquals(MainActivity::class.java.name, intent.component!!.className)
                assertTrue(intent.flags and Intent.FLAG_ACTIVITY_SINGLE_TOP != 0)
                assertTrue(intent.flags and Intent.FLAG_ACTIVITY_CLEAR_TOP != 0)
                assertTrue(notification.flags and Notification.FLAG_ONGOING_EVENT != 0)
            }
            manager.cancel(id)
            assertNull(OngoingActivity.recoverOngoingActivity(c, id))
        }
    }
    @Test fun coldSessionRemovesItsOngoingActivityWhenFinished() {
        val c = RuntimeEnvironment.getApplication()
        shadowOf(c.packageManager).setSystemFeature("android.hardware.type.watch", true)
        val controller = Robolectric.buildService(ColdService::class.java).create()
        controller.startCommand(0, 1)
        assertNotNull(OngoingActivity.recoverOngoingActivity(c, 41))
        controller.get().finish(false)
        assertNull(OngoingActivity.recoverOngoingActivity(c, 41))
        controller.destroy()
    }
    @Test fun phoneNotificationsDoNotBecomeWearOngoingActivities() {
        val c = RuntimeEnvironment.getApplication()
        val manager = c.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel("test", "Training", NotificationManager.IMPORTANCE_LOW))
        manager.notify(41, TrainingNotification.build(c, 41, "test", "Training"))
        assertNull(OngoingActivity.recoverOngoingActivity(c, 41))
    }
}
