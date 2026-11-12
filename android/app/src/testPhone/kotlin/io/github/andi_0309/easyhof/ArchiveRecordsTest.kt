package io.github.andi_0309.easyhof

import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.ConscryptMode
import java.time.Instant

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
@ConscryptMode(ConscryptMode.Mode.OFF)
class ArchiveRecordsTest {
    private fun cold() = JSONObject().put("id", "archive-test").put("kind", "bath")
        .put("startedAt", "2026-11-12T10:00:00Z").put("durationMs", 300000).put("updatedAt", 12)
    @Test fun manualTrainingHasStableIdentityWithoutInventedPulse() {
        val records = ArchiveRecords.from(cold().put("manual", true))
        assertEquals(1, records.size)
        val exercise = records.single() as ExerciseSessionRecord
        assertEquals("easyhof-session-archive-test", exercise.metadata.clientRecordId)
        assertEquals(12L, exercise.metadata.clientRecordVersion)
        assertEquals(Instant.parse("2026-11-12T10:05:00Z"), exercise.endTime)
    }
    @Test fun breathingUsesOriginalWallClockSamplesAcrossPauses() {
        val start = Instant.parse("2026-11-12T10:00:00Z").toEpochMilli()
        val record = cold().put("kind", "breathing").put("durationMs", 15000)
            .put("endedAt", "2026-11-12T10:01:00Z")
            .put("hrEpochSamples", JSONArray().put(JSONArray().put(start + 45000).put(80)))
        val records = ArchiveRecords.from(record)
        val pulse = records.filterIsInstance<HeartRateRecord>().single()
        assertEquals(Instant.ofEpochMilli(start + 45000), pulse.samples.single().time)
        assertEquals(80L, pulse.samples.single().beatsPerMinute)
        assertEquals("easyhof-pulse-archive-test", pulse.metadata.clientRecordId)
    }
    @Test fun legacyBreathingAndDeletedRecordsStayOutOfArchive() {
        assertTrue(ArchiveRecords.from(cold().put("kind", "breathing")).isEmpty())
        assertTrue(ArchiveRecords.from(cold().put("deleted", true)).isEmpty())
    }
    @Test fun invalidOrOutOfSessionSamplesAreExcluded() {
        val record = cold().put("hrSamples", JSONArray()
            .put(JSONArray().put(5000).put(80))
            .put(JSONArray().put(300000).put(90))
            .put(JSONArray().put(10000).put(999)))
        val pulse = ArchiveRecords.from(record).filterIsInstance<HeartRateRecord>().single()
        assertEquals(1, pulse.samples.size)
    }
}
