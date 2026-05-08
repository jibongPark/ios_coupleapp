package com.memorybox.android.friend

import com.memorybox.android.core.network.DataResult
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class FriendRepositoryTest {
    @Test
    fun fetchFriendsUsesIosPathAndGetMethod() = runBlocking {
        val transport = RecordingFriendTransport(
            FriendHttpResponse(
                statusCode = 200,
                body = """{"success":true,"message":"ok","data":[{"id":"u1","name":"Jay"}]}""",
            )
        )
        val repository = NetworkFriendRepository(transport)

        val result = repository.fetch()

        assertEquals(FriendHttpMethod.Get, transport.requests.single().method)
        assertEquals("/friends", transport.requests.single().path)
        assertEquals(null, transport.requests.single().body)
        assertTrue(result is DataResult.Success<*>)
        assertEquals(listOf(Friend(id = "u1", name = "Jay")), (result as DataResult.Success<*>).data)
    }

    @Test
    fun fetchRequestsUsesIosPathAndGetMethod() = runBlocking {
        val transport = RecordingFriendTransport(
            FriendHttpResponse(
                statusCode = 200,
                body = """
                    {
                      "success": true,
                      "message": "ok",
                      "data": [
                        {
                          "senderId": "sender",
                          "senderName": "Sender",
                          "receiverId": "receiver",
                          "receiverName": "Receiver"
                        }
                      ]
                    }
                """.trimIndent(),
            )
        )
        val repository = NetworkFriendRepository(transport)

        val result = repository.fetchRequests()

        assertEquals(FriendHttpMethod.Get, transport.requests.single().method)
        assertEquals("/friendRequests", transport.requests.single().path)
        assertTrue(result is DataResult.Success<*>)
        assertEquals(
            listOf(
                FriendRequest(
                    senderId = "sender",
                    senderName = "Sender",
                    receiverId = "receiver",
                    receiverName = "Receiver",
                )
            ),
            (result as DataResult.Success<*>).data,
        )
    }

    @Test
    fun mutationMethodsUseIosPathsAndActions() = runBlocking {
        val transport = RecordingFriendTransport(
            FriendHttpResponse(
                statusCode = 200,
                body = """{"success":true,"message":"ok","data":{"senderId":"me","senderName":"Me","receiverId":"u2","receiverName":"Lee"}}""",
            ),
            FriendHttpResponse(
                statusCode = 200,
                body = """{"success":true,"message":"ok","data":{"id":"u2","name":"Lee"}}""",
            ),
            FriendHttpResponse(
                statusCode = 200,
                body = """{"success":true,"message":"ok","data":{"id":"u3","name":"Kim"}}""",
            ),
            FriendHttpResponse(
                statusCode = 200,
                body = """{"success":true,"message":"ok","data":{"id":"u4","name":"Park"}}""",
            ),
        )
        val repository = NetworkFriendRepository(transport)

        repository.friendRequest("u2")
        repository.acceptFriend("u2")
        repository.rejectFriend("u3")
        repository.deleteFriend("u4")

        assertEquals(
            listOf(
                FriendHttpRequest(FriendHttpMethod.Post, "/friend/request/u2"),
                FriendHttpRequest(FriendHttpMethod.Post, "/friend/accept/u2"),
                FriendHttpRequest(FriendHttpMethod.Delete, "/friend/u3"),
                FriendHttpRequest(FriendHttpMethod.Delete, "/friend/u4"),
            ),
            transport.requests,
        )
    }

    @Test
    fun returnsFailureMessageWhenApiResponseIsNotSuccessful() = runBlocking {
        val transport = RecordingFriendTransport(
            FriendHttpResponse(
                statusCode = 400,
                body = """{"success":false,"message":"이미 친구 신청을 보냈습니다.","data":null}""",
            )
        )
        val repository = NetworkFriendRepository(transport)

        val result = repository.friendRequest("u2")

        assertTrue(result is DataResult.Failure)
        assertEquals("이미 친구 신청을 보냈습니다.", (result as DataResult.Failure).message)
    }

    private class RecordingFriendTransport(
        vararg responses: FriendHttpResponse,
    ) : FriendTransport {
        private val responseQueue = ArrayDeque(responses.toList())
        val requests = mutableListOf<FriendHttpRequest>()

        override suspend fun request(request: FriendHttpRequest): FriendHttpResponse {
            requests += request
            return responseQueue.removeFirst()
        }
    }
}
