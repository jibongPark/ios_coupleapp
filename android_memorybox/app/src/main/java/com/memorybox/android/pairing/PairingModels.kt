package com.memorybox.android.pairing

import kotlinx.serialization.Serializable

@Serializable
data class SharedSpace(
    val id: String,
    val type: String = "pair",
    val name: String? = null,
    val members: List<SharedSpaceMember> = emptyList(),
)

@Serializable
data class SharedSpaceMember(
    val userId: String,
    val name: String,
    val role: String = "member",
)

@Serializable
data class PairingInvite(
    val code: String,
    val sharedSpaceId: String? = null,
    val inviterId: String,
    val expiresAt: String? = null,
)
