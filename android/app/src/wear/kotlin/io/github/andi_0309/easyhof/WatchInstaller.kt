package io.github.andi_0309.easyhof

import android.app.Activity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object WatchInstaller {
    fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        result.error("unsupported", "Install watches from the phone app", null)
    }
}
