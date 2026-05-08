package com.memorybox.android.friend

import kotlinx.serialization.Serializable

@Serializable
data class Friend(
    val id: String,
    val name: String,
)

@Serializable
data class FriendRequest(
    val senderId: String,
    val senderName: String,
    val receiverId: String,
    val receiverName: String,
)
