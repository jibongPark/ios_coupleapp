# MemoryBox Live Canvas Lock Screen Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a paired-user Live Canvas feature where app-level strokes sync between paired users and lock-screen surfaces display a throttled latest snapshot.

**Architecture:** Add shared canvas models/repositories scoped by `sharedSpaceId`, then implement drawing UI, local stroke persistence, snapshot rendering, and platform-specific snapshot display. Start with stroke-end sync and snapshot throttling so the feature works within iOS/Android lock-screen update limits.

**Tech Stack:** Swift, SwiftUI, TCA, Tuist modules, WidgetKit/App Group where available; Kotlin, Jetpack Compose, Kotlin serialization, app-private files, Android widget/notification fallback, JUnit.

---

## Prerequisites

- Work in branch: `feat/memorybox-priority-completion` or a new feature branch from it.
- Design doc: `docs/superpowers/plans/2026-05-08-memorybox-live-canvas-lockscreen-design.md`
- Pairing/sharedSpace implementation should exist first.
- Keep changes small and commit after each task.
- If local tools are missing, run static verification and document skipped builds/tests.

---

### Task 1: Add Shared Canvas Domain Models

**Files:**
- Create: `Projects/Domains/CanvasDomain/Sources/CanvasVO.swift`
- Create: `Projects/Domains/CanvasDomain/Sources/CanvasRepository.swift`
- Create or modify: `Projects/Domains/CanvasDomain/Project.swift`
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/canvas/CanvasModels.kt`
- Test: `android_memorybox/app/src/test/java/com/memorybox/android/canvas/CanvasModelsTest.kt`

**Step 1: Add iOS value objects**

Create models:

```swift
public struct SharedCanvasVO: Equatable, Sendable {
    public let id: String
    public let sharedSpaceId: String
    public let title: String?
    public let latestSnapshotVersion: Int
    public let latestSnapshotUrl: String?
    public let localSnapshotPath: String?
}

public struct CanvasStrokeVO: Equatable, Sendable, Identifiable {
    public let id: String
    public let canvasId: String
    public let sharedSpaceId: String
    public let authorId: String
    public let sequence: Int
    public let tool: CanvasTool
    public let colorHex: String
    public let lineWidth: Double
    public let points: [CanvasPointVO]
}

public enum CanvasTool: String, Equatable, Sendable {
    case pen
    case eraser
}

public struct CanvasPointVO: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let t: Double?
    public let pressure: Double?
}

public struct CanvasSnapshotVO: Equatable, Sendable {
    public let id: String
    public let canvasId: String
    public let sharedSpaceId: String
    public let version: Int
    public let imageUrl: String?
    public let localPath: String?
    public let width: Int
    public let height: Int
}
```

**Step 2: Add iOS repository protocol**

Add methods:

```swift
func fetchCanvas(sharedSpaceId: String) -> Effect<DataResult<SharedCanvasVO>>
func fetchStrokes(sharedSpaceId: String, afterSequence: Int?) -> Effect<DataResult<[CanvasStrokeVO]>>
func appendStroke(_ stroke: CanvasStrokeVO) -> Effect<DataResult<CanvasStrokeVO>>
func clearCanvas(sharedSpaceId: String) -> Effect<DataResult<SharedCanvasVO>>
func updateSnapshot(_ snapshot: CanvasSnapshotVO) -> Effect<DataResult<CanvasSnapshotVO>>
```

**Step 3: Add Android serializable models**

Create equivalent Kotlin models with normalized points.

**Step 4: Add Android model tests**

Test JSON encode/decode of `CanvasStroke` and normalized point values.

**Step 5: Verification**

Run:

```bash
grep -RIn "SharedCanvas\|CanvasStroke\|CanvasPoint" Projects android_memorybox/app/src/main/java android_memorybox/app/src/test/java | head -120
```

**Step 6: Commit**

```bash
git add Projects/Domains/CanvasDomain android_memorybox/app/src/main/java/com/memorybox/android/canvas android_memorybox/app/src/test/java/com/memorybox/android/canvas
git commit -m "feat: add live canvas domain models"
```

---

### Task 2: Add Local Canvas Persistence

**Files:**
- Create: `Projects/Data/CanvasData/Sources/CanvasRepository.swift`
- Create: `Projects/Data/CanvasData/Sources/CanvasDTO.swift`
- Create or modify: `Projects/Data/CanvasData/Project.swift`
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/canvas/CanvasRepository.kt`
- Test: `android_memorybox/app/src/test/java/com/memorybox/android/canvas/CanvasRepositoryTest.kt`

**Step 1: Add local-first repository behavior**

Implement local persistence for:

- Active shared canvas metadata
- Append-only strokes
- Last synced sequence
- Latest snapshot metadata

**Step 2: Apply sharedSpaceId requirement**

All canvas records must include `sharedSpaceId`. If missing, return a clear failure result.

**Step 3: Queue offline strokes**

Store strokes locally even if network sync is unavailable. Mark as pending if needed.

**Step 4: Add tests**

Test:

- Append stroke persists.
- Fetch after sequence returns newer strokes only.
- Clear canvas removes local strokes or marks clear event.
- Missing sharedSpaceId fails.

**Step 5: Commit**

```bash
git add Projects/Data/CanvasData android_memorybox/app/src/main/java/com/memorybox/android/canvas android_memorybox/app/src/test/java/com/memorybox/android/canvas
git commit -m "feat: add local live canvas persistence"
```

---

### Task 3: Add Snapshot Rendering And Throttling

**Files:**
- Create: `Projects/CoreKit/Core/Sources/CanvasSnapshotRenderer.swift`
- Create: `Projects/CoreKit/Core/Sources/ThrottledSnapshotUpdater.swift`
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/canvas/CanvasSnapshotRenderer.kt`
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/canvas/SnapshotThrottle.kt`
- Test: matching unit tests where tooling supports it

**Step 1: Implement normalized stroke rendering**

Render strokes to bitmap/image using normalized coordinates. MVP can use a fixed target size such as 600x600 or 800x800.

**Step 2: Implement throttle policy**

Rules:

- Update on stroke end.
- Coalesce rapid updates.
- Minimum interval: 1-3 seconds.

**Step 3: Store latest snapshot path**

Save generated image path in local canvas repository.

**Step 4: Tests/static checks**

Test throttle logic separately from platform rendering where possible.

**Step 5: Commit**

```bash
git add Projects/CoreKit/Core/Sources android_memorybox/app/src/main/java/com/memorybox/android/canvas android_memorybox/app/src/test/java/com/memorybox/android/canvas
git commit -m "feat: render throttled live canvas snapshots"
```

---

### Task 4: Add iOS Live Canvas Feature UI

**Files:**
- Create: `Projects/Features/CanvasFeature/Project.swift`
- Create: `Projects/Features/CanvasFeature/Sources/CanvasReducer.swift`
- Create: `Projects/Features/CanvasFeature/Sources/CanvasView.swift`
- Create: `Projects/Features/CanvasFeature/Interface/Sources/CanvasInterface.swift`
- Test: `Projects/Features/CanvasFeature/Tests/Sources/CanvasReducerTests.swift`
- Modify: `Projects/App/Main/Sources/AppView.swift`

**Step 1: Create feature module**

Follow existing TCA feature structure.

**Step 2: Add reducer state/actions**

State:

- `activeSharedSpaceId`
- `canvas`
- `strokes`
- `currentStroke`
- `selectedTool`
- `selectedColorHex`
- `lineWidth`
- `errorMessage`

Actions:

- `onAppear`
- `startStroke`
- `appendPoint`
- `endStroke`
- `clearTapped`
- `didLoadCanvas`
- `didAppendStroke`
- `didUpdateSnapshot`

**Step 3: Add SwiftUI drawing surface**

Use `DragGesture` to collect normalized points.

**Step 4: Block unpaired users**

If no active shared space exists, show pairing CTA/copy.

**Step 5: Add navigation entry**

Add side menu or tab entry: `우리 낙서장`.

**Step 6: Commit**

```bash
git add Projects/Features/CanvasFeature Projects/App/Main/Sources/AppView.swift
git commit -m "feat(ios): add live canvas feature screen"
```

---

### Task 5: Add Android Live Canvas Screen

**Files:**
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/canvas/CanvasScreen.kt`
- Modify: `android_memorybox/app/src/main/java/com/memorybox/android/ui/MemoryBoxApp.kt`
- Test: `android_memorybox/app/src/test/java/com/memorybox/android/canvas/CanvasRepositoryTest.kt`

**Step 1: Add Compose canvas**

Use `Canvas` and pointer input to collect normalized stroke points.

**Step 2: Add tools**

Pen, eraser, color, width, clear.

**Step 3: Integrate repository**

On stroke end:

- Persist stroke.
- Trigger throttled snapshot update.
- Queue/sync remote if network exists.

**Step 4: Block unpaired users**

Show pairing-required message if no active shared space.

**Step 5: Add navigation entry**

Add `우리 낙서장` to existing Android navigation.

**Step 6: Commit**

```bash
git add android_memorybox/app/src/main/java/com/memorybox/android/canvas android_memorybox/app/src/main/java/com/memorybox/android/ui/MemoryBoxApp.kt
git commit -m "feat(android): add live canvas screen"
```

---

### Task 6: Add Network API Boundary For Canvas Sync

**Files:**
- Create or modify: `Projects/Data/CanvasData/Sources/Network/CanvasAPI.swift`
- Modify: `Projects/Data/CanvasData/Sources/CanvasRepository.swift`
- Modify: `android_memorybox/app/src/main/java/com/memorybox/android/canvas/CanvasRepository.kt`
- Tests: API path tests where possible

**Step 1: Add routes**

Routes:

```text
GET /shared-spaces/{sharedSpaceId}/canvas
POST /shared-spaces/{sharedSpaceId}/canvas/strokes
GET /shared-spaces/{sharedSpaceId}/canvas/strokes?afterSequence={sequence}
POST /shared-spaces/{sharedSpaceId}/canvas/clear
POST /shared-spaces/{sharedSpaceId}/canvas/snapshot
GET /shared-spaces/{sharedSpaceId}/canvas/snapshot
```

**Step 2: Implement fallback behavior**

If backend base URL is missing, local canvas still works and remote sync returns non-crashing failure.

**Step 3: Add polling MVP**

If WebSocket is unavailable, add a simple fetch-after-sequence method callable on appear/foreground.

**Step 4: Commit**

```bash
git add Projects/Data/CanvasData android_memorybox/app/src/main/java/com/memorybox/android/canvas android_memorybox/app/src/test/java/com/memorybox/android/canvas
git commit -m "feat: add live canvas sync API boundary"
```

---

### Task 7: Add iOS Lock Screen Snapshot Surface

**Files:**
- Modify or create Widget-related iOS target files according to current project structure
- Modify: `Projects/Data/CanvasData/Sources/CanvasRepository.swift`
- Modify docs if target setup requires manual config

**Step 1: Use App Group snapshot path**

Write latest rendered snapshot to a path accessible by widget/live activity.

**Step 2: Add WidgetKit or Live Activity surface**

Recommended MVP:

- If WidgetKit target exists, extend it to show latest canvas snapshot.
- If no widget target is practical in this repo, document the required target and provide repository snapshot writer first.

**Step 3: Trigger reload conservatively**

Use throttled update calls only.

**Step 4: Commit**

```bash
git add Projects docs
git commit -m "feat(ios): add live canvas lock screen snapshot support"
```

---

### Task 8: Add Android Snapshot Notification/Widget Surface

**Files:**
- Create: `android_memorybox/app/src/main/java/com/memorybox/android/canvas/CanvasSnapshotNotifier.kt`
- Modify existing widget files if suitable
- Modify: `android_memorybox/app/src/main/AndroidManifest.xml` if permissions/services are needed

**Step 1: Add latest snapshot display surface**

Recommended MVP:

- Lock-screen visible notification with latest snapshot where OS permits.
- Home widget fallback if notification lock screen visibility is limited.

**Step 2: Keep updates throttled**

Do not notify on every point. Update only after throttle/stroke end.

**Step 3: Commit**

```bash
git add android_memorybox/app/src/main
git commit -m "feat(android): add live canvas snapshot notification"
```

---

### Task 9: Documentation And Verification

**Files:**
- Modify: `android_memorybox/README.md`
- Create or modify: `docs/superpowers/plans/2026-05-08-memorybox-live-canvas-lockscreen-design.md`
- Optional: PR body update

**Step 1: Update README/manual QA**

Add Live Canvas setup and QA:

- Pair two users.
- Draw in app.
- Partner sees app update.
- Snapshot appears on lock-screen surface/fallback.
- Offline queue behavior.
- Clear canvas.

**Step 2: Run available verification**

Run:

```bash
grep -RIn "Live Canvas\|우리 낙서장\|CanvasStroke\|CanvasSnapshot" Projects android_memorybox docs | head -200
git status --short
```

If available:

```bash
cd android_memorybox
./gradlew testDebugUnitTest
./gradlew assembleDebug
```

If available:

```bash
tuist generate
tuist test
```

**Step 3: Commit docs**

```bash
git add android_memorybox/README.md docs
git commit -m "docs: document live canvas verification"
```

**Step 4: Push**

```bash
git push origin feat-memorybox-priority-completion
```

---

## Completion Criteria

- Live Canvas design and implementation plan are documented.
- Shared canvas domain models exist on iOS and Android.
- Local stroke persistence exists.
- Drawing screen exists on iOS and Android.
- Stroke-end sync API boundary exists.
- Latest snapshot rendering and throttling exist.
- iOS and Android have a first lock-screen/fallback snapshot surface or documented target limitation.
- Not-paired state blocks publishing and points users to pairing.
- Manual QA checklist is updated.
- PR remains mergeable and working tree is clean.
