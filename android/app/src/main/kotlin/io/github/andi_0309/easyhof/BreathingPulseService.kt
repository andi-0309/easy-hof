package io.github.andi_0309.easyhof

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.hardware.*
import android.os.*
import org.json.JSONObject

/** Started only by a visible watch activity after explicit sensor consent. */
class BreathingPulseService : Service(), SensorEventListener {
    companion object { var instance: BreathingPulseService? = null; private set }
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var sensors: SensorManager
    private lateinit var record: JSONObject
    private lateinit var request: JSONObject
    private var receivedAt = 0L
    private var sampleAt = 0L
    private var bpm: Int? = null
    private var wake: PowerManager.WakeLock? = null
    private val beat = object : Runnable {
        override fun run() {
            if (!::record.isInitialized) return
            if (SystemClock.elapsedRealtime() - receivedAt > 90000) { finish(); return }
            publish()
            handler.postDelayed(this, 5000)
        }
    }
    override fun onCreate() { super.onCreate(); sensors = getSystemService(SENSOR_SERVICE) as SensorManager }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (instance != null) return START_NOT_STICKY
        val pending = BreathingPulse.request(this)
        val permission = if (Build.VERSION.SDK_INT >= 36) "android.permission.health.READ_HEART_RATE" else Manifest.permission.BODY_SENSORS
        if (!BreathingPulse.watch(this) || ColdService.instance != null || pending == null || pending.optBoolean("ended") ||
            System.currentTimeMillis() - pending.optLong("sentAt") !in 0..30000 || checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
            stopSelf(); return START_NOT_STICKY
        }
        request = pending; receivedAt = SystemClock.elapsedRealtime()
        record = JSONObject().put("id", pending.getString("id")).put("durationMs", pending.optLong("elapsedMs"))
            .put("hrCount", 0).put("hrSum", 0)
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel("breathing-pulse", "Easy Hof · Puls", NotificationManager.IMPORTANCE_LOW))
        val open = PendingIntent.getActivity(this, 3, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val notification = Notification.Builder(this, "breathing-pulse").setSmallIcon(R.drawable.ic_stat_cold)
            .setContentTitle(if (pending.optString("language") == "de") "Puls beim Atemtraining" else "Breathing heart rate")
            .setContentIntent(open).setOngoing(true).build()
        if (Build.VERSION.SDK_INT >= 34) startForeground(42, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH)
        else startForeground(42, notification)
        instance = this
        wake = (getSystemService(POWER_SERVICE) as PowerManager).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "EasyHof:BreathingPulse")
            .apply { acquire(7200000L + 10000) }
        val sensor = sensors.getDefaultSensor(Sensor.TYPE_HEART_RATE)
        if (sensor != null) sensors.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
        handler.post(beat)
        return START_NOT_STICKY
    }
    @Synchronized fun update(next: JSONObject) {
        if (!::request.isInitialized || next.optString("id") != request.optString("id")) {
            finish(); return
        }
        if (next.optLong("sentAt") < request.optLong("sentAt")) return
        request = next
        receivedAt = SystemClock.elapsedRealtime()
        record.put("durationMs", next.optLong("elapsedMs"))
        if (next.optBoolean("ended")) finish()
    }
    override fun onSensorChanged(event: SensorEvent) {
        if (!::record.isInitialized) return
        val now = SystemClock.elapsedRealtime()
        if (event.accuracy <= SensorManager.SENSOR_STATUS_UNRELIABLE || event.values.firstOrNull()?.toInt() !in 25..240) { bpm = null; return }
        if (now - sampleAt < 1000 || request.optBoolean("paused") || now - receivedAt > 10000) return
        val rate = event.values[0].toInt()
        sampleAt = now; bpm = rate
        // The phone's active exercise clock excludes pauses; never invent disconnected samples.
        val elapsed = (request.optLong("elapsedMs") + now - receivedAt).coerceAtMost(7200000)
        record.put("durationMs", elapsed)
        HeartRateTrace.append(record, elapsed, rate)
        record.put("hrCount", record.optInt("hrCount") + 1).put("hrSum", record.optLong("hrSum") + rate)
        record.put("hrMin", minOf(record.optInt("hrMin", rate), rate)).put("hrMax", maxOf(record.optInt("hrMax", rate), rate))
    }
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) { if (accuracy <= 0) bpm = null }
    fun snapshot(): JSONObject = JSONObject(record.toString()).put("sentAt", System.currentTimeMillis())
        .put("bpm", if (SystemClock.elapsedRealtime() - sampleAt < 15000) bpm else JSONObject.NULL)
    private fun publish() { if (::record.isInitialized) BreathingPulse.publish(this, snapshot()) }
    fun finish() {
        if (instance !== this) return
        handler.removeCallbacks(beat); sensors.unregisterListener(this)
        publish(); instance = null; if (wake?.isHeld == true) wake?.release(); stopForeground(STOP_FOREGROUND_REMOVE); stopSelf()
    }
    override fun onDestroy() {
        handler.removeCallbacks(beat); sensors.unregisterListener(this)
        if (instance === this) { publish(); instance = null }
        if (wake?.isHeld == true) wake?.release()
        super.onDestroy()
    }
}
