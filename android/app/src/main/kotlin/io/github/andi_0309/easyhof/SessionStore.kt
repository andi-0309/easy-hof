package io.github.andi_0309.easyhof

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
    fun valid(record: JSONObject): Boolean {
        if (record.opt("id") !is String || record.opt("updatedAt") !is Number) return false
        if (!record.optString("id").matches(Regex("[A-Za-z0-9-]{1,120}")) || record.optLong("updatedAt", -1) < 0) return false
        if (record.optBoolean("deleted")) return true
        if (record.optString("kind") !in listOf("breathing", "shower", "bath")) return false
        if (record.opt("durationMs") !is Number) return false
        for (field in listOf("hrCount", "hrSum", "hrMin", "hrMax")) {
            if (record.has(field) && record.opt(field) !is Number) return false
        }
        if (record.has("temperature") && !record.isNull("temperature") && record.opt("temperature") !is Number) return false
        if (record.optLong("durationMs", -1) !in 0..86400000L) return false
        try { Instant.parse(record.getString("startedAt")) } catch (_: Exception) { return false }
        if (record.has("temperature") && !record.isNull("temperature") && record.optDouble("temperature", Double.NaN) !in -2.0..40.0) return false
        if (!HeartRateTrace.valid(record)) return false
        if (record.has("retentions")) {
            val holds = record.optJSONArray("retentions") ?: return false
            if (holds.length() > 10 || (0 until holds.length()).any { holds.opt(it) !is Number || holds.optLong(it, -1) !in 0..86400000L }) return false
        }
        if (record.optInt("hrCount") > 0 && (!record.has("hrSum") || !record.has("hrMin") || !record.has("hrMax"))) return false
        return true
    }
    @Synchronized fun merge(context: Context, incoming: JSONObject): Boolean {
        if (!valid(incoming)) return false
        if (incoming.optBoolean("deleted")) BreathingPulse.delete(context, incoming.optString("id"))
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
        HealthArchive.changed(context)
        return true
    }
    fun newSession(context: Context, record: JSONObject): JSONObject {
        record.put("id", record.optString("id").ifBlank { UUID.randomUUID().toString() })
        record.put("updatedAt", System.currentTimeMillis())
        record.put("source", if (context.packageManager.hasSystemFeature("android.hardware.type.watch")) "wear" else "phone")
        BreathingPulse.attach(context, record)
        require(valid(record)) { "Invalid session" }
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
            .put("active", ColdService.instance?.snapshot() ?: BreathingPulse.remoteCold(context) ?: JSONObject.NULL)
            .put("phoneAppAvailable", if (prefs(context).contains("phoneAppAvailable")) prefs(context).getBoolean("phoneAppAvailable", false) else JSONObject.NULL)
            .put("companionSettings", setting(context).takeIf { it.isNotBlank() }?.let { JSONObject(it) } ?: JSONObject.NULL)
            .put("breathingRequest", BreathingPulse.request(context) ?: JSONObject.NULL)
            .put("watchPulse", BreathingPulseService.instance?.snapshot() ?: JSONObject.NULL)
            .put("breathingPulse", BreathingPulse.latest(context) ?: JSONObject.NULL)
            .put("healthConnect", HealthArchive.status(context))
            .put("syncStatus", prefs(context).getString("syncStatus", "ready"))
            .put("lastReceived", prefs(context).getString("lastReceived", null))
    }
}
