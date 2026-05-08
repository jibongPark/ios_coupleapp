package com.memorybox.android.auth

import com.memorybox.android.core.network.ApiResponse
import com.memorybox.android.core.network.DataResult
import com.memorybox.android.core.network.MemoryBoxConfig
import com.memorybox.android.core.network.MemoryBoxEndpoints
import com.memorybox.android.core.network.MemoryBoxHttpClient
import com.memorybox.android.core.network.MemoryBoxHttpMethod
import com.memorybox.android.core.network.MemoryBoxHttpRequest
import com.memorybox.android.core.network.MemoryBoxHttpResponse
import com.memorybox.android.core.network.UrlConnectionMemoryBoxHttpClient
import kotlinx.serialization.SerializationException
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class AuthRepository(
    private val client: MemoryBoxHttpClient,
    private val sessionStore: UserSessionStore,
    private val json: Json = Json { ignoreUnknownKeys = true },
) {
    constructor(
        config: MemoryBoxConfig,
        sessionStore: UserSessionStore,
    ) : this(
        client = UrlConnectionMemoryBoxHttpClient(config),
        sessionStore = sessionStore,
    )

    fun login(type: LoginType, jwt: String, name: String): DataResult<UserSession> =
        login(type = type.serverValue, jwt = jwt, name = name)

    fun login(type: String, jwt: String, name: String): DataResult<UserSession> {
        val request = MemoryBoxHttpRequest(
            method = MemoryBoxHttpMethod.Post,
            path = MemoryBoxEndpoints.Auth.login,
            body = json.encodeToString(
                LoginRequest(
                    loginType = type,
                    jwt = jwt,
                    name = name,
                ),
            ),
        )

        return when (val result = executeApi<AuthResponse>(request)) {
            is DataResult.Success -> {
                val session = result.data.toSession()
                sessionStore.save(session)
                DataResult.Success(session, result.message)
            }
            is DataResult.Failure -> result
        }
    }

    fun refresh(): DataResult<UserSession> {
        val currentSession = sessionStore.load()
            ?: return DataResult.Failure("No current session to refresh.")

        return refreshSession(currentSession)
    }

    fun deleteUser(): DataResult<String> {
        val currentSession = sessionStore.load()
            ?: return DataResult.Failure("No current session to delete.")

        val response = executeDeleteUser(currentSession.accessToken)
        val finalResponse = if (response.isUnauthorized) {
            when (val refreshResult = refreshSession(currentSession)) {
                is DataResult.Success -> executeDeleteUser(refreshResult.data.accessToken)
                is DataResult.Failure -> return refreshResult
            }
        } else {
            response
        }

        return when (val result = decodeApiResponse<String>(finalResponse)) {
            is DataResult.Success -> {
                sessionStore.clear()
                result
            }
            is DataResult.Failure -> result
        }
    }

    fun logout() {
        sessionStore.clear()
    }

    fun currentSession(): UserSession? = sessionStore.load()

    private fun refreshSession(session: UserSession): DataResult<UserSession> {
        val request = MemoryBoxHttpRequest(
            method = MemoryBoxHttpMethod.Post,
            path = MemoryBoxEndpoints.Auth.refresh,
            body = json.encodeToString(RefreshRequest(session.refreshToken)),
        )

        return when (val result = executeApi<RefreshResponse>(request)) {
            is DataResult.Success -> {
                val refreshedSession = session.copy(
                    accessToken = result.data.accessToken,
                    refreshToken = result.data.newRefreshToken,
                )
                sessionStore.save(refreshedSession)
                DataResult.Success(refreshedSession, result.message)
            }
            is DataResult.Failure -> result
        }
    }

    private fun executeDeleteUser(accessToken: String): MemoryBoxHttpResponse =
        client.execute(
            MemoryBoxHttpRequest(
                method = MemoryBoxHttpMethod.Delete,
                path = MemoryBoxEndpoints.Auth.deleteUser,
                bearerToken = accessToken,
            ),
        )

    private inline fun <reified T> executeApi(request: MemoryBoxHttpRequest): DataResult<T> =
        runCatching { client.execute(request) }
            .fold(
                onSuccess = { decodeApiResponse<T>(it) },
                onFailure = { DataResult.Failure(it.message ?: "Network request failed.", it) },
            )

    private inline fun <reified T> decodeApiResponse(response: MemoryBoxHttpResponse): DataResult<T> {
        if (!response.isSuccessful) {
            return DataResult.Failure("HTTP ${response.statusCode}")
        }

        return try {
            val apiResponse = json.decodeFromString<ApiResponse<T>>(response.body)
            if (!apiResponse.success) {
                DataResult.Failure(apiResponse.message)
            } else {
                val data = apiResponse.data
                    ?: return DataResult.Failure("Response data is empty.")
                DataResult.Success(data, apiResponse.message)
            }
        } catch (error: SerializationException) {
            DataResult.Failure("Failed to decode response.", error)
        } catch (error: IllegalArgumentException) {
            DataResult.Failure("Failed to decode response.", error)
        }
    }

    private fun AuthResponse.toSession(): UserSession =
        UserSession(
            userName = userName,
            uid = uid,
            accessToken = accessToken,
            refreshToken = refreshToken,
        )
}
