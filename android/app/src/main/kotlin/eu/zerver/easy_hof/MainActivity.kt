package eu.zerver.easy_hof

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.speech.tts.TextToSpeech
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private var speech: TextToSpeech? = null
    private var speechReady = false
    private var permissionResult: MethodChannel.Result? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        speech = TextToSpeech(this, this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "eu.zerver.easyhof/device").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "snapshot" -> result.success(SessionStore.snapshot(this).toString())
                    "settings" -> result.success(SessionStore.setting(this, call.argument<String>("json")))
                    "saveSession" -> { SessionStore.newSession(this, JSONObject(call.argument<String>("json")!!)); result.success(null) }
                    "deleteSession" -> { SessionStore.delete(this, call.argument<String>("id")!!); result.success(null) }
                    "sync" -> { SessionSync.sync(this); result.success(null) }
                    "keepScreen" -> {
                        if (call.argument<Boolean>("enabled") == true) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(null)
                    }
                    "voiceAvailable" -> result.success(selectVoice(call.argument<String>("language") ?: "en"))
                    "speak" -> {
                        if (selectVoice(call.argument<String>("language") ?: "en")) speech?.speak(call.argument<String>("text"), TextToSpeech.QUEUE_FLUSH, null, "cue")
                        result.success(null)
                    }
                    "stopSpeech" -> { speech?.stop(); result.success(null) }
                    "ttsSettings" -> { startActivity(Intent("com.android.settings.TTS_SETTINGS")); result.success(null) }
                    "requestHeartRate" -> {
                        val permission = if (Build.VERSION.SDK_INT >= 36) "android.permission.health.READ_HEART_RATE" else Manifest.permission.BODY_SENSORS
                        if (checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) result.success(true)
                        else if (permissionResult != null) result.error("busy", "Permission request already active", null)
                        else { permissionResult = result; requestPermissions(arrayOf(permission), 71) }
                    }
                    "startCold" -> {
                        if (ColdService.instance != null) { result.error("active", "A session is already active", null); return@setMethodCallHandler }
                        val intent = Intent(this, ColdService::class.java)
                            .putExtra("kind", call.argument<String>("kind"))
                            .putExtra("goalSeconds", call.argument<Int>("goalSeconds") ?: 0)
                            .putExtra("heartRate", call.argument<Boolean>("heartRate") ?: false)
                            .putExtra("language", call.argument<String>("language") ?: "en")
                        call.argument<Double>("temperature")?.let { intent.putExtra("temperature", it) }
                        startForegroundService(intent)
                        result.success(null)
                    }
                    "stopCold" -> { ColdService.instance?.finish(false); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) { result.error("device", e.message ?: "Device operation failed", null) }
        }
        SessionSync.sync(this)
    }
    private fun selectVoice(language: String): Boolean {
        if (!speechReady) return false
        val voice = speech?.voices?.filter { it.locale.language == language && !it.isNetworkConnectionRequired && !it.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED) }
            ?.sortedByDescending { it.quality }?.firstOrNull() ?: return false
        return speech?.setVoice(voice) == TextToSpeech.SUCCESS
    }
    override fun onInit(status: Int) { speechReady = status == TextToSpeech.SUCCESS; speech?.setSpeechRate(1.0f) }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 71) { permissionResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED); permissionResult = null }
    }
    override fun onDestroy() {
        speech?.stop(); speech?.shutdown()
        permissionResult?.success(false); permissionResult = null
        super.onDestroy()
    }
}
