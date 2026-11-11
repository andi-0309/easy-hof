package io.github.andi_0309.easyhof

import android.content.Context
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.ConscryptMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
// These tests exercise JSON persistence, not TLS. Use Robolectric's
// host-compatible BouncyCastle provider for this test class.
@ConscryptMode(ConscryptMode.Mode.OFF)
class SessionStoreTest {
    private lateinit var context: Context
    @Before fun setup() {
        context = RuntimeEnvironment.getApplication()
        context.getSharedPreferences("easy_hof", Context.MODE_PRIVATE).edit().clear().commit()
    }
    private fun record(time: Long) = JSONObject().put("id", "same-id").put("updatedAt", time).put("kind", "bath").put("durationMs", 60000).put("startedAt", "2026-11-08T10:00:00Z")
    @Test fun duplicateSyncDoesNotDuplicateTraining() {
        assertTrue(SessionStore.merge(context, record(10)))
        assertFalse(SessionStore.merge(context, record(10)))
        assertEquals(1, SessionStore.all(context).size)
        assertFalse(SessionStore.merge(context, record(9)))
        assertTrue(SessionStore.merge(context, record(11)))
        assertEquals(1, SessionStore.all(context).size)
    }
    @Test fun deletedSessionCannotBeResurrectedByOfflineCopyOrClockSkew() {
        SessionStore.merge(context, record(10))
        SessionStore.merge(context, JSONObject().put("id", "same-id").put("updatedAt", 11).put("deleted", true))
        assertFalse(SessionStore.merge(context, record(999999)))
        assertTrue(SessionStore.all(context).single().getBoolean("deleted"))
        assertEquals(0, SessionStore.snapshot(context).getJSONArray("sessions").length())
    }
    @Test fun invalidBackupsDoNotEnterTheStore() {
        assertFalse(SessionStore.merge(context, record(1).put("durationMs", -1)))
        assertFalse(SessionStore.merge(context, record(1).put("temperature", "invalid")))
        assertFalse(SessionStore.merge(context, record(1).put("startedAt", "invalid")))
        assertEquals(0, SessionStore.all(context).size)
    }
    @Test fun malformedAndMismatchedDataItemsAreIgnored() {
        SessionSync.importItem(context, "/easyhof/sessions/wrong-id", record(1).toString())
        SessionSync.importItem(context, "/other/path", record(1).toString())
        SessionSync.importItem(context, "/easyhof/sessions/x", "not json")
        assertEquals(0, SessionStore.all(context).size)
    }
    @Test fun traceIsBoundedAndSurvivesPersistenceAndSync() {
        val session = record(20).put("durationMs", 7200000)
        for (ms in 0L..7200000L step 1000) HeartRateTrace.append(session, ms, 80)
        assertEquals(1441, session.getJSONArray("hrSamples").length())
        assertTrue(session.toString().length < 90000)
        assertTrue(SessionStore.valid(session))
        SessionSync.importItem(context, "/easyhof/sessions/same-id", session.toString())
        assertEquals(1441, SessionStore.all(context).single().getJSONArray("hrSamples").length())
        SessionStore.delete(context, "same-id")
        assertFalse(SessionStore.all(context).single().has("hrSamples"))
    }
    @Test fun invalidTraceSamplesAreRejected() {
        assertFalse(SessionStore.valid(record(1).put("hrSamples", org.json.JSONArray("[[0,80],[5000,999]]"))))
        assertFalse(SessionStore.valid(record(1).put("hrSamples", org.json.JSONArray("[[5000,80],[0,85]]"))))
        assertFalse(SessionStore.valid(record(1).put("hrSamples", "invalid")))
        assertTrue(SessionStore.valid(record(1)))
    }
}
