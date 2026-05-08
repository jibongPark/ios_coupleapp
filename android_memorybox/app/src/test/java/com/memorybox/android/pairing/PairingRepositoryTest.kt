package com.memorybox.android.pairing

import com.memorybox.android.core.network.DataResult
import com.memorybox.android.friend.FriendHttpMethod
import com.memorybox.android.friend.FriendHttpRequest
import com.memorybox.android.friend.FriendHttpResponse
import com.memorybox.android.friend.FriendTransport
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PairingRepositoryTest {
    @Test
    fun networkRepositoryUsesSharedSpaceEndpointPathsAndMethods() = runBlocking {
        val transport = RecordingPairingTransport(
            FriendHttpResponse(
                statusCode = 200,
                body = """{"success":true,"message":"ok","data":{"id":"space-1","type":"pair","name":"Pair","members":[]}}""",
            ),
            FriendHttpResponse(
                statusCode = 200,
                body = """{"success":true,"message":"ok","data":{"code":"ABC123","sharedSpaceId":"space-1","inviterId":"me","expiresAt":"2026-05-09T00:00:00Z"}}""",
            ),
            FriendHttpResponse(
                statusCode = 200,
                body = """{"success":true,"message":"ok","data":{"id":"space-2","type":"pair","members":[{"userId":"partner","name":"Partner","role":"member"}]}}""",
            ),
            FriendHttpResponse(
                statusCode = 200,
                body = """{"success":true,"message":"ok","data":{"id":"space-2","type":"pair","members":[]}}""",
            ),
        )
        val repository = NetworkPairingRepository(transport)

        repository.fetchActiveSharedSpace()
        repository.createPairingInvite()
        repository.acceptPairingInvite("ABC123")
        repository.leaveSharedSpace("space-2")

        assertEquals(
            listOf(
                FriendHttpRequest(FriendHttpMethod.Get, "/shared-spaces/active"),
                FriendHttpRequest(FriendHttpMethod.Post, "/shared-spaces/invites"),
                FriendHttpRequest(FriendHttpMethod.Post, "/shared-spaces/invites/ABC123/accept"),
                FriendHttpRequest(FriendHttpMethod.Delete, "/shared-spaces/space-2/members/me"),
            ),
            transport.requests,
        )
    }

    @Test
    fun localRepositoryPersistsAndClearsActiveSharedSpace() = runBlocking {
        val store = InMemoryActiveSharedSpaceStore()
        val repository = LocalPairingRepository(
            userId = "me",
            store = store,
            codeProvider = { "LOCAL1" },
            idProvider = { "space-local" },
        )

        val invite = repository.createPairingInvite()
        val accepted = repository.acceptPairingInvite("LOCAL1")
        val fetched = repository.fetchActiveSharedSpace()
        val left = repository.leaveSharedSpace("space-local")
        val fetchedAfterLeave = repository.fetchActiveSharedSpace()

        assertTrue(invite is DataResult.Success<*>)
        assertEquals("LOCAL1", (invite as DataResult.Success).data.code)
        assertTrue(accepted is DataResult.Success<*>)
        assertEquals("space-local", (accepted as DataResult.Success).data.id)
        assertEquals("space-local", ((fetched as DataResult.Success).data)?.id)
        assertTrue(left is DataResult.Success<*>)
        assertNull((fetchedAfterLeave as DataResult.Success).data)
    }

    private class RecordingPairingTransport(
        vararg responses: FriendHttpResponse,
    ) : FriendTransport {
        private val responseQueue = ArrayDeque(responses.toList())
        val requests = mutableListOf<FriendHttpRequest>()

        override suspend fun request(request: FriendHttpRequest): FriendHttpResponse {
            requests += request
            return responseQueue.removeFirst()
        }
    }

    private class InMemoryActiveSharedSpaceStore(
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
}
