package com.memorybox.android.core

import com.memorybox.android.core.network.MemoryBoxEndpoints
import org.junit.Assert.assertEquals
import org.junit.Test

class MemoryBoxEndpointsTest {
    @Test
    fun authEndpointsMatchIosPaths() {
        assertEquals("/login", MemoryBoxEndpoints.Auth.login)
        assertEquals("/refresh", MemoryBoxEndpoints.Auth.refresh)
        assertEquals("/deleteUser", MemoryBoxEndpoints.Auth.deleteUser)
    }

    @Test
    fun calendarEndpointsMatchIosPaths() {
        assertEquals("/calendar", MemoryBoxEndpoints.Calendar.calendar)
        assertEquals("/todo/abc", MemoryBoxEndpoints.Calendar.todo("abc"))
        assertEquals("/schedule/abc", MemoryBoxEndpoints.Calendar.schedule("abc"))
        assertEquals("/diary/abc", MemoryBoxEndpoints.Calendar.diary("abc"))
        assertEquals("/sync", MemoryBoxEndpoints.Calendar.sync)
    }

    @Test
    fun friendEndpointsMatchIosPaths() {
        assertEquals("/friends", MemoryBoxEndpoints.Friend.friends)
        assertEquals("/friendRequests", MemoryBoxEndpoints.Friend.friendRequests)
        assertEquals("/friend/request/u1", MemoryBoxEndpoints.Friend.request("u1"))
        assertEquals("/friend/accept/u1", MemoryBoxEndpoints.Friend.accept("u1"))
        assertEquals("/friend/u1", MemoryBoxEndpoints.Friend.friend("u1"))
    }
}
