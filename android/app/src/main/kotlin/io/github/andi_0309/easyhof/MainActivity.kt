package io.github.andi_0309.easyhof

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.media.MediaPlayer
import android.media.AudioManager
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import io.flutter.FlutterInjector
import java.io.File
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private var player: MediaPlayer? = null
    private var focus: AudioFocusRequest? = null
    private val cachedClips = mutableMapOf<String, File>()
    private var documentResult: MethodChannel.Result? = null
    private var permissionResult: MethodChannel.Result? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        volumeControlStream = AudioManager.STREAM_MUSIC
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "io.github.andi_0309.easyhof/device").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "watchPair", "watchInstall" -> WatchInstaller.handle(this, call, result)
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
                    "playCue" -> {
                        playCue(call.argument<String>("cue") ?: "", call.argument<String>("language") ?: "en", call.argument<Int>("seconds") ?: 3)
                        result.success(null)
                    }
                    "stopSpeech" -> { stopAudio(); result.success(null) }
                    "exportBackup", "importBackup" -> {
                        if (documentResult != null) { result.error("busy", "Document picker already active", null); return@setMethodCallHandler }
                        documentResult = result
                        val export = call.method == "exportBackup"
                        val intent = Intent(if (export) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT).apply {
                            type = "application/json"
                            addCategory(Intent.CATEGORY_OPENABLE)
                            if (export) putExtra(Intent.EXTRA_TITLE, "easy-hof-backup.json")
                        }
                        try { startActivityForResult(intent, if (export) 81 else 82) }
                        catch (e: Exception) { documentResult = null; throw e }
                    }
                    "requestHeartRate", "requestNotifications" -> {
                        if (call.method == "requestNotifications" && Build.VERSION.SDK_INT < 33) { result.success(true); return@setMethodCallHandler }
                        val permission = if (call.method == "requestNotifications") Manifest.permission.POST_NOTIFICATIONS
                            else if (Build.VERSION.SDK_INT >= 36) "android.permission.health.READ_HEART_RATE" else Manifest.permission.BODY_SENSORS
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
    private fun playCue(cue: String, language: String, seconds: Int) {
        require(language in setOf("de", "en")) { "Unknown audio language" }
        require(cue in setOf("welcome", "countdown", "inhale", "exhale", "retention", "recovery", "rest", "done")) { "Unknown audio cue" }
        stopAudio()
        require(seconds in 2..4) { "Invalid breath duration" }
        val key = if (cue == "inhale" || cue == "exhale") "breath/$cue-$seconds" else "$language/$cue"
        val file = cachedClips.getOrPut(key) {
            val path = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/audio/$key.mp3")
            File(cacheDir, "easy-hof-${key.replace('/', '-')}.mp3").also { destination ->
                assets.open(path).use { input -> destination.outputStream().use { output -> input.copyTo(output) } }
            }
        }
        val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
        val manager = getSystemService(AUDIO_SERVICE) as AudioManager
        focus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            .setAudioAttributes(attributes).setOnAudioFocusChangeListener { change -> if (change < 0) stopAudio() }.build()
        if (manager.requestAudioFocus(focus!!) != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            stopAudio(); error("Audio focus unavailable")
        }
        val next = MediaPlayer()
        player = next
        try {
            next.apply {
                setAudioAttributes(attributes)
                setDataSource(file.absolutePath)
                setOnCompletionListener { completed -> if (player === completed) stopAudio() }
                setOnErrorListener { _, _, _ -> stopAudio(); true }
                prepare()
                start()
            }
        } catch (error: Exception) { stopAudio(); throw error }
    }
    private fun stopAudio() {
        player?.release(); player = null
        focus?.let { (getSystemService(AUDIO_SERVICE) as AudioManager).abandonAudioFocusRequest(it) }
        focus = null
    }
    override fun onStop() { stopAudio(); super.onStop() }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 71) { permissionResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED); permissionResult = null }
    }
    @Deprecated("Android activity result bridge")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 81 && requestCode != 82) return
        val result = documentResult ?: return
        documentResult = null
        if (resultCode != RESULT_OK || data?.data == null) { result.success(false); return }
        try {
            if (requestCode == 81) {
                val backup = JSONObject().put("format", "easy-hof").put("version", 1)
                    .put("sessions", org.json.JSONArray(SessionStore.all(this)))
                val stream = contentResolver.openOutputStream(data.data!!, "wt") ?: error("Cannot open file")
                stream.bufferedWriter(Charsets.UTF_8).use { it.write(backup.toString(2)) }
            } else {
                val stream = contentResolver.openInputStream(data.data!!) ?: error("Cannot open file")
                val bytes = java.io.ByteArrayOutputStream().also { output ->
                    stream.use { input ->
                        val buffer = ByteArray(8192)
                        while (output.size() <= 5 * 1024 * 1024) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            output.write(buffer, 0, count)
                        }
                    }
                }.toByteArray()
                require(bytes.size <= 5 * 1024 * 1024) { "Backup is too large" }
                val backup = JSONObject(String(bytes, Charsets.UTF_8))
                require(backup.optString("format") == "easy-hof" && backup.optInt("version") == 1) { "Not an Easy Hof backup" }
                val records = backup.getJSONArray("sessions")
                val validated = (0 until records.length()).map { records.getJSONObject(it) }
                require(validated.all { SessionStore.valid(it) }) { "Invalid session in backup" }
                for (record in validated) SessionStore.merge(this, record)
                SessionSync.sync(this)
            }
            result.success(true)
        } catch (e: Exception) { result.error("backup", e.message, null) }
    }
    override fun onDestroy() {
        stopAudio()
        permissionResult?.success(false); permissionResult = null
        documentResult?.success(false); documentResult = null
        super.onDestroy()
    }
}
