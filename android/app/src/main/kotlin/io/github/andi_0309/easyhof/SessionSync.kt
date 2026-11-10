package io.github.andi_0309.easyhof

import android.content.Context
import android.net.Uri
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONObject

object SessionSync {
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
    fun importItem(context: Context, path: String?, json: String?) {
        if (path?.startsWith(PREFIX) != true || json == null || json.length > 90000) return
        try {
            val record = JSONObject(json)
            if (path != PREFIX + record.optString("id")) return
            if (SessionStore.merge(context, record)) SessionStore.received(context)
        } catch (_: Exception) { /* Ignore malformed remote entries, preserve local records. */ }
    }
    fun sync(context: Context) {
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
    override fun onDataChanged(events: DataEventBuffer) {
        for (event in events) if (event.type == DataEvent.TYPE_CHANGED) {
            try { SessionSync.importItem(this, event.dataItem.uri.path, DataMapItem.fromDataItem(event.dataItem).dataMap.getString("record")) }
            catch (_: Exception) { }
        }
    }
}
