package io.github.andi_0309.easyhof

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import java.io.File

/** Short cues mixed over music, with bounded overlap and smooth volume envelopes. */
class CueAudioPlayer(private val factory: () -> MediaPlayer = { MediaPlayer() }) {
    companion object { const val FADE_MS = 160L }
    private data class Clip(val player: MediaPlayer, val start: Long, val duration: Int, var closing: Long? = null, var closeGain: Float = 1f)
    private val handler = Handler(Looper.getMainLooper())
    private val clips = mutableListOf<Clip>()
    private var current: Clip? = null
    private val frame = object : Runnable {
        override fun run() {
            val now = SystemClock.uptimeMillis()
            for (clip in clips.toList()) {
                try {
                    val closing = clip.closing
                    if (closing != null && now - closing >= FADE_MS) { release(clip); continue }
                    val gain = gain(clip, now)
                    clip.player.setVolume(gain, gain)
                } catch (_: Exception) { release(clip) }
            }
            if (clips.isNotEmpty()) handler.postDelayed(this, 16)
        }
    }
    private fun gain(clip: Clip, now: Long): Float {
        val attack = ((now - clip.start).toFloat() / FADE_MS).coerceIn(0f, 1f)
        val tail = ((clip.duration - (now - clip.start)).toFloat() / FADE_MS).coerceIn(0f, 1f)
        val closing = clip.closing?.let { clip.closeGain * (1f - (now - it).toFloat() / FADE_MS).coerceIn(0f, 1f) } ?: 1f
        return minOf(attack, tail, closing)
    }
    fun play(file: File, spoken: Boolean) {
        val next = factory()
        var added: Clip? = null
        try {
            next.setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(if (spoken) AudioAttributes.CONTENT_TYPE_SPEECH else AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
            next.setDataSource(file.absolutePath)
            next.setVolume(0f, 0f)
            next.prepare()
            val now = SystemClock.uptimeMillis()
            // Keep at most an outgoing cue and the new cue, even after rapid taps.
            clips.toList().filter { it !== current }.forEach { release(it) }
            current?.let { it.closeGain = gain(it, now); it.closing = now }
            val clip = Clip(next, now, next.duration.coerceAtLeast(1))
            added = clip; clips.add(clip); current = clip
            next.setOnCompletionListener { release(clip) }
            next.setOnErrorListener { _, _, _ -> release(clip); true }
            next.start()
            handler.removeCallbacks(frame); handler.post(frame)
        } catch (error: Exception) {
            if (added != null) release(added) else next.release()
            throw error
        }
    }
    private fun release(clip: Clip) {
        if (!clips.remove(clip)) return
        if (current === clip) current = null
        clip.player.release()
        if (clips.isEmpty()) handler.removeCallbacks(frame)
    }
    /** Pause, mute and leaving the app always silence every overlapping player immediately. */
    fun stop() {
        handler.removeCallbacks(frame)
        clips.toList().forEach { release(it) }
        current = null
    }
}
