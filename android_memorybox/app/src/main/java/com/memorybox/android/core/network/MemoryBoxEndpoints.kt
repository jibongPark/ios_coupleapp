package com.memorybox.android.core.network

object MemoryBoxEndpoints {
    object Auth {
        const val login = "/login"
        const val refresh = "/refresh"
        const val deleteUser = "/deleteUser"
    }

    object Calendar {
        const val calendar = "/calendar"
        const val sync = "/sync"

        fun todo(id: String) = "/todo/$id"
        fun schedule(id: String) = "/schedule/$id"
        fun diary(id: String) = "/diary/$id"
    }

    object Friend {
        const val friends = "/friends"
        const val friendRequests = "/friendRequests"
        const val createInvite = "/friend/createInvite"

        fun request(uid: String) = "/friend/request/$uid"
        fun accept(friendId: String) = "/friend/accept/$friendId"
        fun friend(friendId: String) = "/friend/$friendId"
    }
}
