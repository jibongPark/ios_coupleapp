# MemoryBox Pairing Shared Space Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a 1:1 pairing feature backed by a future-proof `sharedSpaceId` model so paired users can share calendar, travel, and D-Day data.

**Architecture:** Add pairing/shared-space domain models and local active pairing state first, then wire iOS and Android UI/repositories around that state. Calendar sharing should be connected first because iOS already has `shared` fields; trip and D-Day sharing should add `sharedSpaceId` in local models and sync boundaries without forcing a backend contract rewrite.

**Tech Stack:** Swift, TCA, Tuist modules, Moya, Realm; Kotlin, Jetpack Compose, Kotlin serialization, app-private persistence, JUnit.

---

## Prerequisites

- Work in branch: `feat/memorybox-priority-completion`
- Design doc: `docs/superpowers/plans/2026-05-08-memorybox-pairing-design.md`
- Keep changes small and commit after each task.
- If local tools are missing, still run grep/static checks and document skipped verification.

---

### Task 1: Add iOS SharedSpace Domain Models

**Files:**
- Create: `Projects/Domains/FriendDomain/Sources/SharedSpaceVO.swift`
- Modify: `Projects/Domains/FriendDomain/Sources/FriendRepository.swift`
- Test: `Projects/Features/FriendFeature/Tests/Sources/FriendReducerTests.swift`

**Step 1: Create value objects**

Add:

```swift
import Foundation

public struct SharedSpaceVO: Equatable, Sendable {
    public let id: String
    public let type: SharedSpaceType
    public let name: String?
    public let members: [SharedSpaceMemberVO]
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: String,
        type: SharedSpaceType = .pair,
        name: String? = nil,
        members: [SharedSpaceMemberVO] = [],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.members = members
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum SharedSpaceType: String, Equatable, Sendable {
    case pair
}

public struct SharedSpaceMemberVO: Equatable, Sendable {
    public let userId: String
    public let name: String
    public let role: SharedSpaceMemberRole

    public init(userId: String, name: String, role: SharedSpaceMemberRole = .member) {
        self.userId = userId
        self.name = name
        self.role = role
    }
}

public enum SharedSpaceMemberRole: String, Equatable, Sendable {
    case owner
    case member
}

public struct PairingInviteVO: Equatable, Sendable {
    public let code: String
    public let sharedSpaceId: String?
    public let inviterId: String
    public let expiresAt: Date?

    public init(code: String, sharedSpaceId: String? = nil, inviterId: String, expiresAt: Date? = nil) {
        self.code = code
        self.sharedSpaceId = sharedSpaceId
        self.inviterId = inviterId
        self.expiresAt = expiresAt
    }
}
```

**Step 2: Extend repository protocol**

In `FriendRepository.swift`, add methods:

```swift
func fetchActiveSharedSpace() -> Effect<DataResult<SharedSpaceVO?>>
func createPairingInvite() -> Effect<DataResult<PairingInviteVO>>
func acceptPairingInvite(_ code: String) -> Effect<DataResult<SharedSpaceVO>>
func leaveSharedSpace(_ id: String) -> Effect<DataResult<SharedSpaceVO>>
```

**Step 3: Run a compile-oriented check**

Run:

```bash
grep -RIn "SharedSpaceVO\|PairingInviteVO" Projects/Domains/FriendDomain/Sources
```

Expected: new types and protocol methods are present.

**Step 4: Commit**

```bash
git add Projects/Domains/FriendDomain/Sources
git commit -m "feat(ios): add shared space domain models"
```

---

### Task 2: Add iOS FriendData API And Local Active Pairing State

**Files:**
- Modify: `Projects/Data/FriendData/Sources/Network/FriendAPI.swift`
- Modify: `Projects/Data/FriendData/Sources/FriendDTO.swift`
- Modify: `Projects/Data/FriendData/Sources/FriendRepository.swift`
- Test: `Projects/Features/FriendFeature/Tests/Sources/FriendReducerTests.swift`

**Step 1: Add DTOs**

Add `SharedSpaceDTO`, `SharedSpaceMemberDTO`, and `PairingInviteDTO` with fields matching the VO names. Keep dates optional if backend format is uncertain.

**Step 2: Add API cases**

Add cases:

```swift
case activeSharedSpace
case createPairingInvite
case acceptPairingInvite(code: String)
case leaveSharedSpace(id: String)
```

Suggested paths:

```swift
/shared-spaces/active
/shared-spaces/invites
/shared-spaces/invites/{code}/accept
/shared-spaces/{id}/members/me
```

**Step 3: Implement repository methods**

Implement methods added in Task 1. Also store active shared space ID locally:

```swift
ConfigManager.shared.set("activeSharedSpaceId", sharedSpace.id)
```

On leave/unpair, clear:

```swift
ConfigManager.shared.set("activeSharedSpaceId", "")
```

**Step 4: Verify no crash on missing API base URL**

Run:

```bash
grep -RIn "missingAPIBaseURLMessage\|hasValidAPIBaseURL" Projects/Data/FriendData/Sources
```

Expected: new methods guard missing base URL like existing friend methods.

**Step 5: Commit**

```bash
git add Projects/Data/FriendData/Sources
git commit -m "feat(ios): add shared space friend data APIs"
```

---

### Task 3: Add iOS Pairing UI State To FriendFeature

**Files:**
- Modify: `Projects/Features/FriendFeature/Sources/FriendView.swift`
- Test: `Projects/Features/FriendFeature/Tests/Sources/FriendReducerTests.swift`

**Step 1: Add reducer state**

Add to `FriendReducer.State`:

```swift
var activeSharedSpace: SharedSpaceVO?
var pairingInvite: PairingInviteVO?
var pairingCode: String = ""
var isPairingLoading: Bool = false
```

**Step 2: Add actions**

Add:

```swift
case fetchActiveSharedSpace
case didFetchActiveSharedSpace(SharedSpaceVO?)
case createPairingInvite
case didCreatePairingInvite(PairingInviteVO)
case pairingCodeChanged(String)
case acceptPairingInvite
case didAcceptPairingInvite(SharedSpaceVO)
case leaveSharedSpace
case didLeaveSharedSpace
```

**Step 3: Add reducer behavior**

- `onAppear` should also send `.fetchActiveSharedSpace`.
- `createPairingInvite` calls repository.
- `acceptPairingInvite` calls repository with `state.pairingCode`.
- `leaveSharedSpace` calls repository for `state.activeSharedSpace?.id` and clears state.

**Step 4: Add tests**

Add tests for:

- `didFetchActiveSharedSpace` stores shared space
- `didCreatePairingInvite` stores invite
- `pairingCodeChanged` updates input
- `didAcceptPairingInvite` stores shared space and clears code
- `didLeaveSharedSpace` clears shared space

**Step 5: Add UI section**

In `FriendView`, add a section above friend list:

- Not paired: show invite code creation button and code input
- Paired: show partner/shared space info and unpair button
- Keep copy-my-id existing behavior

**Step 6: Commit**

```bash
git add Projects/Features/FriendFeature/Sources/FriendView.swift Projects/Features/FriendFeature/Tests/Sources/FriendReducerTests.swift
git commit -m "feat(ios): add pairing controls to friend feature"
```

---

### Task 4: Wire iOS Calendar Writes To Active SharedSpace

**Files:**
- Modify: `Projects/Data/CalendarData/Sources/CalendarRepository.swift`
- Modify: `Projects/Data/CalendarData/Sources/Network/CalendarAPI.swift`
- Test: `Projects/Domains/CalendarDomain/Tests/Sources/CalendarDomainTests.swift`

**Step 1: Add helper**

In `CalendarRepository.swift`, add:

```swift
private var activeSharedSpaceId: String? {
    let id: String? = ConfigManager.shared.get("activeSharedSpaceId")
    return id?.isEmpty == false ? id : nil
}
```

**Step 2: Apply default sharing on create/update**

When creating/updating todo, schedule, and diary, if the VO's `shared` is empty and active shared space exists, include that ID in the API payload and local persisted `shared` field.

Use conservative logic:

```swift
let shared = item.shared.isEmpty ? activeSharedSpaceId.map { [$0] } ?? [] : item.shared
```

**Step 3: Preserve private future path**

Do not force-share if an item already has explicit `shared` values. Do not add a UI privacy toggle in this task.

**Step 4: Static verification**

Run:

```bash
grep -RIn "activeSharedSpaceId\|shared" Projects/Data/CalendarData/Sources/CalendarRepository.swift
```

Expected: create/update paths reference active shared space.

**Step 5: Commit**

```bash
git add Projects/Data/CalendarData/Sources
git commit -m "feat(ios): scope calendar sharing to active pair"
```

---

### Task 5: Add Android Pairing Models And Repository

**Files:**
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/pairing/PairingModels.kt`
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/pairing/PairingRepository.kt`
- Test: `android_memorybox/app/src/test/java/com/memorybox/android/pairing/PairingRepositoryTest.kt`

**Step 1: Add serializable models**

Create Kotlin models equivalent to iOS:

```kotlin
@Serializable
data class SharedSpace(
    val id: String,
    val type: String = "pair",
    val name: String? = null,
    val members: List<SharedSpaceMember> = emptyList(),
)

@Serializable
data class SharedSpaceMember(
    val userId: String,
    val name: String,
    val role: String = "member",
)

@Serializable
data class PairingInvite(
    val code: String,
    val sharedSpaceId: String? = null,
    val inviterId: String,
    val expiresAt: String? = null,
)
```

**Step 2: Add repository interface**

Add methods:

```kotlin
suspend fun fetchActiveSharedSpace(): DataResult<SharedSpace?>
suspend fun createPairingInvite(): DataResult<PairingInvite>
suspend fun acceptPairingInvite(code: String): DataResult<SharedSpace>
suspend fun leaveSharedSpace(id: String): DataResult<SharedSpace>
```

**Step 3: Add local repository**

Persist active shared space to app-private JSON or SharedPreferences, following existing Android persistence style.

**Step 4: Add network repository**

Use the same lightweight transport pattern as `FriendRepository.kt`.

**Step 5: Add tests**

Test endpoint paths and local persistence.

**Step 6: Commit**

```bash
git add android_memorybox/app/src/main/java/com/memorybox/android/pairing android_memorybox/app/src/test/java/com/memorybox/android/pairing
git commit -m "feat(android): add pairing repository"
```

---

### Task 6: Add Android Pairing Screen

**Files:**
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/pairing/PairingScreen.kt`
- Modify: `android_memorybox/app/src/main/java/com/memorybox/android/ui/MemoryBoxApp.kt`
- Test: `android_memorybox/app/src/test/java/com/memorybox/android/pairing/PairingRepositoryTest.kt`

**Step 1: Create screen**

Compose UI should mirror iOS states:

- Not paired: create invite, enter code, accept
- Paired: show partner/member and unpair button
- Error: show message

**Step 2: Add navigation entry**

Add a Settings/Friend side-menu entry named `페어링` or include the Pairing section inside Friend screen.

Recommended first pass: include it in Friend screen to avoid adding another navigation tab.

**Step 3: Wire repository state**

Use `remember` state and coroutine actions, matching existing `FriendScreen.kt` style.

**Step 4: Commit**

```bash
git add android_memorybox/app/src/main/java/com/memorybox/android/pairing android_memorybox/app/src/main/java/com/memorybox/android/ui/MemoryBoxApp.kt
git commit -m "feat(android): add pairing screen"
```

---

### Task 7: Add sharedSpaceId To Android Calendar, Map, And D-Day Models

**Files:**
- Modify files under: `android_memorybox/app/src/main/java/com/memorybox/android/calendar/`
- Modify files under: `android_memorybox/app/src/main/java/com/memorybox/android/map/`
- Modify files under: `android_memorybox/app/src/main/java/com/memorybox/android/widget/`
- Tests under matching `android_memorybox/app/src/test/java/com/memorybox/android/*/`

**Step 1: Add field**

Add nullable `sharedSpaceId: String? = null` to local records where user-created shared data is stored.

**Step 2: Read active pairing state**

Where repositories create new records, apply active shared space if present.

**Step 3: Avoid widget device preference sharing**

D-Day record data can be shared. Selected home widget item remains device-local.

**Step 4: Add tests**

Add tests that creating calendar/trip/D-Day records while paired writes `sharedSpaceId`.

**Step 5: Commit**

```bash
git add android_memorybox/app/src/main/java/com/memorybox/android android_memorybox/app/src/test/java/com/memorybox/android
git commit -m "feat(android): scope shared data to active pair"
```

---

### Task 8: Documentation And Verification

**Files:**
- Modify: `android_memorybox/README.md`
- Modify or create: `docs/superpowers/plans/2026-05-08-memorybox-pairing-design.md`
- Optional: PR body update via `gh pr edit`

**Step 1: Update docs**

Document pairing behavior, manual QA, and backend questions.

**Step 2: Run available verification**

Run:

```bash
grep -RIn "SharedSpace\|sharedSpaceId\|Pairing" Projects android_memorybox | head -200
git status --short
```

If tools are available, also run:

```bash
cd android_memorybox
./gradlew testDebugUnitTest
./gradlew assembleDebug
```

For iOS, if tools are available:

```bash
tuist generate
tuist test
```

**Step 3: Commit docs**

```bash
git add android_memorybox/README.md docs
git commit -m "docs: document memorybox pairing verification"
```

**Step 4: Push**

```bash
git push origin feat/memorybox-priority-completion
```

---

## Completion Criteria

- Pairing/shared-space design is documented.
- iOS has shared-space domain/data/reducer/UI state.
- Android has pairing models/repository/screen.
- Calendar records are scoped to active pair.
- Android calendar/map/D-Day records can store `sharedSpaceId`.
- Missing backend/tooling limitations are documented clearly.
- PR remains mergeable and working tree is clean.
