package com.memorybox.android.auth

import com.memorybox.android.core.network.DataResult
import com.memorybox.android.core.network.MemoryBoxHttpClient
import com.memorybox.android.core.network.MemoryBoxHttpMethod
import com.memorybox.android.core.network.MemoryBoxHttpRequest
import com.memorybox.android.core.network.MemoryBoxHttpResponse
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AuthRepositoryTest {
    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun loginPostsIosRequestBodyAndPersistsSession() {
        val client = RecordingHttpClient(
            MemoryBoxHttpResponse(
                statusCode = 200,
                body = apiResponse(
                    """
                    {
                      "userName": "Bong",
                      "uid": "user-1",
                      "accessToken": "access-1",
                      "refreshToken": "refresh-1"
                    }
                    """.trimIndent(),
                ),
            ),
        )
        val store = InMemorySessionStore()
        val repository = AuthRepository(client = client, sessionStore = store)

        val result = repository.login(type = LoginType.Kakao, jwt = "jwt-token", name = "Bong")

        assertTrue(result is DataResult.Success<*>)
        assertEquals(1, client.requests.size)
        val request = client.requests.single()
        assertEquals(MemoryBoxHttpMethod.Post, request.method)
        assertEquals("/login", request.path)
        assertNull(request.bearerToken)

        val body = json.parseToJsonElement(request.body.orEmpty()).jsonObject
        assertEquals("kakao", body["loginType"]?.jsonPrimitive?.content)
        assertEquals("jwt-token", body["jwt"]?.jsonPrimitive?.content)
        assertEquals("Bong", body["name"]?.jsonPrimitive?.content)

        assertEquals(
            UserSession(
                userName = "Bong",
                uid = "user-1",
                accessToken = "access-1",
                refreshToken = "refresh-1",
            ),
            repository.currentSession(),
        )
    }

    @Test
    fun refreshPostsRefreshTokenAndUpdatesCurrentSession() {
        val client = RecordingHttpClient(
            MemoryBoxHttpResponse(
                statusCode = 200,
                body = apiResponse(
                    """
                    {
                      "accessToken": "access-2",
                      "newRefreshToken": "refresh-2"
                    }
                    """.trimIndent(),
                ),
            ),
        )
        val store = InMemorySessionStore(
            UserSession(
                userName = "Bong",
                uid = "user-1",
                accessToken = "access-1",
                refreshToken = "refresh-1",
            ),
        )
        val repository = AuthRepository(client = client, sessionStore = store)

        val result = repository.refresh()

        assertTrue(result is DataResult.Success<*>)
        assertEquals(1, client.requests.size)
        val request = client.requests.single()
        assertEquals(MemoryBoxHttpMethod.Post, request.method)
        assertEquals("/refresh", request.path)

        val body = json.parseToJsonElement(request.body.orEmpty()).jsonObject
        assertEquals("refresh-1", body["refreshToken"]?.jsonPrimitive?.content)
        assertEquals(
            UserSession(
                userName = "Bong",
                uid = "user-1",
                accessToken = "access-2",
                refreshToken = "refresh-2",
            ),
            repository.currentSession(),
        )
    }

    @Test
    fun deleteUserRetriesOnceWithRefreshedBearerAfterUnauthorizedResponse() {
        val client = RecordingHttpClient(
            MemoryBoxHttpResponse(statusCode = 401, body = """{"success":false,"message":"expired"}"""),
            MemoryBoxHttpResponse(
                statusCode = 200,
                body = apiResponse(
                    """
                    {
                      "accessToken": "access-2",
                      "newRefreshToken": "refresh-2"
                    }
                    """.trimIndent(),
                ),
            ),
            MemoryBoxHttpResponse(statusCode = 200, body = apiResponse("\"deleted\"")),
        )
        val store = InMemorySessionStore(
            UserSession(
                userName = "Bong",
                uid = "user-1",
                accessToken = "access-1",
                refreshToken = "refresh-1",
            ),
        )
        val repository = AuthRepository(client = client, sessionStore = store)

        val result = repository.deleteUser()

        assertTrue(result is DataResult.Success<*>)
        assertEquals(3, client.requests.size)
        assertEquals(MemoryBoxHttpMethod.Delete, client.requests[0].method)
        assertEquals("/deleteUser", client.requests[0].path)
        assertEquals("access-1", client.requests[0].bearerToken)
        assertEquals("/refresh", client.requests[1].path)
        val refreshBody = json.parseToJsonElement(client.requests[1].body.orEmpty()).jsonObject
        assertEquals("refresh-1", refreshBody["refreshToken"]?.jsonPrimitive?.content)
        assertEquals(MemoryBoxHttpMethod.Delete, client.requests[2].method)
        assertEquals("/deleteUser", client.requests[2].path)
        assertEquals("access-2", client.requests[2].bearerToken)
        assertNull(repository.currentSession())
    }

    @Test
    fun logoutClearsCurrentSessionWithoutNetworkCall() {
        val client = RecordingHttpClient()
        val repository = AuthRepository(
            client = client,
            sessionStore = InMemorySessionStore(
                UserSession(
                    userName = "Bong",
                    uid = "user-1",
                    accessToken = "access-1",
                    refreshToken = "refresh-1",
                ),
            ),
        )

        repository.logout()

        assertNull(repository.currentSession())
        assertTrue(client.requests.isEmpty())
    }

    private fun apiResponse(dataJson: String): String = """
        {
          "success": true,
          "message": "ok",
          "data": $dataJson
        }
    """.trimIndent()
}

private class RecordingHttpClient(
    vararg responses: MemoryBoxHttpResponse,
) : MemoryBoxHttpClient {
    val requests = mutableListOf<MemoryBoxHttpRequest>()
    private val responses = ArrayDeque(responses.toList())

    override fun execute(request: MemoryBoxHttpRequest): MemoryBoxHttpResponse {
        requests += request
        return responses.removeFirstOrNull()
            ?: MemoryBoxHttpResponse(statusCode = 500, body = """{"success":false,"message":"missing response"}""")
    }
}

private class InMemorySessionStore(
    initialSession: UserSession? = null,
) : UserSessionStore {
    private var session = initialSession

    override fun load(): UserSession? = session

    override fun save(session: UserSession) {
        this.session = session
    }

    override fun clear() {
        session = null
    }
}
