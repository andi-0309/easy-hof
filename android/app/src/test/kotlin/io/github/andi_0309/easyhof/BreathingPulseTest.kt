package io.github.andi_0309.easyhof

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.ConscryptMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
@ConscryptMode(ConscryptMode.Mode.OFF)
class BreathingPulseTest {
    private fun record() = JSONObject().put("id", "breath-unit-test").put("kind", "breathing")
        .put("startedAt", "2026-11-11T10:00:00Z").put("durationMs", 15000).put("updatedAt", 1)
        .put("retentions", JSONArray().put(8000))
    private fun pulse(sent: Long = 10) = JSONObject().put("id", "breath-unit-test").put("durationMs", 12000)
        .put("sentAt", sent).put("bpm", 80).put("hrCount", 2).put("hrSum", 150)
        .put("hrMin", 70).put("hrMax", 80).put("hrSamples", JSONArray().put(JSONArray().put(5000).put(70)).put(JSONArray().put(10000).put(80)))
    @Test fun validatesTraceAndRejectsInvalidRequestOrOversizedPulse() {
        assertTrue(BreathingPulse.validPulse(pulse()))
        assertFalse(BreathingPulse.validPulse(pulse().put("bpm", 999)))
        assertFalse(BreathingPulse.validPulse(pulse().put("durationMs", 100)))
        assertFalse(BreathingPulse.validPulse(pulse().put("hrCount", 8000)))
        assertFalse(BreathingPulse.validRequest(JSONObject().put("id", "../bad")))
    }
    @Test fun pendingPulseAttachesToPhoneRecordWithoutLosingBreathingMetadata() {
        val c = RuntimeEnvironment.getApplication()
        BreathingPulse.receivePulse(c, pulse())
        val r = record()
        BreathingPulse.attach(c, r)
        assertEquals(2, r.getInt("hrCount"))
        assertEquals(8000, r.getJSONArray("retentions").getInt(0))
        assertEquals(15000, r.getLong("durationMs"))
        assertTrue(SessionStore.valid(r))
    }
    @Test fun latePulseUpdatesExistingSessionAndIgnoresOlderDeliveries() {
        val c = RuntimeEnvironment.getApplication()
        SessionStore.merge(c, record())
        BreathingPulse.receivePulse(c, pulse(20))
        BreathingPulse.receivePulse(c, pulse(10).put("hrCount", 1))
        val r = SessionStore.all(c).single()
        assertEquals(2, r.getInt("hrCount"))
        assertEquals("breathing", r.getString("kind"))
        assertEquals(1, r.getJSONArray("retentions").length())
    }
    @Test fun deletionCannotBeUndoneByLatePulse() {
        val c = RuntimeEnvironment.getApplication()
        SessionStore.merge(c, JSONObject().put("id", "breath-unit-test").put("deleted", true).put("updatedAt", 100))
        BreathingPulse.receivePulse(c, pulse())
        val r = SessionStore.all(c).single()
        assertTrue(r.getBoolean("deleted"))
        assertFalse(r.has("hrSamples"))
    }
}
