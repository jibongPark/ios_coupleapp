package com.memorybox.android.pairing

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
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
fun PairingScreen(
    userId: String,
    modifier: Modifier = Modifier,
    repository: PairingRepository = remember(userId) { LocalPairingRepository(userId) },
) {
    var screenState by remember(repository) { mutableStateOf(PairingScreenState(isLoading = true)) }
    var pairingCode by remember { mutableStateOf("") }
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(repository) {
        screenState = screenState.copy(isLoading = true, errorMessage = null)
        screenState = when (val result = repository.fetchActiveSharedSpace()) {
            is DataResult.Success -> screenState.copy(
                isLoading = false,
                activeSharedSpace = result.data,
                errorMessage = null,
            )
            is DataResult.Failure -> screenState.copy(
                isLoading = false,
                errorMessage = result.message,
            )
        }
    }

    fun <T> runPairingAction(
        action: suspend () -> DataResult<T>,
        reduce: (PairingScreenState, T) -> PairingScreenState,
    ) {
        coroutineScope.launch {
            screenState = screenState.copy(isLoading = true, errorMessage = null)
            screenState = when (val result = action()) {
                is DataResult.Success<*> -> {
                    @Suppress("UNCHECKED_CAST")
                    reduce(screenState, result.data as T).copy(isLoading = false, errorMessage = null)
                }
                is DataResult.Failure -> screenState.copy(
                    isLoading = false,
                    errorMessage = result.message,
                )
            }
        }
    }

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text("페어링", style = MaterialTheme.typography.titleMedium)

        if (screenState.isLoading) {
            Text("페어링 정보를 불러오는 중...", style = MaterialTheme.typography.bodyMedium)
        }

        screenState.errorMessage?.let { message ->
            Text(message, color = MaterialTheme.colorScheme.error)
        }

        val activeSharedSpace = screenState.activeSharedSpace
        if (activeSharedSpace != null) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(pairingDescription(activeSharedSpace, userId))
                Button(
                    enabled = !screenState.isLoading,
                    onClick = {
                        runPairingAction(
                            action = { repository.leaveSharedSpace(activeSharedSpace.id) },
                            reduce = { state, _ -> state.copy(activeSharedSpace = null, pairingInvite = null) },
                        )
                    },
                ) {
                    Text("해제")
                }
            }
        } else {
            screenState.pairingInvite?.let { invite ->
                Text("초대 코드: ${invite.code}", color = MaterialTheme.colorScheme.primary)
            }

            Button(
                enabled = !screenState.isLoading,
                onClick = {
                    runPairingAction(
                        action = { repository.createPairingInvite() },
                        reduce = { state, invite -> state.copy(pairingInvite = invite) },
                    )
                },
            ) {
                Text("초대 코드 생성")
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                OutlinedTextField(
                    value = pairingCode,
                    onValueChange = { pairingCode = it },
                    modifier = Modifier.weight(1f),
                    label = { Text("페어링 코드") },
                )
                Button(
                    enabled = pairingCode.isNotBlank() && !screenState.isLoading,
                    onClick = {
                        val code = pairingCode.trim()
                        runPairingAction(
                            action = { repository.acceptPairingInvite(code) },
                            reduce = { state, sharedSpace ->
                                pairingCode = ""
                                state.copy(activeSharedSpace = sharedSpace, pairingInvite = null)
                            },
                        )
                    },
                ) {
                    Text("연결")
                }
            }
        }
    }
}

private data class PairingScreenState(
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val activeSharedSpace: SharedSpace? = null,
    val pairingInvite: PairingInvite? = null,
)

private fun pairingDescription(sharedSpace: SharedSpace, userId: String): String {
    val partner = sharedSpace.members.firstOrNull { it.userId != userId }
    return when {
        partner != null -> "${partner.name}님과 페어링 중"
        !sharedSpace.name.isNullOrBlank() -> "${sharedSpace.name} 공유 공간에 연결됨"
        else -> "공유 공간에 연결됨"
    }
}
