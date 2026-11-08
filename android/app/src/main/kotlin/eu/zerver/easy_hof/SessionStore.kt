package eu.zerver.easy_hof

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.util.UUID

/** One durable record per session; tombstones survive reconnects. */
object SessionStore {
    private fun prefs(context: Context) = context.getSharedPreferences("easy_hof", Context.MODE_PRIVATE)
    @Synchronized fun all(context: Context): List<JSONObject> {
        val array = JSONArray(prefs(context).getString("sessions", "[]"))
        return (0 until array.length()).map { array.getJSONObject(it) }
    }
    @Synchronized fun merge(context: Context, incoming: JSONObject): Boolean {
        if (!incoming.has("id") || !incoming.has("updatedAt")) return false
        val records = all(context).toMutableList()
        val index = records.indexOfFirst { it.optString("id") == incoming.optString("id") }
        if (index >= 0) {
            val old = records[index]
            // A deleted record cannot be resurrected by an offline copy.
            if (old.optBoolean("deleted") && !incoming.optBoolean("deleted")) return false
            if (!incoming.optBoolean("deleted") && old.optLong("updatedAt") >= incoming.optLong("updatedAt")) return false
            if (old.toString() == incoming.toString()) return false
            records[index] = incoming
        } else records.add(incoming)
        check(prefs(context).edit().putString("sessions", JSONArray(records).toString()).commit()) { "Storage unavailable" }
        return true
    }
    fun newSession(context: Context, record: JSONObject): JSONObject {
        record.put("id", record.optString("id").ifBlank { UUID.randomUUID().toString() })
        record.put("updatedAt", System.currentTimeMillis())
        record.put("source", if (context.packageManager.hasSystemFeature("android.hardware.type.watch")) "wear" else "phone")
        merge(context, record)
        SessionSync.publish(context, record)
        return record
    }
    fun delete(context: Context, id: String) {
        val old = all(context).firstOrNull { it.optString("id") == id } ?: return
        val tombstone = JSONObject().put("id", id).put("deleted", true)
            .put("updatedAt", maxOf(System.currentTimeMillis(), old.optLong("updatedAt") + 1))
        merge(context, tombstone)
        SessionSync.publish(context, tombstone)
    }
    fun active(context: Context): JSONObject? = prefs(context).getString("active", null)?.let { JSONObject(it) }
    fun active(context: Context, record: JSONObject?) {
        check(prefs(context).edit().putString("active", record?.toString()).commit()) { "Storage unavailable" }
    }
    fun setting(context: Context, value: String? = null): String {
        if (value != null) check(prefs(context).edit().putString("settings", value).commit())
        return prefs(context).getString("settings", "") ?: ""
    }
    fun status(context: Context, value: String) { prefs(context).edit().putString("syncStatus", value).apply() }
    fun received(context: Context) { prefs(context).edit().putString("lastReceived", Instant.now().toString()).apply(); status(context, "received") }
    fun snapshot(context: Context): JSONObject {
        // A service killed by Android is recovered using its last durable checkpoint,
        // never by pretending it kept recording while dead.
        if (ColdService.instance == null) {
            val orphan = active(context)
            if (orphan != null) {
                orphan.put("interrupted", true).remove("bpm")
                newSession(context, orphan)
                active(context, null)
            }
        }
        val sessions = all(context).filter { !it.optBoolean("deleted") }.sortedByDescending { it.optString("startedAt") }
        return JSONObject().put("sessions", JSONArray(sessions))
            .put("active", ColdService.instance?.snapshot() ?: JSONObject.NULL)
            .put("syncStatus", prefs(context).getString("syncStatus", "ready"))
            .put("lastReceived", prefs(context).getString("lastReceived", null))
    }
}
