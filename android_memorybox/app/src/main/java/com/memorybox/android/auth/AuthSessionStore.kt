package com.memorybox.android.auth

import android.content.Context
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

interface UserSessionStore {
    fun load(): UserSession?
    fun save(session: UserSession)
    fun clear()
}

object AuthSessionStore {
    private const val PREF_NAME = "memorybox_auth"
    private const val SESSION_KEY = "session"
    private val json = Json { ignoreUnknownKeys = true }

    fun load(context: Context): UserSession? {
        val raw = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            .getString(SESSION_KEY, null)
            ?: return null
        return runCatching { json.decodeFromString<UserSession>(raw) }.getOrNull()
    }

    fun save(context: Context, session: UserSession) {
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(SESSION_KEY, json.encodeToString(session))
            .apply()
    }

    fun clear(context: Context) {
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(SESSION_KEY)
            .apply()
    }

    fun asStore(context: Context): UserSessionStore = AndroidUserSessionStore(context.applicationContext)

    private class AndroidUserSessionStore(
        private val context: Context,
    ) : UserSessionStore {
        override fun load(): UserSession? = AuthSessionStore.load(context)

        override fun save(session: UserSession) {
            AuthSessionStore.save(context, session)
        }

        override fun clear() {
            AuthSessionStore.clear(context)
        }
    }
}
