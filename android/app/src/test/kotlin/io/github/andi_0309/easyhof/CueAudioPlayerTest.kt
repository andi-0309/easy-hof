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
import org.robolectric.shadows.ShadowLooper
import java.util.concurrent.TimeUnit
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
    @Test fun cuesFadeInCrossfadeAndReleaseTheOutgoingPlayer() {
        val context = RuntimeEnvironment.getApplication()
        val file = File(context.cacheDir, "fade.mp3")
        ShadowMediaPlayer.addMediaInfo(DataSource.toDataSource(file.absolutePath), ShadowMediaPlayer.MediaInfo(3000, 0))
        val players = mutableListOf<MediaPlayer>()
        val cues = CueAudioPlayer { MediaPlayer().also { players.add(it) } }
        cues.play(file, spoken = false)
        val first = players.last()
        assertEquals(0f, shadowOf(first).leftVolume, 0.001f)
        ShadowLooper.idleMainLooper(80, TimeUnit.MILLISECONDS)
        assertTrue(shadowOf(first).leftVolume in 0.3f.. 0.7f)
        ShadowLooper.idleMainLooper(100, TimeUnit.MILLISECONDS)
        assertTrue(shadowOf(first).leftVolume > 0.95f)
        cues.play(file, spoken = false)
        val next = players.last()
        assertTrue(first.isPlaying)
        assertEquals(0f, shadowOf(next).leftVolume, 0.001f)
        ShadowLooper.idleMainLooper(80, TimeUnit.MILLISECONDS)
        assertTrue(shadowOf(first).leftVolume in 0.3f.. 0.7f)
        assertTrue(shadowOf(next).leftVolume in 0.3f.. 0.7f)
        ShadowLooper.idleMainLooper(100, TimeUnit.MILLISECONDS)
        assertEquals(ShadowMediaPlayer.State.END, shadowOf(first).state)
        assertTrue(shadowOf(next).leftVolume > 0.95f)
        cues.stop()
        assertEquals(ShadowMediaPlayer.State.END, shadowOf(next).state)
    }
    @Test fun naturalClipEndingAlsoFadesAndMuteStopsAllPlayers() {
        val context = RuntimeEnvironment.getApplication()
        val file = File(context.cacheDir, "ending.mp3")
        ShadowMediaPlayer.addMediaInfo(DataSource.toDataSource(file.absolutePath), ShadowMediaPlayer.MediaInfo(3000, 0))
        val players = mutableListOf<MediaPlayer>()
        val cues = CueAudioPlayer { MediaPlayer().also { players.add(it) } }
        cues.play(file, spoken = true)
        ShadowLooper.idleMainLooper(2920, TimeUnit.MILLISECONDS)
        assertTrue(shadowOf(players.last()).leftVolume in 0.3f.. 0.7f)
        cues.play(file, spoken = false)
        cues.stop()
        assertTrue(players.all { shadowOf(it).state == ShadowMediaPlayer.State.END })
        ShadowLooper.idleMainLooper(200, TimeUnit.MILLISECONDS)
    }

}
