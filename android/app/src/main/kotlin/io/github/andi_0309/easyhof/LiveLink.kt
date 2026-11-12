package io.github.andi_0309.easyhof

import android.content.Context
import com.google.android.gms.wearable.Wearable
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/** Best-effort direct live channel; DataItems remain the reconnect/history fallback. */
object LiveLink {
    const val STOP = "/easyhof/control/stop"
    fun send(c: Context, path: String, record: JSONObject) {
        try {
            val bytes = record.toString().toByteArray(Charsets.UTF_8)
            Wearable.getNodeClient(c).connectedNodes.addOnSuccessListener { nodes ->
                for (node in nodes) Wearable.getMessageClient(c).sendMessage(node.id, path, bytes)
            }
        } catch (_: Exception) { }
    }
    fun stopRemote(c: Context, id: String, result: MethodChannel.Result) {
        try {
            Wearable.getNodeClient(c).connectedNodes.addOnSuccessListener { nodes ->
                if (nodes.isEmpty()) { result.error("unavailable", "Watch not connected", null); return@addOnSuccessListener }
                val tasks = nodes.map { Wearable.getMessageClient(c).sendMessage(it.id, STOP, JSONObject().put("id", id).toString().toByteArray()) }
                com.google.android.gms.tasks.Tasks.whenAllComplete(tasks).addOnSuccessListener {
                    if (tasks.any { it.isSuccessful }) result.success(null) else result.error("unavailable", "Watch not reachable", null)
                }
            }.addOnFailureListener { result.error("unavailable", "Watch not connected", null) }
        } catch (_: Exception) { result.error("unavailable", "Watch not connected", null) }
    }
}
