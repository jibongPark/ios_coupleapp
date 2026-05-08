# Android MemoryBox Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone Kotlin Android port of the iOS MemoryBox app under `android_memorybox/`.

**Architecture:** The Android app uses a single `:app` module with feature packages mirroring the iOS feature boundaries. Pure domain and utility code is testable on the JVM; Android UI uses Jetpack Compose, local persistence starts with app-private JSON/SharedPreferences repositories, and network code mirrors the existing REST API contracts.

**Tech Stack:** Kotlin, Android Gradle Plugin, Jetpack Compose, Kotlin serialization, OkHttp/HttpURLConnection-compatible API boundary, Android AppWidgetProvider, JUnit.

---

### Task 1: Project Foundation

**Files:**
- Create: `android_memorybox/settings.gradle.kts`
- Create: `android_memorybox/build.gradle.kts`
- Create: `android_memorybox/app/build.gradle.kts`
- Create: `android_memorybox/app/src/main/AndroidManifest.xml`
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/MainActivity.kt`

- [x] Write JVM tests for pure date/calendar helpers before implementation.
- [x] Add Gradle and Android app configuration.
- [x] Add minimal Activity host and app theme.
- [x] Run `./gradlew testDebugUnitTest`.

### Task 2: Core Domain And Utilities

**Files:**
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/core/date/MemoryBoxDates.kt`
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/calendar/domain/CalendarModels.kt`
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/widget/domain/DdayModels.kt`

- [x] Implement inclusive D-Day calculation matching iOS.
- [x] Implement calendar grid range and day key format.
- [x] Keep models serializable and independent from Android APIs.

### Task 3: Calendar MVP

**Files:**
- Create under `android_memorybox/app/src/main/java/com/memorybox/android/calendar/`

- [x] Implement in-memory/file-backed repository matching iOS calendar models.
- [x] Implement Compose month grid, selected-day list, and edit dialogs.
- [x] Preserve server DTO field names for later Retrofit replacement.

### Task 4: Map MVP

**Files:**
- Create under `android_memorybox/app/src/main/java/com/memorybox/android/map/`
- Copy asset: `android_memorybox/app/src/main/assets/sigungu.geojson`

- [x] Implement GeoJSON parser for `SIGUNGU_CD`, `SIGUNGU_NM`, and MultiPolygon coordinates.
- [x] Implement trip model/store and basic Compose map canvas.
- [x] Defer exact image clipping polish if it risks buildability.

### Task 5: Auth/Friend MVP

**Files:**
- Create under `android_memorybox/app/src/main/java/com/memorybox/android/auth/`
- Create under `android_memorybox/app/src/main/java/com/memorybox/android/friend/`

- [x] Implement token/session store and REST endpoint definitions.
- [x] Implement login dialog shell, logout/delete hooks, friend list/request UI.

### Task 6: D-Day Widget MVP

**Files:**
- Create under `android_memorybox/app/src/main/java/com/memorybox/android/widget/`
- Create: `android_memorybox/app/src/main/res/xml/dday_widget_info.xml`
- Create: `android_memorybox/app/src/main/res/layout/dday_widget.xml`

- [x] Implement D-Day item store and AppWidgetProvider.
- [x] Render selected item title and inclusive D-Day text in a native Android widget.

### Verification

- [x] Run `./gradlew testDebugUnitTest`.
- [x] Run `./gradlew assembleDebug`.
- [x] Report exact pass/fail output and any limitations.
