package com.memorybox.android.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.memorybox.android.BuildConfig
import com.memorybox.android.auth.AuthRepository
import com.memorybox.android.auth.AuthSessionStore
import com.memorybox.android.auth.LoginType
import com.memorybox.android.auth.UserSessionStore
import com.memorybox.android.auth.UserSession
import com.memorybox.android.calendar.data.CalendarJsonStore
import com.memorybox.android.calendar.data.CalendarRepositoryImpl
import com.memorybox.android.calendar.data.NetworkCalendarServerTransport
import com.memorybox.android.calendar.data.NoopCalendarServerTransport
import com.memorybox.android.calendar.ui.CalendarScreen
import com.memorybox.android.core.network.DataResult
import com.memorybox.android.core.network.MemoryBoxConfig
import com.memorybox.android.core.network.UrlConnectionMemoryBoxHttpClient
import com.memorybox.android.friend.FriendScreen
import com.memorybox.android.friend.HttpUrlConnectionFriendTransport
import com.memorybox.android.friend.LocalFriendRepository
import com.memorybox.android.friend.NetworkFriendRepository
import com.memorybox.android.map.ui.MapScreen
import com.memorybox.android.widget.ui.DdayScreen
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

private enum class MainTab(val label: String) {
    Map("여행지도"),
    Calendar("캘린더"),
}

private enum class SideDestination {
    Home,
    Widget,
    Friend,
    Setting,
}

@Composable
fun MemoryBoxApp() {
    val context = LocalContext.current.applicationContext
    val drawerState = rememberDrawerState(DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    val sessionStore = remember(context) { AuthSessionStore.asStore(context) }
    var tab by remember { mutableStateOf(MainTab.Map) }
    var destination by remember { mutableStateOf(SideDestination.Home) }
    var session by remember { mutableStateOf(sessionStore.load()) }
    var showLoginDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var appMessage by remember { mutableStateOf<String?>(null) }
    var calendarRefreshKey by remember { mutableStateOf(0) }

    val activeBaseUrl = session?.baseUrl
        ?.takeIf { it.isNotBlank() }
        ?: BuildConfig.MEMORYBOX_BASE_URL

    val calendarRepository = remember(context, activeBaseUrl, session?.accessToken) {
        val transport = activeBaseUrl.takeIf { it.isNotBlank() }?.let { baseUrl ->
            NetworkCalendarServerTransport(
                client = UrlConnectionMemoryBoxHttpClient(MemoryBoxConfig(baseUrl)),
                accessTokenProvider = { sessionStore.load()?.accessToken },
                refreshAccessToken = { refreshAccessToken(baseUrl, sessionStore) },
            )
        } ?: NoopCalendarServerTransport

        CalendarRepositoryImpl(
            store = CalendarJsonStore.appPrivate(context),
            transport = transport,
        )
    }

    val friendRepository = remember(activeBaseUrl, session?.accessToken, session?.uid) {
        if (activeBaseUrl.isNotBlank() && session?.accessToken?.isNotBlank() == true) {
            NetworkFriendRepository(
                HttpUrlConnectionFriendTransport(
                    baseUrl = activeBaseUrl,
                    bearerTokenProvider = { sessionStore.load()?.accessToken },
                    refreshTokenProvider = { refreshAccessToken(activeBaseUrl, sessionStore) },
                ),
            )
        } else {
            LocalFriendRepository(session?.uid.orEmpty())
        }
    }

    LaunchedEffect(activeBaseUrl, session?.uid, session?.accessToken) {
        val current = session
        if (current != null && activeBaseUrl.isNotBlank() && current.accessToken.isNotBlank()) {
            withContext(Dispatchers.IO) {
                syncCalendarAfterLogin(context, activeBaseUrl, sessionStore)
            }
            calendarRefreshKey += 1
        }
    }

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            ModalDrawerSheet {
                SideMenu(
                    session = session,
                    onLogin = {
                        showLoginDialog = true
                        scope.launch { drawerState.close() }
                    },
                    onWidget = {
                        destination = SideDestination.Widget
                        scope.launch { drawerState.close() }
                    },
                    onFriend = {
                        destination = SideDestination.Friend
                        scope.launch { drawerState.close() }
                    },
                    onSetting = {
                        destination = SideDestination.Setting
                        scope.launch { drawerState.close() }
                    },
                    onLogout = {
                        sessionStore.clear()
                        session = null
                        destination = SideDestination.Home
                        scope.launch { drawerState.close() }
                    },
                    onDeleteUser = {
                        showDeleteDialog = true
                        scope.launch { drawerState.close() }
                    },
                )
            }
        },
    ) {
        Scaffold(
            topBar = {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                ) {
                    Button(onClick = { scope.launch { drawerState.open() } }) {
                        Text("☰")
                    }
                    Spacer(Modifier.weight(1f))
                    Text(session?.userName?.let { "$it 님" } ?: "MemoryBox")
                }
            },
            bottomBar = {
                if (destination == SideDestination.Home) {
                    NavigationBar {
                        MainTab.entries.forEach { item ->
                            NavigationBarItem(
                                selected = item == tab,
                                onClick = { tab = item },
                                label = { Text(item.label) },
                                icon = { Text(if (item == MainTab.Map) "지도" else "일정") },
                            )
                        }
                    }
                }
            },
        ) { padding ->
            when (destination) {
                SideDestination.Home -> when (tab) {
                    MainTab.Map -> MapScreen(Modifier.padding(padding))
                    MainTab.Calendar -> CalendarScreen(
                        modifier = Modifier.padding(padding),
                        repository = calendarRepository,
                        refreshFromServer = session?.accessToken?.isNotBlank() == true && activeBaseUrl.isNotBlank(),
                        refreshKey = calendarRefreshKey,
                    )
                }

                SideDestination.Widget -> DdayScreen(Modifier.padding(padding))
                SideDestination.Friend -> FriendScreen(
                    userId = session?.uid.orEmpty(),
                    modifier = Modifier.padding(padding),
                    repository = friendRepository,
                )
                SideDestination.Setting -> SettingScreen(
                    session = session,
                    activeBaseUrl = activeBaseUrl,
                    modifier = Modifier.padding(padding),
                )
            }
        }
    }

    if (showLoginDialog) {
        LoginDialog(
            onDismiss = { showLoginDialog = false },
            defaultBaseUrl = activeBaseUrl,
            onServerLogin = { baseUrl, type, jwt, name ->
                scope.launch(Dispatchers.IO) {
                    val repository = AuthRepository(
                        config = MemoryBoxConfig(baseUrl),
                        sessionStore = sessionStore,
                    )
                    when (val result = repository.login(type, jwt, name)) {
                        is DataResult.Success -> {
                            val newSession = result.data.copy(baseUrl = baseUrl)
                            sessionStore.save(newSession)
                            syncCalendarAfterLogin(context, baseUrl, sessionStore)
                            withContext(Dispatchers.Main) {
                                session = newSession
                                calendarRefreshKey += 1
                                showLoginDialog = false
                                appMessage = null
                            }
                        }

                        is DataResult.Failure -> withContext(Dispatchers.Main) {
                            appMessage = result.message
                        }
                    }
                }
            },
            onLocalLogin = { name ->
                val newSession = UserSession(
                    userName = name.ifBlank { "name" },
                    uid = "local-user",
                    accessToken = "",
                    refreshToken = "",
                    baseUrl = activeBaseUrl,
                )
                sessionStore.save(newSession)
                session = newSession
                showLoginDialog = false
            },
        )
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("회원탈퇴") },
            text = { Text("회원탈퇴를 하시겠습니까?\n모든 데이터가 사라지며 복구 불가합니다.") },
            confirmButton = {
                TextButton(onClick = {
                    val current = session
                    if (current != null && activeBaseUrl.isNotBlank() && current.accessToken.isNotBlank()) {
                        scope.launch(Dispatchers.IO) {
                            val repository = AuthRepository(
                                config = MemoryBoxConfig(activeBaseUrl),
                                sessionStore = sessionStore,
                            )
                            when (val result = repository.deleteUser()) {
                                is DataResult.Success -> withContext(Dispatchers.Main) {
                                    session = null
                                    destination = SideDestination.Home
                                    showDeleteDialog = false
                                    appMessage = result.message
                                }

                                is DataResult.Failure -> withContext(Dispatchers.Main) {
                                    showDeleteDialog = false
                                    appMessage = result.message
                                }
                            }
                        }
                    } else {
                        sessionStore.clear()
                        session = null
                        destination = SideDestination.Home
                        showDeleteDialog = false
                    }
                }) {
                    Text("확인")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("취소")
                }
            },
        )
    }

    appMessage?.let { message ->
        AlertDialog(
            onDismissRequest = { appMessage = null },
            text = { Text(message) },
            confirmButton = {
                TextButton(onClick = { appMessage = null }) {
                    Text("확인")
                }
            },
        )
    }
}

private fun refreshAccessToken(
    baseUrl: String,
    sessionStore: UserSessionStore,
): String? {
    if (baseUrl.isBlank()) return null
    return when (
        val result = AuthRepository(
            config = MemoryBoxConfig(baseUrl),
            sessionStore = sessionStore,
        ).refresh()
    ) {
        is DataResult.Success -> result.data.accessToken
        is DataResult.Failure -> null
    }
}

private fun syncCalendarAfterLogin(
    context: android.content.Context,
    baseUrl: String,
    sessionStore: UserSessionStore,
) {
    if (baseUrl.isBlank()) return
    val repository = CalendarRepositoryImpl(
        store = CalendarJsonStore.appPrivate(context),
        transport = NetworkCalendarServerTransport(
            client = UrlConnectionMemoryBoxHttpClient(MemoryBoxConfig(baseUrl)),
            accessTokenProvider = { sessionStore.load()?.accessToken },
            refreshAccessToken = { refreshAccessToken(baseUrl, sessionStore) },
        ),
    )
    repository.syncServer()
}

@Composable
private fun SideMenu(
    session: UserSession?,
    onLogin: () -> Unit,
    onWidget: () -> Unit,
    onFriend: () -> Unit,
    onSetting: () -> Unit,
    onLogout: () -> Unit,
    onDeleteUser: () -> Unit,
) {
    Column(
        modifier = Modifier.padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (session == null) {
            Button(onClick = onLogin, modifier = Modifier.fillMaxWidth()) {
                Text("로그인")
            }
        } else {
            Text("${session.userName} 님 환영합니다.")
        }

        HorizontalDivider()

        Button(onClick = onWidget, modifier = Modifier.fillMaxWidth()) {
            Text("위젯")
        }

        if (session != null) {
            Button(onClick = onFriend, modifier = Modifier.fillMaxWidth()) {
                Text("친구")
            }
        }

        Button(onClick = onSetting, modifier = Modifier.fillMaxWidth()) {
            Text("설정")
        }

        if (session != null) {
            Button(onClick = onDeleteUser, modifier = Modifier.fillMaxWidth()) {
                Text("회원탈퇴")
            }
            Button(onClick = onLogout, modifier = Modifier.fillMaxWidth()) {
                Text("로그아웃")
            }
        }
    }
}

@Composable
private fun SettingScreen(
    session: UserSession?,
    activeBaseUrl: String,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("설정", style = androidx.compose.material3.MaterialTheme.typography.titleLarge)
        Text("앱 정보", style = androidx.compose.material3.MaterialTheme.typography.titleMedium)
        Text("앱 이름: MemoryBox")
        Text("빌드 타입: ${BuildConfig.BUILD_TYPE}")
        Text("서버 주소: ${activeBaseUrl.ifBlank { "설정되지 않음" }}")

        HorizontalDivider()

        Text("계정", style = androidx.compose.material3.MaterialTheme.typography.titleMedium)
        Text(session?.userName?.let { "$it 님으로 로그인됨" } ?: "로그인되어 있지 않습니다.")
    }
}

@Composable
private fun LoginDialog(
    onDismiss: () -> Unit,
    defaultBaseUrl: String,
    onServerLogin: (String, LoginType, String, String) -> Unit,
    onLocalLogin: (String) -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var baseUrl by remember { mutableStateOf(defaultBaseUrl) }
    var jwt by remember { mutableStateOf("") }
    var loginType by remember { mutableStateOf(LoginType.Apple) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("로그인 방법 선택") },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("이름") },
                )
                OutlinedTextField(
                    value = baseUrl,
                    onValueChange = { baseUrl = it },
                    label = { Text("BASE_URL") },
                )
                OutlinedTextField(
                    value = jwt,
                    onValueChange = { jwt = it },
                    label = { Text("${loginType.serverValue} token") },
                )
                Row {
                    Button(onClick = { loginType = LoginType.Apple }) {
                        Text("Apple")
                    }
                    Button(onClick = { loginType = LoginType.Kakao }) {
                        Text("Kakao")
                    }
                }
            }
        },
        confirmButton = {
            Button(
                enabled = baseUrl.isNotBlank() && jwt.isNotBlank(),
                onClick = { onServerLogin(baseUrl, loginType, jwt, name.ifBlank { "name" }) },
            ) {
                Text("서버 로그인")
            }
        },
        dismissButton = {
            Row {
                TextButton(onClick = { onLocalLogin(name) }) {
                    Text("로컬 로그인")
                }
                TextButton(onClick = onDismiss) {
                    Text("취소")
                }
            }
        },
    )
}
