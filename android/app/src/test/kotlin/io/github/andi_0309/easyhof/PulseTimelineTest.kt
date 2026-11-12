package io.github.andi_0309.easyhof

import org.junit.Assert.*
import org.junit.Test

class PulseTimelineTest {
    @Test fun batchedReadingsUseTheHistoricalActiveClockAndExcludePauses() {
        val timeline = PulseTimeline()
        timeline.update(10000, 0, false)
        timeline.update(12000, 2000, true)
        timeline.update(18000, 2000, false)
        timeline.update(20000, 4000, false)
        assertEquals(1000L, timeline.activeAt(11000))
        assertNull(timeline.activeAt(15000))
        assertEquals(3000L, timeline.activeAt(19000))
    }
    @Test fun missingHeartbeatDoesNotInventMoreThanTheSupportedSegment() {
        val timeline = PulseTimeline()
        timeline.update(1000, 4000, false)
        assertNull(timeline.activeAt(500))
        assertNull(timeline.activeAt(12000))
        timeline.update(20000, 5000, false)
        assertEquals(5100L, timeline.activeAt(20100))
    }
}
