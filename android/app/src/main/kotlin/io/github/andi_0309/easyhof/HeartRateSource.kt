package io.github.andi_0309.easyhof

/** Original monotonic sample timestamp is retained, including batched platform data. */
interface HeartRateSource {
    fun start()
    fun stop()
}
