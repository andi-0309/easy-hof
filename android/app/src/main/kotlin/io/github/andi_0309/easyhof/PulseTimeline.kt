package io.github.andi_0309.easyhof

/** Maps delayed Health Services samples to known phone-clock segments without filling gaps. */
class PulseTimeline {
    private data class Checkpoint(val watchMs: Long, val activeMs: Long, val paused: Boolean)
    private val points = ArrayDeque<Checkpoint>()
    fun update(watchMs: Long, activeMs: Long, paused: Boolean) {
        if (points.isNotEmpty() && watchMs < points.last().watchMs) return
        if (points.isNotEmpty() && watchMs == points.last().watchMs) points.removeLast()
        points.addLast(Checkpoint(watchMs, activeMs, paused))
        while (points.size > 181) points.removeFirst()
    }
    fun activeAt(watchMs: Long): Long? {
        val checkpoint = points.lastOrNull { it.watchMs <= watchMs } ?: return null
        val delta = watchMs - checkpoint.watchMs
        if (checkpoint.paused || delta > 10000) return null
        return (checkpoint.activeMs + delta).takeIf { it in 0..7200000L }
    }
}
