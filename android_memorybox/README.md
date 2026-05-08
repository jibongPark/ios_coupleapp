# Android MemoryBox

Standalone Kotlin Android port of the iOS MemoryBox app.

## Structure

- `core`: shared date and API response/path helpers.
- `auth`: login/session models and local session storage.
- `calendar`: calendar grid logic, DTOs, and Compose calendar MVP.
- `map`: bundled `sigungu.geojson` parser and Compose canvas map MVP.
- `friend`: friend/request models and Compose MVP screen.
- `pairing`: shared-space models, invite/accept/leave repositories, local active-pair persistence, and Compose pairing controls.
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

## Local Android Build Requirements

- JDK 17 이상 권장
- `JAVA_HOME` must point to the installed JDK
- Android SDK 35 and matching build tools must be installed
- `ANDROID_HOME`/`ANDROID_SDK_ROOT` or `local.properties` `sdk.dir` must point to the Android SDK
- Verify with:

```bash
java -version
echo "$JAVA_HOME"
./gradlew testDebugUnitTest
./gradlew assembleDebug
```

## Manual QA Checklist

### Environment
- [ ] JDK 17, Android SDK, SDK 35 configured
- [ ] `./gradlew testDebugUnitTest` passes
- [ ] `./gradlew assembleDebug` produces a debug APK
- [ ] Optional: `MEMORYBOX_BASE_URL` points to a reachable backend

### Auth
- [ ] 로컬 로그인으로 앱 진입 가능
- [ ] BASE_URL + Apple/Kakao token 입력 시 `/login` 요청 성공
- [ ] refresh token 흐름 확인
- [ ] 로그아웃 시 세션 제거
- [ ] 회원탈퇴 요청 성공/실패 메시지 확인

### Calendar
- [ ] 월 이동 가능
- [ ] 할 일 생성/수정/삭제 가능
- [ ] 일정 생성/수정/삭제 가능
- [ ] 다이어리 생성/수정/삭제 가능
- [ ] 페어링 상태에서 새 항목 생성 시 shared/sharedSpaceId가 active shared space로 저장됨
- [ ] 로그인 후 서버 sync 시 로컬 데이터 유지/동기화 확인

### Friend / Pairing
- [ ] 친구 목록 조회
- [ ] 친구 요청 목록 조회
- [ ] 친구 요청 전송
- [ ] 친구 수락/거절/삭제
- [ ] 페어링 초대 코드 생성
- [ ] 파트너 코드 입력 후 active shared space 표시
- [ ] 페어링 해제 후 새 Calendar/Map/D-Day 기록에 sharedSpaceId가 붙지 않음
- [ ] API 실패 메시지가 크래시 없이 표시됨

### Map
- [ ] 지도 로딩
- [ ] 지역 선택
- [ ] 여행 기록 추가/수정
- [ ] 이미지 선택/저장/삭제

### D-Day Widget
- [ ] D-Day 항목 추가/수정/삭제
- [ ] 페어링 상태에서 새 D-Day record에 sharedSpaceId가 저장됨
- [ ] 대표 항목 선택은 기기 로컬 상태로 유지됨
- [ ] 홈 위젯에 제목/날짜 표시
- [ ] 이미지/정렬 옵션 반영

## Automated Verification Coverage

The current unit test suite covers local-first domain behavior and backend boundary helpers:

- Auth session/login/refresh/logout/delete-user retry behavior
- Calendar grid generation, local persistence, sync payloads, corrupted store quarantine, and active shared-space scoping
- Friend endpoint routing, friend request mutations, and failure messages
- Pairing repository endpoint paths and local active shared-space persistence
- Map GeoJSON parsing, trip persistence, active shared-space scoping, and image file guards
- D-Day widget item persistence, active shared-space scoping, render state text, and image file guards
- Core date and endpoint helpers

Remaining gaps require configured Android tooling, emulator/device checks, or backend credentials:

- Compose UI navigation and form interaction tests
- Native app widget `RemoteViews` instrumentation tests
- Real image picker URI handling on device/emulator
- Backend integration for Apple/Kakao auth, calendar sync, friend mutations, and shared-space pairing endpoints
- Shared trip image upload/download backend contract
- APK install/launch smoke test after `assembleDebug`

## Pairing / Shared Space Scope

Pairing uses the following backend-compatible paths:

- `GET /shared-spaces/active`
- `POST /shared-spaces/invites`
- `POST /shared-spaces/invites/{code}/accept`
- `DELETE /shared-spaces/{id}/members/me`

When an active shared space is cached locally, new Calendar todos/schedules/diaries, Map trip records, and D-Day records default to that `sharedSpaceId`. D-Day selected widget item remains device-local so each phone can choose a different home-screen item.

## Current Scope

This is a buildable native Android implementation with local-first feature behavior and backend-compatible API boundaries. Production Apple/Kakao login and shared media sync still require platform app keys, redirect URLs, backend credentials, and shared media contracts outside this repository.

## Live Canvas / 우리 낙서장

`canvas` package adds the paired Live Canvas MVP:

- `CanvasModels.kt`: shared canvas, stroke, point, snapshot models with normalized 0.0-1.0 points.
- `CanvasRepository.kt`: local-first JSON persistence, offline pending strokes, clear, snapshot metadata, and backend-compatible API boundary paths.
- `CanvasSnapshotRenderer.kt` + `SnapshotThrottle.kt`: stroke-end snapshot rendering and 1-3 second throttling support.
- `CanvasScreen.kt`: Compose drawing screen with pen/eraser/color/width/clear controls, blocked when no active shared space exists.
- `CanvasSnapshotNotifier.kt`: lock-screen-visible notification fallback that displays the latest snapshot where Android notification policy permits.

Backend API boundary used by the MVP:

- `GET /shared-spaces/{sharedSpaceId}/canvas`
- `POST /shared-spaces/{sharedSpaceId}/canvas/strokes`
- `GET /shared-spaces/{sharedSpaceId}/canvas/strokes?afterSequence={sequence}`
- `POST /shared-spaces/{sharedSpaceId}/canvas/clear`
- `POST /shared-spaces/{sharedSpaceId}/canvas/snapshot`
- `GET /shared-spaces/{sharedSpaceId}/canvas/snapshot`

### Live Canvas Manual QA

- [ ] Pair two users so `SharedPreferencesActiveSharedSpaceStore` contains an active shared space.
- [ ] Open side menu → `우리 낙서장`.
- [ ] Confirm unpaired users see the pairing-required message and cannot publish strokes.
- [ ] Draw with pen; leave the screen and return; strokes remain from local JSON storage.
- [ ] Switch eraser/color/width and verify rendered strokes update.
- [ ] Tap `전체 지우기`; local strokes clear and canvas version advances.
- [ ] While offline or without `MEMORYBOX_BASE_URL`, drawing still persists locally and remote sync fails without crashing.
- [ ] After stroke end, a snapshot file is written under app-private `canvas/snapshots/`.
- [ ] On Android versions/settings that allow lock-screen notification display, latest snapshot appears in the `우리 낙서장` notification; otherwise use it as the documented fallback surface.
