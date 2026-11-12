package io.github.andi_0309.easyhof

import androidx.health.connect.client.records.*
import androidx.health.connect.client.records.metadata.Device
import androidx.health.connect.client.records.metadata.Metadata
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneId

object ArchiveRecords {
    fun exerciseId(id: String) = "easyhof-session-$id"
    fun pulseId(id: String) = "easyhof-pulse-$id"
    fun from(record: JSONObject): List<Record> {
        if (record.optBoolean("deleted")) return emptyList()
        val start = Instant.parse(record.getString("startedAt"))
        // Old breathing records have only an active-time clock. Do not invent wall-clock data.
        if (record.optString("kind") == "breathing" && !record.has("endedAt")) return emptyList()
        val end = record.optString("endedAt").takeIf { it.isNotBlank() }?.let { Instant.parse(it) }
            ?: start.plusMillis(record.getLong("durationMs"))
        if (end <= start) return emptyList()
        val zone = ZoneId.systemDefault().rules
        val startOffset = zone.getOffset(start)
        val endOffset = zone.getOffset(end)
        val id = record.getString("id")
        val version = record.getLong("updatedAt")
        val device = Device(type = if (record.optInt("hrCount") > 0 || record.optString("source") == "wear") Device.TYPE_WATCH else Device.TYPE_PHONE)
        val metadata = if (record.optBoolean("manual")) Metadata.manualEntry(clientRecordId = exerciseId(id), clientRecordVersion = version)
            else Metadata.activelyRecorded(clientRecordId = exerciseId(id), clientRecordVersion = version, device = device)
        val title = when(record.optString("kind")) { "bath" -> "Easy Hof · Eisbad / Ice bath"; "shower" -> "Easy Hof · Dusche / Shower"; else -> "Easy Hof · Atmen / Breathing" }
        val result = mutableListOf<Record>(ExerciseSessionRecord(startTime = start, startZoneOffset = startOffset,
            endTime = end, endZoneOffset = endOffset, metadata = metadata,
            exerciseType = ExerciseSessionRecord.EXERCISE_TYPE_OTHER_WORKOUT, title = title))
        val epoch = record.optJSONArray("hrEpochSamples")
        val trace = epoch ?: if (record.optString("kind") != "breathing") record.optJSONArray("hrSamples") else null
        val samples = mutableListOf<HeartRateRecord.Sample>()
        if (trace != null) for (i in 0 until trace.length()) {
            val point = trace.getJSONArray(i)
            val time = if (epoch != null) Instant.ofEpochMilli(point.getLong(0)) else start.plusMillis(point.getLong(0))
            if (time >= start && time < end && point.getLong(1) in 25..240) samples.add(HeartRateRecord.Sample(time, point.getLong(1)))
        }
        if (samples.isNotEmpty()) result.add(HeartRateRecord(startTime = start, startZoneOffset = startOffset,
            endTime = end, endZoneOffset = endOffset, samples = samples.distinctBy { it.time }.sortedBy { it.time },
            metadata = Metadata.activelyRecorded(clientRecordId = pulseId(id), clientRecordVersion = version, device = Device(type = Device.TYPE_WATCH))))
        return result
    }
}
