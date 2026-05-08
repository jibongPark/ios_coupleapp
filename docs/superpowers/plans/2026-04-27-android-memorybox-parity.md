# Android MemoryBox Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Move `android_memorybox/` from buildable MVP foundation toward real Android behavior parity with the iOS MemoryBox app.

**Architecture:** Keep the single Android `:app` module, but make feature packages behave like the iOS modules: repository boundary, local-first storage, API path/body parity, and Compose screens wired to real state. Use Kotlin serialization and app-private JSON/SharedPreferences stores first to avoid migration overhead while preserving model/API contracts for later Room/Retrofit replacement.

**Tech Stack:** Kotlin, Jetpack Compose, Android app-private files, SharedPreferences, `HttpURLConnection`, Kotlin serialization, JUnit.

---

## Requirements Summary

- Persist calendar, map trips, D-Day widgets, session, and friend state across app restarts.
- Mirror iOS API paths and request/response bodies for auth, calendar sync, and friend features.
- Implement local-first calendar behavior: fetch local data, optionally sync with server when logged in, queue offline deletes, sync on login.
- Implement trip add/edit with image copy-to-private-storage semantics.
- Implement D-Day widget records with image/title/date display options and native widget refresh.
- Keep existing iOS files untouched.

## Assumptions

- `BASE_URL` and social login keys are not available in the repo, so Android uses a configurable base URL field and real HTTP client boundary without hardcoding secrets.
- Apple login on Android requires external OAuth/platform setup; this pass implements the backend-compatible login call and a manual token entry/development login shell.
- Room/Retrofit can replace JSON stores/`HttpURLConnection` later without changing domain models.

## Out Of Scope

- Play Store signing/release setup.
- Pixel-perfect UI polish.
- Production Kakao/Apple SDK setup requiring app keys, redirect URLs, and console configuration.
- Backend contract changes.

## Tasks

### Task 1: Core Network And Auth

**Files:**
- Modify/Create under `android_memorybox/app/src/main/java/com/memorybox/android/core/network/`
- Modify/Create under `android_memorybox/app/src/main/java/com/memorybox/android/auth/`
- Test under `android_memorybox/app/src/test/java/com/memorybox/android/auth/`

- [x] Add tests for login/refresh request encoding and bearer retry decision.
- [x] Implement configurable `MemoryBoxConfig`.
- [x] Implement lightweight JSON HTTP client boundary.
- [x] Implement `AuthRepository` with `/login`, `/refresh`, `/deleteUser`, session persistence, logout.

### Task 2: Calendar Local-First Repository

**Files:**
- Modify/Create under `android_memorybox/app/src/main/java/com/memorybox/android/calendar/`
- Test under `android_memorybox/app/src/test/java/com/memorybox/android/calendar/`

- [x] Add tests for local create/update/delete grouping and sync payload shape.
- [x] Implement persistent calendar store.
- [x] Implement repository methods equivalent to iOS `fetch`, `updateTodo`, `updateDiary`, `updateSchedule`, delete methods, and `syncServer`.
- [x] Wire `CalendarScreen` to repository-backed state.

### Task 3: Map Trip Persistence And Image Flow

**Files:**
- Modify/Create under `android_memorybox/app/src/main/java/com/memorybox/android/map/`
- Test under `android_memorybox/app/src/test/java/com/memorybox/android/map/`

- [x] Add tests for trip persistence and image filename storage.
- [x] Implement trip store keyed by `sigunguCode`.
- [x] Implement app-private image copy/delete helpers.
- [x] Wire map tap to add/edit trip bottom sheet or dialog.

### Task 4: Friend API And Screen State

**Files:**
- Modify/Create under `android_memorybox/app/src/main/java/com/memorybox/android/friend/`
- Test under `android_memorybox/app/src/test/java/com/memorybox/android/friend/`

- [x] Add tests for friend endpoint request paths/actions.
- [x] Implement friend repository methods: fetch, requests, request, accept, reject/delete.
- [x] Wire `FriendScreen` to repository-backed loading/error/list state.

### Task 5: D-Day Widget Parity

**Files:**
- Modify/Create under `android_memorybox/app/src/main/java/com/memorybox/android/widget/`
- Modify resources under `android_memorybox/app/src/main/res/`
- Test under `android_memorybox/app/src/test/java/com/memorybox/android/widget/`

- [x] Add tests for D-Day item upsert/remove/select behavior.
- [x] Implement image path persistence and alignment options.
- [x] Wire D-Day UI to persisted records and widget refresh.
- [x] Render selected widget title/date in native widget.

### Task 6: Integration And Verification

**Files:**
- Modify `android_memorybox/app/src/main/java/com/memorybox/android/ui/MemoryBoxApp.kt`
- Modify `android_memorybox/README.md`

- [x] Connect login success to calendar sync.
- [x] Confirm side menu gating matches iOS.
- [x] Run `./gradlew testDebugUnitTest`.
- [x] Run `./gradlew assembleDebug`.
- [x] Review untracked/generated files and residual risks.
