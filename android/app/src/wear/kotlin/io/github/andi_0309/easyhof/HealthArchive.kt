package io.github.andi_0309.easyhof

import android.app.Activity
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

object HealthArchive {
    fun status(c: Context) = JSONObject().put("enabled", false).put("state", "phone_only")
    fun connect(activity: Activity, result: MethodChannel.Result) { result.success(false) }
    fun permissionReturned(c: Context, code: Int, data: Intent?) { }
    fun releasePermissionRequest() { }
    fun disconnect(c: Context) { }
    fun changed(c: Context) { }
}
