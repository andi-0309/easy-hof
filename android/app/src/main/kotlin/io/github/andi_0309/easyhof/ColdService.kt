package io.github.andi_0309.easyhof

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.hardware.*
import android.os.*
import org.json.JSONObject
import java.time.Instant
import java.util.UUID

class ColdService : Service(), SensorEventListener {
    companion object { var instance: ColdService? = null; private set }
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var record: JSONObject
    private lateinit var sensors: SensorManager
    private var wake: PowerManager.WakeLock? = null
    private var startElapsed = 0L
    private var lastSample = 0L
    private var lastCheckpoint = 0L
    private var bpm: Int? = null
    private var status = "denied"
    private var german = true
    private val beat = object : Runnable {
        override fun run() {
            if (!::record.isInitialized) return
            val elapsed = SystemClock.elapsedRealtime() - startElapsed
            record.put("durationMs", elapsed)
            val goal = record.optInt("goalSeconds") * 1000L
            if (goal > 0 && elapsed >= goal && !record.optBoolean("goalReached")) {
                record.put("goalReached", true)
                vibrate()
            }
            if (elapsed - lastCheckpoint >= 5000) { checkpoint(); lastCheckpoint = elapsed }
            if (elapsed >= 7200000) { finish(true); return }
            getSystemService(NotificationManager::class.java).notify(41, notification())
            handler.postDelayed(this, 1000)
        }
    }
    override fun onCreate() { super.onCreate(); sensors = getSystemService(SENSOR_SERVICE) as SensorManager }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") { if (::record.isInitialized) finish(false) else stopSelf(); return START_NOT_STICKY }
        if (::record.isInitialized) return START_NOT_STICKY
        german = intent?.getStringExtra("language") != "en"
        val permission = if (Build.VERSION.SDK_INT >= 36) "android.permission.health.READ_HEART_RATE" else Manifest.permission.BODY_SENSORS
        val hasHr = intent?.getBooleanExtra("heartRate", false) == true && checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel("training", "Easy Hof", NotificationManager.IMPORTANCE_LOW))
        startElapsed = SystemClock.elapsedRealtime()
        record = JSONObject().put("id", UUID.randomUUID().toString()).put("kind", intent?.getStringExtra("kind") ?: "shower")
            .put("startedAt", Instant.now().toString()).put("durationMs", 0).put("goalSeconds", intent?.getIntExtra("goalSeconds", 0) ?: 0)
            .put("goalReached", false).put("hrCount", 0).put("hrSum", 0)
        if (intent?.hasExtra("temperature") == true) record.put("temperature", intent.getDoubleExtra("temperature", 5.0))
        if (Build.VERSION.SDK_INT >= 34) startForeground(41, notification(), if (hasHr) ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH else ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        else startForeground(41, notification())
        instance = this
        checkpoint()
        wake = (getSystemService(POWER_SERVICE) as PowerManager).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "EasyHof:ColdSession").apply { acquire(2 * 60 * 60 * 1000L + 10000) }
        if (hasHr) {
            val sensor = sensors.getDefaultSensor(Sensor.TYPE_HEART_RATE)
            status = if (sensor == null) "unavailable" else "waiting"
            if (sensor != null && !sensors.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)) status = "unavailable"
        }
        handler.post(beat)
        return START_NOT_STICKY
    }
    private fun notification(): Notification {
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val stop = PendingIntent.getService(this, 1, Intent(this, ColdService::class.java).setAction("STOP"), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val secs = if (::record.isInitialized) record.optLong("durationMs") / 1000 else 0
        return Notification.Builder(this, "training").setSmallIcon(R.drawable.ic_stat_cold)
            .setContentTitle(if (german) "Kältetraining läuft" else "Cold training running")
            .setContentText("%d:%02d".format(secs / 60, secs % 60)).setContentIntent(open).setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .addAction(Notification.Action.Builder(null, if (german) "Beenden" else "Finish", stop).build()).build()
    }
    private fun checkpoint() { SessionStore.active(this, record) }
    fun snapshot(): JSONObject {
        val result = JSONObject(record.toString()).put("durationMs", SystemClock.elapsedRealtime() - startElapsed)
        val fresh = bpm != null && SystemClock.elapsedRealtime() - lastSample < 30000
        result.put("bpm", if (fresh) bpm else JSONObject.NULL)
        result.put("hrStatus", if (!fresh && bpm != null) "stale" else status)
        return result
    }
    fun finish(interrupted: Boolean) {
        handler.removeCallbacks(beat)
        record.put("durationMs", SystemClock.elapsedRealtime() - startElapsed).put("interrupted", interrupted)
        SessionStore.newSession(this, record)
        SessionStore.active(this, null)
        sensors.unregisterListener(this)
        if (wake?.isHeld == true) wake?.release()
        instance = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }
    override fun onSensorChanged(event: SensorEvent) {
        val rate = event.values.firstOrNull()?.toInt() ?: return
        if (event.accuracy == SensorManager.SENSOR_STATUS_UNRELIABLE || event.accuracy == SensorManager.SENSOR_STATUS_NO_CONTACT || rate !in 25..240) {
            status = "unreliable"; bpm = null; return
        }
        val now = SystemClock.elapsedRealtime()
        if (now - lastSample < 1000) return
        lastSample = now; bpm = rate; status = "ok"
        record.put("durationMs", now - startElapsed)
        HeartRateTrace.append(record, now - startElapsed, rate)
        record.put("hrCount", record.optInt("hrCount") + 1).put("hrSum", record.optLong("hrSum") + rate)
        record.put("hrMin", minOf(record.optInt("hrMin", rate), rate)).put("hrMax", maxOf(record.optInt("hrMax", rate), rate))
    }
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        if (accuracy <= SensorManager.SENSOR_STATUS_UNRELIABLE) { status = "unreliable"; bpm = null }
    }
    private fun vibrate() {
        val settings = SessionStore.setting(this, null)
        if (settings.isNotBlank() && !JSONObject(settings).optBoolean("haptics", true)) return
        val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
        vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 600, 180, 600, 180, 900), intArrayOf(0, 255, 0, 255, 0, 255), -1))
    }
    override fun onDestroy() {
        handler.removeCallbacks(beat); sensors.unregisterListener(this)
        if (wake?.isHeld == true) wake?.release()
        if (instance === this) { checkpoint(); instance = null }
        super.onDestroy()
    }
}
