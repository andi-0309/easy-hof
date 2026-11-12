package io.github.andi_0309.easyhof

import android.app.Activity
import android.content.Context
import android.content.Intent
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONObject

/** Optional local Health Connect archive. No cloud account and no import of other apps' records. */
object HealthArchive {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val mutex = Mutex()
    private val permissions = setOf(HealthPermission.getWritePermission(ExerciseSessionRecord::class), HealthPermission.getWritePermission(HeartRateRecord::class))
    private var permissionResult: MethodChannel.Result? = null
    private val contract = PermissionController.createRequestPermissionResultContract()
    private fun prefs(c: Context) = c.getSharedPreferences("health_archive", Context.MODE_PRIVATE)
    fun status(c: Context): JSONObject = JSONObject().put("enabled", prefs(c).getBoolean("enabled", false))
        .put("state", prefs(c).getString("state", "off")).put("lastSync", prefs(c).getString("lastSync", null))
    fun connect(activity: Activity, result: MethodChannel.Result) {
        if (HealthConnectClient.getSdkStatus(activity) != HealthConnectClient.SDK_AVAILABLE) {
            prefs(activity).edit().putString("state", "unavailable").apply(); result.success(false); return
        }
        if (permissionResult != null) { result.error("busy", "Permission dialog already open", null); return }
        permissionResult = result
        try { activity.startActivityForResult(contract.createIntent(activity, permissions), 83) }
        catch (error: Exception) { permissionResult = null; result.error("health_connect", error.message, null) }
    }
    fun permissionReturned(c: Context, code: Int, data: Intent?) {
        val result = permissionResult ?: return
        permissionResult = null
        val granted = contract.parseResult(code, data).containsAll(permissions)
        prefs(c).edit().putBoolean("enabled", granted).putString("state", if (granted) "queued" else "permission").apply()
        if (granted) changed(c)
        result.success(granted)
    }
    fun releasePermissionRequest() { permissionResult?.success(false); permissionResult = null }
    fun disconnect(c: Context) { prefs(c).edit().putBoolean("enabled", false).putString("state", "off").apply() }
    fun changed(c: Context) {
        if (!prefs(c).getBoolean("enabled", false)) return
        val context = c.applicationContext
        scope.launch { mutex.withLock { sync(context) } }
    }
    private suspend fun sync(c: Context) {
        if (!prefs(c).getBoolean("enabled", false)) return
        try {
            if (HealthConnectClient.getSdkStatus(c) != HealthConnectClient.SDK_AVAILABLE) {
                prefs(c).edit().putString("state", "unavailable").apply(); return
            }
            val client = HealthConnectClient.getOrCreate(c)
            if (!client.permissionController.getGrantedPermissions().containsAll(permissions)) {
                prefs(c).edit().putString("state", "permission").apply(); return
            }
            for (record in SessionStore.all(c)) {
                if (!prefs(c).getBoolean("enabled", false)) return
                val id = record.getString("id")
                val version = record.getLong("updatedAt")
                if (prefs(c).getLong(id, -1) >= version) continue
                if (record.optBoolean("deleted")) {
                    client.deleteRecords(ExerciseSessionRecord::class, emptyList(), listOf(ArchiveRecords.exerciseId(id)))
                    client.deleteRecords(HeartRateRecord::class, emptyList(), listOf(ArchiveRecords.pulseId(id)))
                } else {
                    val records = ArchiveRecords.from(record)
                    if (records.isNotEmpty()) client.insertRecords(records)
                }
                prefs(c).edit().putLong(id, version).apply()
            }
            prefs(c).edit().putString("state", "synced").putString("lastSync", java.time.Instant.now().toString()).apply()
        } catch (_: SecurityException) { prefs(c).edit().putString("state", "permission").apply() }
        catch (_: Exception) { prefs(c).edit().putString("state", "error").apply() }
    }
}
