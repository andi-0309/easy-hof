package io.github.andi_0309.easyhof

import android.app.Activity
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.github.muntashirakon.adb.AbsAdbConnectionManager
import java.math.BigInteger
import java.net.InetAddress
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.cert.Certificate
import java.util.Date
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference
import javax.security.auth.x500.X500Principal

/** User-initiated, LAN-only installer. Never accepts arbitrary commands or APKs. */
object WatchInstaller {
    private val active = AtomicReference<Any?>(null)
    private val worker = Executors.newCachedThreadPool()
    private val watchdog = Executors.newSingleThreadScheduledExecutor()
    private const val alias = "easy-hof-watch-installer"

    fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        val operation = Any()
        if (!active.compareAndSet(null, operation)) {
            result.error("busy", "Watch operation already running", null); return
        }
        val answered = AtomicBoolean(false)
        worker.execute {
            var manager: AbsAdbConnectionManager? = null
            var timeout: java.util.concurrent.ScheduledFuture<*>? = null
            try {
                val host = call.argument<String>("host") ?: ""
                // Numeric private IPv4 only: no DNS lookups, loopback or public destinations.
                require(host.matches(Regex("[0-9]{1,3}(\\.[0-9]{1,3}){3}"))) { "Enter the watch's local IPv4 address" }
                require(host.split('.').all { it.toInt() in 0..255 }) { "Invalid IP address" }
                val address = InetAddress.getByName(host)
                require(address.isSiteLocalAddress && !address.isLoopbackAddress) { "Use a private Wi-Fi address" }
                val port = call.argument<Int>("port") ?: 0
                require(port in 1..65535) { "Invalid port" }
                manager = connection()
                val connection = manager
                timeout = watchdog.schedule({
                    if (answered.compareAndSet(false, true)) {
                        active.compareAndSet(operation, null)
                        activity.runOnUiThread { result.error("timeout", "Watch timed out. Check Wi-Fi, keep its debugging screen open, and retry.", null) }
                    }
                    worker.execute { try { connection.disconnect() } catch (_: Exception) {} }
                }, 180, TimeUnit.SECONDS)
                if (call.method == "watchPair") {
                    val code = call.argument<String>("code") ?: ""
                    require(code.matches(Regex("[0-9]{6}"))) { "Enter the six-digit pairing code" }
                    check(connection.pair(host, port, code)) { "Pairing failed. Request a fresh code on the watch." }
                } else {
                    // Only the watch APK embedded by the same CI job can be installed.
                    val descriptor = try { activity.assets.openFd("wear/easy-hof-wear.apk") }
                        catch (_: Exception) { error("This build has no bundled watch APK. Install the phone APK from GitHub Releases.") }
                    descriptor.use { apk ->
                        check(connection.connect(host, port)) { "Could not connect. Check the connection port (not pairing port)." }
                        check(!answered.get()) { "Operation expired" }
                        connection.openStream("shell:getprop ro.build.characteristics").use { stream ->
                            check(stream.openInputStream().bufferedReader().readText().trim().split(',').contains("watch")) { "This device is not a Wear OS watch" }
                        }
                        check(!answered.get()) { "Operation expired" }
                        connection.openStream("exec:cmd package install -r -S ${apk.length}").use { stream ->
                            apk.createInputStream().use { input -> input.copyTo(stream.openOutputStream(), 32 * 1024) }
                            // Package manager reads exactly -S bytes; closing stdin here would close the ADB stream.
                            val response = stream.openInputStream().bufferedReader().readText()
                            check(response.trim() == "Success") { "Watch installation failed: ${response.take(500)}" }
                        }
                    }
                }
                if (answered.compareAndSet(false, true)) activity.runOnUiThread { result.success(true) }
            } catch (e: Exception) {
                if (answered.compareAndSet(false, true)) activity.runOnUiThread { result.error("watch", e.message ?: "Watch connection failed", null) }
            } finally {
                timeout?.cancel(false)
                try { manager?.disconnect() } catch (_: Exception) {}
                active.compareAndSet(operation, null)
            }
        }
    }

    private fun connection(): AbsAdbConnectionManager {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (!store.containsAlias(alias)) {
            KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA, "AndroidKeyStore").apply {
                initialize(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_DECRYPT)
                    .setKeySize(2048).setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512, KeyProperties.DIGEST_NONE)
                    .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1, KeyProperties.SIGNATURE_PADDING_RSA_PSS)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setCertificateSubject(X500Principal("CN=Easy Hof"))
                    .setCertificateSerialNumber(BigInteger.ONE)
                    .setCertificateNotBefore(Date(0))
                    .setCertificateNotAfter(Date(4102444800000L)).build())
                generateKeyPair()
            }
        }
        return object : AbsAdbConnectionManager() {
            override fun getPrivateKey(): PrivateKey = store.getKey(alias, null) as PrivateKey
            override fun getCertificate(): Certificate = store.getCertificate(alias)
            override fun getDeviceName() = "Easy Hof"
        }.apply { setApi(30); setTimeout(30, TimeUnit.SECONDS) }
    }
}
