package io.github.andi_0309.easyhof

import android.content.Context
import android.net.Uri
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject

/** Phone owns the exercise. Watch contributes only optional, session-keyed pulse data. */
object BreathingPulse {
    const val REQUEST = "/easyhof/breathing/request"
    const val PREFIX = "/easyhof/breathing/pulse/"
    private val fields = listOf("hrCount", "hrSum", "hrMin", "hrMax", "hrSamples", "hrEpochSamples")
    private fun prefs(c: Context) = c.getSharedPreferences("easy_hof_pulse", Context.MODE_PRIVATE)
    fun watch(c: Context) = c.packageManager.hasSystemFeature("android.hardware.type.watch")
    fun validRequest(r: JSONObject): Boolean = r.optString("id").matches(Regex("[A-Za-z0-9-]{1,120}")) &&
        r.optLong("elapsedMs", -1) in 0..7200000 && r.optLong("sentAt") > 0 && r.optString("startedAt").isNotBlank()
    fun request(c: Context): JSONObject? = prefs(c).getString("request", null)?.let { JSONObject(it) }
    fun receiveRequest(c: Context, r: JSONObject) {
        if (!watch(c) || !validRequest(r)) return
        val old = request(c)
        if (old?.optString("id") == r.optString("id") && old.optLong("sentAt") > r.optLong("sentAt")) return
        if (old?.optString("id") == r.optString("id") && old.optBoolean("ended") && !r.optBoolean("ended")) return
        prefs(c).edit().putString("request", r.toString()).apply()
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            BreathingPulseService.instance?.update(r)
            MainActivity.maybeStartPulse()
        }
    }
    fun ignoreSession(c: Context, id: String?) { prefs(c).edit().putString("ignored", id).apply() }
    fun ignored(c: Context, id: String) = prefs(c).getString("ignored", null) == id
    fun sendRequest(c: Context, r: JSONObject) {
        require(validRequest(r))
        if (!watch(c)) put(c, REQUEST, r)
    }
    private fun put(c: Context, path: String, r: JSONObject) {
        LiveLink.send(c, path, r)
        try {
            val data = PutDataMapRequest.create(path)
            data.dataMap.putString("record", r.toString())
            Wearable.getDataClient(c).putDataItem(data.asPutDataRequest().setUrgent())
        } catch (_: Exception) { /* Optional pulse must not interrupt training. */ }
    }
    fun publish(c: Context, r: JSONObject) = put(c, PREFIX + r.getString("id"), r)
    fun publishLive(c: Context, record: JSONObject) {
        val live = JSONObject(record.toString()).put("liveOnly", true)
        live.remove("hrSamples"); live.remove("hrEpochSamples")
        LiveLink.send(c, PREFIX + live.getString("id"), live)
    }
    fun validPulse(r: JSONObject): Boolean = r.optString("id").matches(Regex("[A-Za-z0-9-]{1,120}")) &&
        r.optLong("durationMs", -1) in 0..7200000 && r.optLong("sentAt") > 0 && HeartRateTrace.valid(r) &&
        r.optInt("hrCount", -1) in 0..7201 && r.optLong("hrSum", -1) in 0..1728240 &&
        (r.optInt("hrCount") == 0 || (r.optInt("hrMin") in 25..240 && r.optInt("hrMax") in 25..240)) &&
        (r.isNull("bpm") || r.optInt("bpm") in 25..240)
    @Synchronized fun receivePulse(c: Context, r: JSONObject) {
        if (watch(c) || !validPulse(r)) return
        val key = r.getString("id")
        if (SessionStore.all(c).any { it.optString("id") == key && it.optBoolean("deleted") }) return
        if (r.optBoolean("liveOnly")) {
            val previous = prefs(c).getString("live-$key", null)?.let { JSONObject(it) }
            if (previous != null && previous.optLong("sentAt") > r.optLong("sentAt")) return
            val edit = prefs(c).edit()
            val others = prefs(c).all.keys.filter { it.startsWith("live-") && it != "live-$key" }
            if (others.size >= 20) others.take(others.size - 19).forEach { edit.remove(it) }
            edit.putString("live-$key", r.toString()).putString("latest", key).apply()
            return
        }
        val old = prefs(c).getString(key, null)?.let { JSONObject(it) }
        if (old != null && (old.optLong("sentAt") > r.optLong("sentAt") || (old.optLong("sentAt") == r.optLong("sentAt") && !r.optBoolean("ended")))) return
        // Keep only a small pending cache; durable training history lives in SessionStore.
        val edit = prefs(c).edit()
        val stale = prefs(c).all.keys.filter { it !in listOf("request", "latest", "ignored") && !it.startsWith("live-") && it != key }
        if (stale.size > 19) stale.sortedBy { prefs(c).getString(it, "") }.take(stale.size - 19).forEach { edit.remove(it) }
        edit.putString(key, r.toString()).putString("latest", key).apply()
        val record = SessionStore.all(c).firstOrNull { it.optString("id") == key } ?: return
        if (record.optBoolean("deleted")) return
        val before = record.toString()
        attach(c, record)
        if (before != record.toString()) {
            record.put("updatedAt", maxOf(System.currentTimeMillis(), record.optLong("updatedAt") + 1))
            if (SessionStore.merge(c, record)) SessionSync.publish(c, record)
        }
    }
    fun attach(c: Context, record: JSONObject) {
        if (watch(c) || record.optBoolean("deleted")) return
        val pulse = prefs(c).getString(record.optString("id"), null)?.let { JSONObject(it) } ?: return
        if (!validPulse(pulse) || pulse.optInt("hrCount") <= record.optInt("hrCount")) return
        for (field in fields) if (pulse.has(field)) record.put(field, pulse.get(field))
        // Never attach points beyond the actual phone exercise timeline.
        val samples = record.optJSONArray("hrSamples")
        if (samples != null) {
            val kept = org.json.JSONArray()
            for (i in 0 until samples.length()) if (samples.getJSONArray(i).getLong(0) <= record.optLong("durationMs")) kept.put(samples.getJSONArray(i))
            record.put("hrSamples", kept)
        }
    }
    fun delete(c: Context, id: String) {
        prefs(c).edit().remove(id).remove("live-$id").apply()
        try { Wearable.getDataClient(c).deleteDataItems(Uri.parse("wear://*" + PREFIX + id)) } catch (_: Exception) { }
    }
    fun forId(c: Context, id: String): JSONObject? {
        val live = prefs(c).getString("live-$id", null)?.let { JSONObject(it) }
        val full = prefs(c).getString(id, null)?.let { JSONObject(it) }
        if (full != null && (full.optLong("sentAt") >= (live?.optLong("sentAt") ?: -1) || full.optBoolean("ended"))) return full
        if (live != null && System.currentTimeMillis() - live.optLong("sentAt") < 30000) return live
        return full
    }
    fun latest(c: Context): JSONObject? = prefs(c).getString("latest", null)?.let { forId(c, it) }
    fun remoteCold(c: Context): JSONObject? {
        if (watch(c)) return null
        val r = latest(c) ?: return null
        if (r.optString("kind") !in listOf("shower", "bath") || r.optBoolean("ended") || System.currentTimeMillis() - r.optLong("sentAt") >= 30000) return null
        if (SessionStore.all(c).any { it.optString("id") == r.optString("id") }) return null
        return JSONObject(r.toString()).put("remote", true)
    }
    fun attachLive(c: Context, record: JSONObject) {
        if (watch(c)) return
        attach(c, record)
        val live = forId(c, record.optString("id")) ?: return
        if (System.currentTimeMillis() - live.optLong("sentAt") < 30000 && !live.optBoolean("ended")) {
            record.put("bpm", live.opt("bpm") ?: JSONObject.NULL).put("hrStatus", live.optString("hrStatus", "waiting"))
        }
    }
    fun import(c: Context, path: String?, json: String?): Boolean {
        if (path != REQUEST && path?.startsWith(PREFIX) != true) return false
        if (json == null || json.length > 90000) return true
        try {
            val r = JSONObject(json)
            if (path == REQUEST) receiveRequest(c, r)
            else if (path == PREFIX + r.optString("id")) receivePulse(c, r)
        } catch (_: Exception) { }
        return true
    }
    fun sync(c: Context) {
        try {
            Wearable.getDataClient(c).getDataItems(Uri.parse("wear://*/easyhof/breathing/"), DataClient.FILTER_PREFIX)
                .addOnSuccessListener { items ->
                    try { for (item in items) import(c, item.uri.path, com.google.android.gms.wearable.DataMapItem.fromDataItem(item).dataMap.getString("record")) }
                    finally { items.release() }
                }
        } catch (_: Exception) { }
    }
}
