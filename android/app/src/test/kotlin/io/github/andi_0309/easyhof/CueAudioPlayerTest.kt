package io.github.andi_0309.easyhof

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import java.io.File
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.ConscryptMode
import org.robolectric.shadows.ShadowMediaPlayer
import org.robolectric.shadows.util.DataSource

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
@ConscryptMode(ConscryptMode.Mode.OFF)
class CueAudioPlayerTest {
    @Test fun inhaleAndExhaleMixWithoutTakingOrAbandoningMusicFocus() {
        val context = RuntimeEnvironment.getApplication()
        val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val musicFocus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).build()).build()
        manager.requestAudioFocus(musicFocus)
        val focusBefore = shadowOf(manager).lastAudioFocusRequest
        val players = mutableListOf<MediaPlayer>()
        val cues = CueAudioPlayer { MediaPlayer().also { players.add(it) } }
        for (cue in listOf("inhale", "exhale", "inhale", "exhale")) {
            val file = File(context.cacheDir, "$cue.mp3")
            ShadowMediaPlayer.addMediaInfo(DataSource.toDataSource(file.absolutePath), ShadowMediaPlayer.MediaInfo(3000, 0))
            cues.play(file, spoken = false)
            assertTrue(players.last().isPlaying)
            assertSame(focusBefore, shadowOf(manager).lastAudioFocusRequest)
            assertNull(shadowOf(manager).lastAbandonedAudioFocusRequest)
        }
        val last = players.last()
        cues.stop()
        assertEquals(ShadowMediaPlayer.State.END, shadowOf(last).state)
        assertSame(focusBefore, shadowOf(manager).lastAudioFocusRequest)
        assertNull(shadowOf(manager).lastAbandonedAudioFocusRequest)
    }

    @Test fun staleCompletionCannotStopTheNextCue() {
        val context = RuntimeEnvironment.getApplication()
        val file = File(context.cacheDir, "cue.mp3")
        ShadowMediaPlayer.addMediaInfo(DataSource.toDataSource(file.absolutePath), ShadowMediaPlayer.MediaInfo(3000, 0))
        val players = mutableListOf<MediaPlayer>()
        val cues = CueAudioPlayer { MediaPlayer().also { players.add(it) } }
        cues.play(file, spoken = false)
        val old = players.last()
        cues.play(file, spoken = true)
        val next = players.last()
        shadowOf(old).invokeCompletionListener()
        assertTrue(next.isPlaying)
        cues.stop()
        assertEquals(ShadowMediaPlayer.State.END, shadowOf(next).state)
    }
}
