package io.github.andi_0309.easyhof

import android.content.Context

class PlatformHeartRateSource(context: Context, sample: (Int, Long) -> Unit, private val status: (String) -> Unit) : HeartRateSource {
    override fun start() { status("unavailable") }
    override fun stop() { }
}
