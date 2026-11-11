package io.github.andi_0309.easyhof

import android.view.InputDevice
import android.view.MotionEvent

object RotaryInput {
    fun delta(event: MotionEvent, scrollFactor: Float, density: Float): Double? {
        if (event.action != MotionEvent.ACTION_SCROLL || !event.isFromSource(InputDevice.SOURCE_ROTARY_ENCODER) || density <= 0f) return null
        val delta = -event.getAxisValue(MotionEvent.AXIS_SCROLL) * scrollFactor / density
        return if (delta.isFinite()) delta.toDouble() else null
    }
}
