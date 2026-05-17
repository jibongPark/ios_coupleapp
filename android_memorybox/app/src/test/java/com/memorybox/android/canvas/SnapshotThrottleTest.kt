package com.memorybox.android.canvas

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SnapshotThrottleTest {
    @Test
    fun allowsFirstStrokeEndThenCoalescesUntilMinimumInterval() {
        val throttle = SnapshotThrottle(minIntervalMillis = 2_000)

        assertTrue(throttle.shouldUpdate(nowMillis = 1_000))
        assertFalse(throttle.shouldUpdate(nowMillis = 2_000))
        assertTrue(throttle.shouldUpdate(nowMillis = 3_000))
    }
}
