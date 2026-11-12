package io.github.andi_0309.easyhof

import org.json.JSONArray
import org.json.JSONObject

/** Bounded five-second samples keep two-hour sessions below the Data Layer limit. */
object HeartRateTrace {
    const val MAX_SAMPLES = 1441
    fun append(record: JSONObject, elapsedMs: Long, bpm: Int) {
        if (bpm !in 25..240 || elapsedMs !in 0..7200000L) return
        val samples = record.optJSONArray("hrSamples") ?: JSONArray().also { record.put("hrSamples", it) }
        if (samples.length() >= MAX_SAMPLES) return
        if (samples.length() > 0 && elapsedMs - samples.getJSONArray(samples.length() - 1).getLong(0) < 5000) return
        samples.put(JSONArray().put(elapsedMs).put(bpm))
    }
    fun valid(record: JSONObject): Boolean {
        val epoch = record.optJSONArray("hrEpochSamples")
        if (record.has("hrEpochSamples") && epoch == null) return false
        if (epoch != null) {
            if (epoch.length() > MAX_SAMPLES) return false
            var lastEpoch = -1L
            for (i in 0 until epoch.length()) {
                val point = epoch.optJSONArray(i) ?: return false
                if (point.length() != 2 || point.opt(0) !is Number || point.opt(1) !is Number) return false
                val time = point.optDouble(0, Double.NaN); val rate = point.optDouble(1, Double.NaN)
                if (!time.isFinite() || time != time.toLong().toDouble() || time.toLong() !in 0..253402300799999L || time.toLong() <= lastEpoch || rate !in 25.0..240.0 || rate != rate.toInt().toDouble()) return false
                lastEpoch = time.toLong()
            }
        }
        if (!record.has("hrSamples")) return true
        val samples = record.optJSONArray("hrSamples") ?: return false
        if (samples.length() > MAX_SAMPLES) return false
        var last = -1L
        for (i in 0 until samples.length()) {
            val point = samples.optJSONArray(i) ?: return false
            if (point.length() != 2 || point.opt(0) !is Number || point.opt(1) !is Number) return false
            val time = point.optDouble(0, Double.NaN)
            val rate = point.optDouble(1, Double.NaN)
            if (!time.isFinite() || !rate.isFinite() || time != time.toLong().toDouble() || rate != rate.toInt().toDouble()) return false
            if (time.toLong() !in 0..7200000L || time.toLong() <= last || rate !in 25.0..240.0) return false
            if (time > record.optLong("durationMs") + 1000) return false
            last = time.toLong()
        }
        return true
    }
}
