package io.github.andi_0309.easyhof

import android.Manifest
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.ConscryptMode
import org.robolectric.shadows.ShadowLooper
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
@ConscryptMode(ConscryptMode.Mode.OFF)
class BreathingPulseServiceTest {
    @Test fun watchTrainingCanWaitForThePhoneAndThenEndsWithItsSession() {
        val c = RuntimeEnvironment.getApplication()
        shadowOf(c.packageManager).setSystemFeature("android.hardware.type.watch", true)
        shadowOf(c).grantPermissions(Manifest.permission.BODY_SENSORS)
        val controller = Robolectric.buildService(BreathingPulseService::class.java).create().startCommand(0, 1)
        val service = controller.get()
        assertSame(service, BreathingPulseService.instance)
        assertTrue(service.snapshot().getBoolean("waiting"))
        val request = JSONObject().put("id", "breath-test-armed").put("elapsedMs", 1000)
            .put("startedAt", "2026-11-11T10:00:00Z").put("sentAt", System.currentTimeMillis())
        service.update(request)
        assertEquals("breath-test-armed", service.snapshot().getString("id"))
        assertFalse(service.snapshot().optBoolean("waiting"))
        service.update(request.put("ended", true).put("elapsedMs", 5000))
        assertNull(BreathingPulseService.instance)
        controller.destroy()
    }
    @Test fun waitingDoesNotStartUnboundedSensorRecording() {
        val c = RuntimeEnvironment.getApplication()
        shadowOf(c.packageManager).setSystemFeature("android.hardware.type.watch", true)
        shadowOf(c).grantPermissions(Manifest.permission.BODY_SENSORS)
        val controller = Robolectric.buildService(BreathingPulseService::class.java).create().startCommand(0, 1)
        assertTrue(controller.get().snapshot().getBoolean("waiting"))
        ShadowLooper.idleMainLooper(185001, TimeUnit.MILLISECONDS)
        assertNull(BreathingPulseService.instance)
        controller.destroy()
    }
}
