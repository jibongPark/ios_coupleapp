package com.memorybox.android.pairing

import android.content.Context
import com.memorybox.android.core.network.ApiResponse
import com.memorybox.android.core.network.DataResult
import com.memorybox.android.core.network.MemoryBoxEndpoints
import com.memorybox.android.friend.FriendHttpMethod
import com.memorybox.android.friend.FriendHttpRequest
import com.memorybox.android.friend.FriendTransport
import java.util.UUID
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.json.Json

interface PairingRepository {
    suspend fun fetchActiveSharedSpace(): DataResult<SharedSpace?>
    suspend fun createPairingInvite(): DataResult<PairingInvite>
    suspend fun acceptPairingInvite(code: String): DataResult<SharedSpace>
    suspend fun leaveSharedSpace(id: String): DataResult<SharedSpace>
}

interface ActiveSharedSpaceStore {
    fun load(): SharedSpace?
    fun save(sharedSpace: SharedSpace)
    fun clear()
}

class SharedPreferencesActiveSharedSpaceStore(
    context: Context,
    private val json: Json = Json { ignoreUnknownKeys = true },
) : ActiveSharedSpaceStore {
    private val preferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

    override fun load(): SharedSpace? {
        val raw = preferences.getString(KEY_ACTIVE_SHARED_SPACE, null)?.takeIf { it.isNotBlank() }
            ?: return null
        return runCatching { json.decodeFromString(SharedSpace.serializer(), raw) }.getOrNull()
    }

    override fun save(sharedSpace: SharedSpace) {
        preferences.edit()
            .putString(KEY_ACTIVE_SHARED_SPACE, json.encodeToString(SharedSpace.serializer(), sharedSpace))
            .apply()
    }

    override fun clear() {
        preferences.edit().remove(KEY_ACTIVE_SHARED_SPACE).apply()
    }

    private companion object {
        const val PREF_NAME = "memorybox_pairing"
        const val KEY_ACTIVE_SHARED_SPACE = "activeSharedSpace"
    }
}

class NetworkPairingRepository(
    private val transport: FriendTransport,
    private val store: ActiveSharedSpaceStore? = null,
    private val json: Json = Json { ignoreUnknownKeys = true },
) : PairingRepository {
    override suspend fun fetchActiveSharedSpace(): DataResult<SharedSpace?> =
        executeNullable(
            request = FriendHttpRequest(FriendHttpMethod.Get, MemoryBoxEndpoints.SharedSpace.active),
            serializer = SharedSpace.serializer(),
        ) { sharedSpace ->
            if (sharedSpace != null) store?.save(sharedSpace)
        }

    override suspend fun createPairingInvite(): DataResult<PairingInvite> =
        execute(
            request = FriendHttpRequest(FriendHttpMethod.Post, MemoryBoxEndpoints.SharedSpace.invites),
            serializer = PairingInvite.serializer(),
        )

    override suspend fun acceptPairingInvite(code: String): DataResult<SharedSpace> =
        execute(
            request = FriendHttpRequest(FriendHttpMethod.Post, MemoryBoxEndpoints.SharedSpace.acceptInvite(code)),
            serializer = SharedSpace.serializer(),
        ) { sharedSpace -> store?.save(sharedSpace) }

    override suspend fun leaveSharedSpace(id: String): DataResult<SharedSpace> =
        execute(
            request = FriendHttpRequest(FriendHttpMethod.Delete, MemoryBoxEndpoints.SharedSpace.leave(id)),
            serializer = SharedSpace.serializer(),
        ) { store?.clear() }

    private suspend fun <T> execute(
        request: FriendHttpRequest,
        serializer: KSerializer<T>,
        onSuccess: (T) -> Unit = {},
    ): DataResult<T> =
        try {
            val response = transport.request(request)
            val apiResponse = json.decodeFromString(ApiResponse.serializer(serializer), response.body)
            val message = apiResponse.message

            if (response.statusCode !in 200..299 || !apiResponse.success) {
                DataResult.Failure(message.ifBlank { "서버 요청에 실패했습니다." })
            } else {
                apiResponse.data?.let { data ->
                    onSuccess(data)
                    DataResult.Success(data, message)
                } ?: DataResult.Failure(message.ifBlank { "서버 응답 데이터가 없습니다." })
            }
        } catch (error: Throwable) {
            DataResult.Failure("서버와의 통신에 에러가 발생했습니다.", error)
        }

    private suspend fun <T> executeNullable(
        request: FriendHttpRequest,
        serializer: KSerializer<T>,
        onSuccess: (T?) -> Unit = {},
    ): DataResult<T?> =
        try {
            val response = transport.request(request)
            val apiResponse = json.decodeFromString(ApiResponse.serializer(serializer.nullable), response.body)
            val message = apiResponse.message

            if (response.statusCode !in 200..299 || !apiResponse.success) {
                DataResult.Failure(message.ifBlank { "서버 요청에 실패했습니다." })
            } else {
                onSuccess(apiResponse.data)
                DataResult.Success(apiResponse.data, message)
            }
        } catch (error: Throwable) {
            DataResult.Failure("서버와의 통신에 에러가 발생했습니다.", error)
        }
}

class LocalPairingRepository(
    private val userId: String = "",
    private val store: ActiveSharedSpaceStore = InMemoryActiveSharedSpaceStore(),
    private val codeProvider: () -> String = { UUID.randomUUID().toString().take(6).uppercase() },
    private val idProvider: () -> String = { "local_${UUID.randomUUID()}" },
) : PairingRepository {
    private var pendingInvite: PairingInvite? = null

    override suspend fun fetchActiveSharedSpace(): DataResult<SharedSpace?> =
        DataResult.Success(store.load())

    override suspend fun createPairingInvite(): DataResult<PairingInvite> {
        val invite = PairingInvite(
            code = codeProvider(),
            sharedSpaceId = store.load()?.id,
            inviterId = userId,
        )
        pendingInvite = invite
        return DataResult.Success(invite)
    }

    override suspend fun acceptPairingInvite(code: String): DataResult<SharedSpace> {
        if (code.isBlank()) {
            return DataResult.Failure("페어링 코드를 입력해주세요.")
        }

        val sharedSpace = SharedSpace(
            id = pendingInvite?.sharedSpaceId ?: idProvider(),
            members = listOf(
                SharedSpaceMember(userId = userId.ifBlank { "me" }, name = userId.ifBlank { "나" }, role = "owner"),
                SharedSpaceMember(userId = "partner", name = "파트너"),
            ),
        )
        store.save(sharedSpace)
        pendingInvite = null
        return DataResult.Success(sharedSpace)
    }

    override suspend fun leaveSharedSpace(id: String): DataResult<SharedSpace> {
        val sharedSpace = store.load() ?: SharedSpace(id = id)
        store.clear()
        pendingInvite = null
        return DataResult.Success(sharedSpace)
    }
}

class InMemoryActiveSharedSpaceStore(
    initialSharedSpace: SharedSpace? = null,
) : ActiveSharedSpaceStore {
    private var sharedSpace = initialSharedSpace

    override fun load(): SharedSpace? = sharedSpace

    override fun save(sharedSpace: SharedSpace) {
        this.sharedSpace = sharedSpace
    }

    override fun clear() {
        sharedSpace = null
    }
}
