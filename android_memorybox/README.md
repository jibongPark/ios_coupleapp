# Android MemoryBox

Standalone Kotlin Android port of the iOS MemoryBox app.

## Structure

- `core`: shared date and API response/path helpers.
- `auth`: login/session models and local session storage.
- `calendar`: calendar grid logic, DTOs, and Compose calendar MVP.
- `map`: bundled `sigungu.geojson` parser and Compose canvas map MVP.
- `friend`: friend/request models and Compose MVP screen.
- `widget`: D-Day models, local store, edit screen, and native Android app widget provider.

## iOS Mapping

- SwiftUI root `AppView` -> `MemoryBoxApp`
- TCA reducers -> Compose state and feature package models
- `CalendarVO`/`CalendarDTO` -> `CalendarModels.kt` and `CalendarDtos.kt`
- `MapVO`/`TripDTO` -> `MapModels.kt`
- `WidgetVO` -> `DdayWidgetItem`
- `AuthAPI`, `CalendarAPI`, `FriendAPI` paths -> `MemoryBoxEndpoints`

## Build

```bash
cd android_memorybox
./gradlew testDebugUnitTest
./gradlew assembleDebug
```

`MEMORYBOX_BASE_URL` can be supplied as a Gradle property or environment variable:

```bash
MEMORYBOX_BASE_URL=https://example.com ./gradlew assembleDebug
```

## Current Scope

This is a buildable native Android implementation with local-first feature behavior and backend-compatible API boundaries. Production Apple/Kakao login still requires platform app keys, redirect URLs, and console configuration outside this repository.
