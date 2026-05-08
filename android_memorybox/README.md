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
- [ ] 로그인 후 서버 sync 시 로컬 데이터 유지/동기화 확인

### Friend
- [ ] 친구 목록 조회
- [ ] 친구 요청 목록 조회
- [ ] 친구 요청 전송
- [ ] 친구 수락/거절/삭제
- [ ] API 실패 메시지가 크래시 없이 표시됨

### Map
- [ ] 지도 로딩
- [ ] 지역 선택
- [ ] 여행 기록 추가/수정
- [ ] 이미지 선택/저장/삭제

### D-Day Widget
- [ ] D-Day 항목 추가/수정/삭제
- [ ] 대표 항목 선택
- [ ] 홈 위젯에 제목/날짜 표시
- [ ] 이미지/정렬 옵션 반영

## Current Scope

This is a buildable native Android implementation with local-first feature behavior and backend-compatible API boundaries. Production Apple/Kakao login still requires platform app keys, redirect URLs, and console configuration outside this repository.
