package io.github.andi_0309.easyhof

import android.view.InputDevice
import android.view.MotionEvent
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.ConscryptMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
@ConscryptMode(ConscryptMode.Mode.OFF)
class RotaryInputTest {
    private fun event(source: Int, action: Int = MotionEvent.ACTION_SCROLL): MotionEvent {
        val coords = MotionEvent.PointerCoords().apply { setAxisValue(MotionEvent.AXIS_SCROLL, 2f) }
        val pointer = MotionEvent.PointerProperties().apply { id = 0 }
        return MotionEvent.obtain(0, 0, action, 1, arrayOf(pointer), arrayOf(coords), 0, 0, 1f, 1f, 0, 0, source, 0)
    }
    @Test fun crownScrollUsesLogicalPixelsAndPreservesDirection() {
        val e = event(InputDevice.SOURCE_ROTARY_ENCODER)
        assertEquals(-64.0, RotaryInput.delta(e, 64f, 2f)!!, 0.001)
        e.recycle()
    }
    @Test fun ordinaryMouseScrollAndTouchAreNotIntercepted() {
        val mouse = event(InputDevice.SOURCE_MOUSE)
        val touch = event(InputDevice.SOURCE_ROTARY_ENCODER, MotionEvent.ACTION_MOVE)
        assertNull(RotaryInput.delta(mouse, 64f, 2f))
        assertNull(RotaryInput.delta(touch, 64f, 2f))
        mouse.recycle(); touch.recycle()
    }
}
