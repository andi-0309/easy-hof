package io.github.andi_0309.easyhof

import android.app.Activity
import android.os.Bundle
import android.graphics.Color
import android.widget.ScrollView
import android.widget.TextView
import io.flutter.FlutterInjector

class HealthPermissionActivity : Activity() {
    override fun onCreate(state: Bundle?) {
        super.onCreate(state)
        val language = try { org.json.JSONObject(SessionStore.setting(this)).optString("language") } catch (_: Exception) { resources.configuration.locales[0].language }
        val code = if (language == "de") "de" else "en"
        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/privacy/privacy-$code.txt")
        val policy = assets.open(key).bufferedReader().use { it.readText() }
        val text = TextView(this).apply { setText(policy); textSize = 16f; setTextColor(Color.WHITE); setPadding(32, 32, 32, 32) }
        setContentView(ScrollView(this).apply { setBackgroundColor(Color.BLACK); addView(text) })
    }
}
