package eu.zerver.easy_hof

import android.content.Context
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
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
}
