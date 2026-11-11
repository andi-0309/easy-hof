package io.github.andi_0309.easyhof

import android.media.AudioAttributes
import android.media.MediaPlayer
import java.io.File

/** Short, foreground training cues mixed into the media stream.
 * Do not acquire/release audio focus between cues: the user's music app keeps
 * its focus and neither side is paused/ducked by Easy Hof's own focus requests.
 */
class CueAudioPlayer(private val factory: () -> MediaPlayer = { MediaPlayer() }) {
    private var current: MediaPlayer? = null

    fun play(file: File, spoken: Boolean) {
        stop()
        val next = factory()
        current = next
        try {
            next.setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(if (spoken) AudioAttributes.CONTENT_TYPE_SPEECH else AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build())
            next.setDataSource(file.absolutePath)
            next.setVolume(1f, 1f)
            next.setOnCompletionListener { completed -> if (current === completed) stop() }
            next.setOnErrorListener { failed, _, _ -> if (current === failed) stop(); true }
            next.prepare()
            next.start()
        } catch (error: Exception) {
            if (current === next) stop()
            throw error
        }
    }

    fun stop() {
        val previous = current
        current = null
        previous?.release()
    }
}
