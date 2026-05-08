package com.memorybox.android.friend

import com.memorybox.android.core.network.ApiResponse
import com.memorybox.android.core.network.DataResult
import com.memorybox.android.core.network.MemoryBoxEndpoints
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

interface FriendRepository {
    suspend fun fetch(): DataResult<List<Friend>>

    suspend fun fetchFriends(): DataResult<List<Friend>> = fetch()

    suspend fun fetchRequests(): DataResult<List<FriendRequest>>

    suspend fun friendRequest(uid: String): DataResult<FriendRequest>

    suspend fun acceptFriend(id: String): DataResult<Friend>

    suspend fun rejectFriend(id: String): DataResult<Friend>

    suspend fun deleteFriend(id: String): DataResult<Friend>
}

enum class FriendHttpMethod(val verb: String) {
    Get("GET"),
    Post("POST"),
    Delete("DELETE"),
}

data class FriendHttpRequest(
    val method: FriendHttpMethod,
    val path: String,
    val body: String? = null,
)

data class FriendHttpResponse(
    val statusCode: Int,
    val body: String,
)

interface FriendTransport {
    suspend fun request(request: FriendHttpRequest): FriendHttpResponse
}

class NetworkFriendRepository(
    private val transport: FriendTransport,
    private val json: Json = Json { ignoreUnknownKeys = true },
) : FriendRepository {
    override suspend fun fetch(): DataResult<List<Friend>> =
        execute(
            request = FriendHttpRequest(FriendHttpMethod.Get, MemoryBoxEndpoints.Friend.friends),
            serializer = ListSerializer(Friend.serializer()),
        )

    override suspend fun fetchRequests(): DataResult<List<FriendRequest>> =
        execute(
            request = FriendHttpRequest(FriendHttpMethod.Get, MemoryBoxEndpoints.Friend.friendRequests),
            serializer = ListSerializer(FriendRequest.serializer()),
        )

    override suspend fun friendRequest(uid: String): DataResult<FriendRequest> =
        execute(
            request = FriendHttpRequest(FriendHttpMethod.Post, MemoryBoxEndpoints.Friend.request(uid)),
            serializer = FriendRequest.serializer(),
        )

    override suspend fun acceptFriend(id: String): DataResult<Friend> =
        execute(
            request = FriendHttpRequest(FriendHttpMethod.Post, MemoryBoxEndpoints.Friend.accept(id)),
            serializer = Friend.serializer(),
        )

    override suspend fun rejectFriend(id: String): DataResult<Friend> =
        execute(
            request = FriendHttpRequest(FriendHttpMethod.Delete, MemoryBoxEndpoints.Friend.friend(id)),
            serializer = Friend.serializer(),
        )

    override suspend fun deleteFriend(id: String): DataResult<Friend> =
        execute(
            request = FriendHttpRequest(FriendHttpMethod.Delete, MemoryBoxEndpoints.Friend.friend(id)),
            serializer = Friend.serializer(),
        )

    private suspend fun <T> execute(
        request: FriendHttpRequest,
        serializer: KSerializer<T>,
    ): DataResult<T> =
        try {
            val response = transport.request(request)
            val apiResponse = json.decodeFromString(ApiResponse.serializer(serializer), response.body)
            val message = apiResponse.message

            if (response.statusCode !in 200..299 || !apiResponse.success) {
                DataResult.Failure(message.ifBlank { "서버 요청에 실패했습니다." })
            } else {
                apiResponse.data?.let { DataResult.Success(it, message) }
                    ?: DataResult.Failure(message.ifBlank { "서버 응답 데이터가 없습니다." })
            }
        } catch (error: Throwable) {
            DataResult.Failure("서버와의 통신에 에러가 발생했습니다.", error)
        }
}

class HttpUrlConnectionFriendTransport(
    private val baseUrl: String,
    private val bearerTokenProvider: () -> String? = { null },
    private val refreshTokenProvider: (suspend () -> String?)? = null,
    private val connectTimeoutMillis: Int = 10_000,
    private val readTimeoutMillis: Int = 10_000,
) : FriendTransport {
    override suspend fun request(request: FriendHttpRequest): FriendHttpResponse =
        withContext(Dispatchers.IO) {
            val firstResponse = executeOnce(request, bearerTokenProvider())
            if (firstResponse.statusCode != 401) {
                return@withContext firstResponse
            }

            val refreshedToken = refreshTokenProvider?.invoke()
            if (refreshedToken.isNullOrBlank()) {
                firstResponse
            } else {
                executeOnce(request, refreshedToken)
            }
        }

    private fun executeOnce(request: FriendHttpRequest, bearerToken: String?): FriendHttpResponse {
            val connection = URL(baseUrl.trimEnd('/') + request.path).openConnection() as HttpURLConnection
            connection.requestMethod = request.method.verb
            connection.connectTimeout = connectTimeoutMillis
            connection.readTimeout = readTimeoutMillis
            connection.setRequestProperty("Content-Type", "application/json")
            bearerToken?.takeIf { it.isNotBlank() }?.let { token ->
                connection.setRequestProperty("Authorization", "Bearer $token")
            }

            request.body?.let { body ->
                connection.doOutput = true
                connection.outputStream.use { output ->
                    output.write(body.toByteArray(Charsets.UTF_8))
                }
            }

            val statusCode = connection.responseCode
            val body = (if (statusCode in 200..299) connection.inputStream else connection.errorStream)
                ?.bufferedReader()
                ?.use { it.readText() }
                .orEmpty()

            connection.disconnect()
            return FriendHttpResponse(statusCode, body)
    }
}

class LocalFriendRepository(
    private val userId: String = "",
    initialFriends: List<Friend> = emptyList(),
    initialRequests: List<FriendRequest> = emptyList(),
) : FriendRepository {
    private val friends = initialFriends.toMutableList()
    private val requests = initialRequests.toMutableList()

    override suspend fun fetch(): DataResult<List<Friend>> =
        DataResult.Success(friends.toList())

    override suspend fun fetchRequests(): DataResult<List<FriendRequest>> =
        DataResult.Success(requests.toList())

    override suspend fun friendRequest(uid: String): DataResult<FriendRequest> {
        val request = FriendRequest(
            senderId = userId,
            senderName = userId.ifBlank { "나" },
            receiverId = uid,
            receiverName = uid,
        )
        requests.removeAll { it.senderId == userId && it.receiverId == uid }
        requests += request
        return DataResult.Success(request)
    }

    override suspend fun acceptFriend(id: String): DataResult<Friend> {
        val request = requests.firstOrNull { it.senderId == id }
        val friend = Friend(id = id, name = request?.senderName ?: id)
        requests.removeAll { it.senderId == id }
        if (friends.none { it.id == friend.id }) {
            friends += friend
        }
        return DataResult.Success(friend)
    }

    override suspend fun rejectFriend(id: String): DataResult<Friend> =
        removeFriendOrRequest(id)

    override suspend fun deleteFriend(id: String): DataResult<Friend> =
        removeFriendOrRequest(id)

    private fun removeFriendOrRequest(id: String): DataResult<Friend> {
        val existingFriend = friends.firstOrNull { it.id == id }
        val existingRequest = requests.firstOrNull { it.senderId == id || it.receiverId == id }
        friends.removeAll { it.id == id }
        requests.removeAll { it.senderId == id || it.receiverId == id }
        return DataResult.Success(
            existingFriend ?: Friend(
                id = id,
                name = existingRequest?.senderName?.takeIf { existingRequest.senderId == id }
                    ?: existingRequest?.receiverName
                    ?: id,
            )
        )
    }
}
