package com.memorybox.android.auth

import kotlinx.serialization.Serializable

enum class LoginType(val serverValue: String) {
    Apple("apple"),
    Kakao("kakao"),
}

@Serializable
data class LoginRequest(
    val loginType: String,
    val jwt: String,
    val name: String,
)

@Serializable
data class AuthResponse(
    val userName: String,
    val uid: String,
    val accessToken: String,
    val refreshToken: String,
)

@Serializable
data class RefreshRequest(
    val refreshToken: String,
)

@Serializable
data class RefreshResponse(
    val accessToken: String,
    val newRefreshToken: String,
)

@Serializable
data class UserSession(
    val userName: String,
    val uid: String,
    val accessToken: String,
    val refreshToken: String,
    val baseUrl: String = "",
)
