package com.memorybox.android.friend

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.memorybox.android.core.network.DataResult
import kotlinx.coroutines.launch

@Composable
fun FriendScreen(
    userId: String,
    modifier: Modifier = Modifier,
    repository: FriendRepository = remember(userId) { LocalFriendRepository(userId) },
) {
    var inviteCode by remember { mutableStateOf("") }
    var screenState by remember(repository) { mutableStateOf(FriendScreenState(isLoading = true)) }
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(repository) {
        screenState = screenState.copy(isLoading = true, errorMessage = null)
        val friendsResult = repository.fetch()
        val requestsResult = repository.fetchRequests()
        screenState = screenState.copy(
            isLoading = false,
            friends = friendsResult.dataOrNull() ?: screenState.friends,
            requests = requestsResult.dataOrNull() ?: screenState.requests,
            errorMessage = friendsResult.failureMessageOrNull()
                ?: requestsResult.failureMessageOrNull(),
        )
    }

    fun <T> runFriendAction(
        action: suspend () -> DataResult<T>,
        reduce: (FriendScreenState, T) -> FriendScreenState,
    ) {
        coroutineScope.launch {
            screenState = screenState.copy(isLoading = true, errorMessage = null)
            screenState = when (val result = action()) {
                is DataResult.Success<*> -> {
                    @Suppress("UNCHECKED_CAST")
                    reduce(screenState, result.data as T)
                        .copy(isLoading = false, errorMessage = null)
                }
                is DataResult.Failure -> screenState.copy(
                    isLoading = false,
                    errorMessage = result.message,
                )
            }
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("친구", style = MaterialTheme.typography.titleLarge)
        Text("uid : $userId", style = MaterialTheme.typography.bodyMedium)

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
                value = inviteCode,
                onValueChange = { inviteCode = it },
                modifier = Modifier.weight(1f),
                label = { Text("초대코드를 입력해주세요.") },
            )
            Button(
                enabled = inviteCode.isNotBlank(),
                onClick = {
                    val uid = inviteCode
                    runFriendAction(
                        action = { repository.friendRequest(uid) },
                        reduce = { state, request ->
                            inviteCode = ""
                            state.copy(requests = state.requests + request)
                        },
                    )
                },
            ) {
                Text("신청")
            }
        }

        if (screenState.isLoading) {
            Text("불러오는 중...", style = MaterialTheme.typography.bodyMedium)
        }

        screenState.errorMessage?.let { message ->
            Text(message, color = MaterialTheme.colorScheme.error)
        }

        Spacer(Modifier.height(8.dp))
        Text("친구 요청", style = MaterialTheme.typography.titleMedium)
        screenState.requests.forEach { request ->
            val isMyRequest = request.senderId == userId
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(if (isMyRequest) request.receiverName else request.senderName)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (isMyRequest) {
                        Button(
                            onClick = {
                                runFriendAction(
                                    action = { repository.deleteFriend(request.receiverId) },
                                    reduce = { state, friend -> state.removeFriendState(friend.id) },
                                )
                            },
                        ) {
                            Text("취소")
                        }
                    } else {
                        Button(
                            onClick = {
                                runFriendAction(
                                    action = { repository.acceptFriend(request.senderId) },
                                    reduce = { state, friend ->
                                        state.copy(
                                            requests = state.requests.filterNot { it.senderId == friend.id },
                                            friends = state.friends.appendIfMissing(friend),
                                        )
                                    },
                                )
                            },
                        ) {
                            Text("수락")
                        }
                        Button(
                            onClick = {
                                runFriendAction(
                                    action = { repository.rejectFriend(request.senderId) },
                                    reduce = { state, friend ->
                                        state.copy(
                                            requests = state.requests.filterNot { it.senderId == friend.id },
                                        )
                                    },
                                )
                            },
                        ) {
                            Text("거절")
                        }
                    }
                }
            }
        }

        Text("친구 목록", style = MaterialTheme.typography.titleMedium)
        screenState.friends.forEach { friend ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(friend.name)
                Button(
                    onClick = {
                        runFriendAction(
                            action = { repository.deleteFriend(friend.id) },
                            reduce = { state, deletedFriend -> state.removeFriendState(deletedFriend.id) },
                        )
                    },
                ) {
                    Text("삭제")
                }
            }
        }
    }
}

private data class FriendScreenState(
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val friends: List<Friend> = emptyList(),
    val requests: List<FriendRequest> = emptyList(),
)

@Suppress("UNCHECKED_CAST")
private fun <T> DataResult<T>.dataOrNull(): T? =
    when (this) {
        is DataResult.Success<*> -> data as T
        is DataResult.Failure -> null
    }

private fun DataResult<*>.failureMessageOrNull(): String? =
    when (this) {
        is DataResult.Success<*> -> null
        is DataResult.Failure -> message
    }

private fun FriendScreenState.removeFriendState(friendId: String): FriendScreenState =
    copy(
        friends = friends.filterNot { it.id == friendId },
        requests = requests.filterNot { it.senderId == friendId || it.receiverId == friendId },
    )

private fun List<Friend>.appendIfMissing(friend: Friend): List<Friend> =
    if (any { it.id == friend.id }) this else this + friend
