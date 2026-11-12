package io.github.andi_0309.easyhof

import android.content.Context
import android.net.Uri
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONObject

object SessionSync {
    private const val SETTINGS = "/easyhof/settings"
    private const val PREFIX = "/easyhof/sessions/"
    fun publish(context: Context, record: JSONObject) {
        try {
            val request = PutDataMapRequest.create(PREFIX + record.getString("id"))
            request.dataMap.putString("record", record.toString())
            Wearable.getDataClient(context).putDataItem(request.asPutDataRequest().setUrgent())
                .addOnSuccessListener { SessionStore.status(context, "queued") }
                .addOnFailureListener { SessionStore.status(context, "unavailable") }
        } catch (_: Exception) { SessionStore.status(context, "unavailable") }
    }
    fun publishSettings(context: Context) {
        if (BreathingPulse.watch(context)) return
        val json = SessionStore.setting(context)
        if (json.isBlank()) return
        try {
            val request = PutDataMapRequest.create(SETTINGS)
            request.dataMap.putString("record", json)
            Wearable.getDataClient(context).putDataItem(request.asPutDataRequest().setUrgent())
        } catch (_: Exception) { }
    }
    fun importItem(context: Context, path: String?, json: String?) {
        if (path == SETTINGS) {
            if (BreathingPulse.watch(context) && json != null && json.length < 2000) {
                try { val settings = JSONObject(json)
                    if (settings.optString("language") in listOf("de", "en")) SessionStore.setting(context, settings.toString())
                } catch (_: Exception) { }
            }
            return
        }
        if (BreathingPulse.import(context, path, json)) return
        if (path?.startsWith(PREFIX) != true || json == null || json.length > 90000) return
        try {
            val record = JSONObject(json)
            if (path != PREFIX + record.optString("id")) return
            if (SessionStore.merge(context, record)) SessionStore.received(context)
        } catch (_: Exception) { /* Ignore malformed remote entries, preserve local records. */ }
    }
    fun sync(context: Context) {
        BreathingPulse.sync(context)
        publishSettings(context)
        if (BreathingPulse.watch(context)) {
            try {
                Wearable.getCapabilityClient(context).getCapability("easy_hof_phone", com.google.android.gms.wearable.CapabilityClient.FILTER_ALL)
                    .addOnSuccessListener { capability -> context.getSharedPreferences("easy_hof", Context.MODE_PRIVATE).edit()
                        .putBoolean("phoneAppAvailable", capability.nodes.isNotEmpty()).apply() }
                Wearable.getDataClient(context).getDataItems(Uri.parse("wear://*/easyhof/settings"), com.google.android.gms.wearable.DataClient.FILTER_LITERAL)
                    .addOnSuccessListener { items -> try { for (item in items) importItem(context, item.uri.path, DataMapItem.fromDataItem(item).dataMap.getString("record")) } finally { items.release() } }
            } catch (_: Exception) { }
        }
        try {
            Wearable.getDataClient(context).getDataItems(Uri.parse("wear://*/easyhof/sessions"), com.google.android.gms.wearable.DataClient.FILTER_PREFIX)
                .addOnSuccessListener { items ->
                    try { for (item in items) importItem(context, item.uri.path, DataMapItem.fromDataItem(item).dataMap.getString("record")) }
                    finally { items.release() }
                    for (record in SessionStore.all(context)) publish(context, record)
                }.addOnFailureListener { SessionStore.status(context, "unavailable") }
        } catch (_: Exception) { SessionStore.status(context, "unavailable") }
    }
}

class SyncService : WearableListenerService() {
    override fun onMessageReceived(event: MessageEvent) {
        if (event.data.size > 90000) return
        if (event.path == LiveLink.STOP) {
            try {
                val id = JSONObject(String(event.data, Charsets.UTF_8)).optString("id")
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    val service = ColdService.instance
                    if (service?.snapshot()?.optString("id") == id) service.finish(false)
                }
            } catch (_: Exception) { }
        } else SessionSync.importItem(this, event.path, String(event.data, Charsets.UTF_8))
    }
    override fun onDataChanged(events: DataEventBuffer) {
        for (event in events) if (event.type == DataEvent.TYPE_CHANGED) {
            try { SessionSync.importItem(this, event.dataItem.uri.path, DataMapItem.fromDataItem(event.dataItem).dataMap.getString("record")) }
            catch (_: Exception) { }
        }
    }
}
