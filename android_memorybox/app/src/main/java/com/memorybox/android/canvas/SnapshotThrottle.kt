package com.memorybox.android.canvas

class SnapshotThrottle(
    private val minIntervalMillis: Long = 2_000,
) {
    private var lastUpdateMillis: Long? = null

    fun shouldUpdate(nowMillis: Long = System.currentTimeMillis()): Boolean {
        val last = lastUpdateMillis
        if (last == null || nowMillis - last >= minIntervalMillis) {
            lastUpdateMillis = nowMillis
            return true
        }
        return false
    }
}
