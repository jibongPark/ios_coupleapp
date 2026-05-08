# MemoryBox Verification Checklist

Use this checklist to verify the work currently included in PR #13.

PR: https://github.com/jibongPark/ios_coupleapp/pull/13
Branch: `feat/memorybox-priority-completion`

## 0. Before Testing

- [ ] Open PR #13 and confirm it is still open/mergeable.
- [ ] Pull latest branch locally.
- [ ] Confirm current branch is `feat/memorybox-priority-completion`.
- [ ] Confirm working tree is clean before testing.
- [ ] Confirm backend base URL is available or note that backend-related checks will be skipped.
- [ ] Prepare two test accounts: User A and User B.
- [ ] Prepare at least one iOS device/simulator if available.
- [ ] Prepare at least one Android device/emulator if available.

## 1. Local Tooling / Build Environment

### iOS

- [ ] macOS environment is available.
- [ ] Xcode is installed.
- [ ] Tuist is installed.
- [ ] Run `tuist generate`.
- [ ] Open generated workspace/project in Xcode.
- [ ] Build the main iOS app target.
- [ ] Run available iOS tests with `tuist test` or Xcode test.

Expected:

- [ ] Project generation succeeds.
- [ ] App compiles.
- [ ] Tests pass or failures are documented with logs.

### Android

- [ ] JDK 17 is installed.
- [ ] `JAVA_HOME` is set.
- [ ] Android SDK 35 is installed.
- [ ] Run `cd android_memorybox`.
- [ ] Run `./gradlew testDebugUnitTest`.
- [ ] Run `./gradlew assembleDebug`.
- [ ] Install debug APK on emulator/device.

Expected:

- [ ] Unit tests pass.
- [ ] Debug APK builds.
- [ ] App launches successfully.

## 2. Existing Priority Work

### Missing API Base URL Safety

- [ ] Launch iOS app without API base URL configured.
- [ ] Try login/backend-dependent flows.
- [ ] Confirm app does not crash.
- [ ] Confirm user-facing setup/error message appears.

Expected:

- [ ] No `fatalError("URL String not found")` crash.
- [ ] No force-cast URL crash.

### Settings Entry / Android Polish

- [ ] iOS settings entry appears where expected.
- [ ] Android settings/user-flow polish is visible.
- [ ] Empty/loading/error states appear without crashes.

## 3. Pairing / SharedSpace

### Pairing Setup

- [ ] Log in as User A.
- [ ] Open Friend/Pairing screen.
- [ ] Confirm not-paired state is shown.
- [ ] Create pairing invite/code as User A.
- [ ] Log in as User B on another device/session.
- [ ] Enter User A's code as User B.
- [ ] Accept pairing.

Expected:

- [ ] Both users show paired/shared-space state.
- [ ] Active `sharedSpaceId` is stored locally.
- [ ] Invalid/expired code shows a clear error.
- [ ] Missing API base URL does not crash.

### Pairing Removal

- [ ] Use unpair/leave shared space action.
- [ ] Confirm confirmation dialog/message appears if implemented.
- [ ] Confirm paired state clears locally.
- [ ] Confirm future shared writes stop after unpair.

Expected:

- [ ] User is no longer paired.
- [ ] `activeSharedSpaceId` is cleared.
- [ ] Existing cached data handling matches expected policy.

## 4. Shared Calendar

### iOS Calendar Sharing

- [ ] Pair User A and User B.
- [ ] On User A, create a todo.
- [ ] On User A, create a schedule.
- [ ] On User A, create a diary entry.
- [ ] Sync/refresh as User B.

Expected:

- [ ] New records are scoped to the active shared space or existing shared field.
- [ ] User B can see shared calendar records after sync.
- [ ] Editing a shared record syncs correctly.
- [ ] Deleting a shared record syncs correctly.

### Android Calendar Sharing

- [ ] Pair User A and User B.
- [ ] Create calendar records on Android.
- [ ] Confirm records store/apply `sharedSpaceId`.
- [ ] Confirm records can sync or remain queued when backend is unavailable.

Expected:

- [ ] Local records persist.
- [ ] Shared-space scoping is present.
- [ ] No crash if backend is unavailable.

## 5. Shared Travel / Map Photos

- [ ] Pair User A and User B.
- [ ] Open Map/Travel screen.
- [ ] Select a region.
- [ ] Add a trip record.
- [ ] Attach/select an image.
- [ ] Save trip.
- [ ] Restart app and confirm trip persists.
- [ ] Sync/refresh as partner.

Expected:

- [ ] Trip record stores `sharedSpaceId`.
- [ ] Image is copied/stored safely in app-private storage.
- [ ] Partner can receive trip metadata when backend supports it.
- [ ] Shared image display works once backend media upload/download is available.

Backend note:

- [ ] Confirm server media upload/download contract for shared trip photos.

## 6. Shared D-Day / Widget

- [ ] Pair User A and User B.
- [ ] Create a D-Day item.
- [ ] Add title/date/image/options if available.
- [ ] Confirm D-Day item stores `sharedSpaceId`.
- [ ] Sync/refresh as partner.
- [ ] Select representative D-Day item for widget.
- [ ] Confirm widget/home display updates.

Expected:

- [ ] D-Day record data is shareable.
- [ ] Representative widget selection remains device-local.
- [ ] Partner sees shared D-Day data after sync.
- [ ] Widget does not crash if image is missing.

## 7. Live Canvas / 우리 낙서장

### Entry / Pair Requirement

- [ ] Open `우리 낙서장` while not paired.
- [ ] Confirm pairing-required message appears.
- [ ] Pair two users.
- [ ] Reopen `우리 낙서장`.

Expected:

- [ ] Not-paired users cannot publish shared strokes.
- [ ] Paired users can access canvas.

### Drawing Basics

- [ ] Draw with pen.
- [ ] Change color.
- [ ] Change stroke width.
- [ ] Use eraser.
- [ ] Clear canvas.
- [ ] Confirm clear action is protected by confirmation if implemented.

Expected:

- [ ] Strokes render correctly.
- [ ] Normalized coordinates look correct across screen sizes.
- [ ] Clear removes or resets canvas locally and sync boundary is called.

### Local Persistence

- [ ] Draw several strokes.
- [ ] Background/close app.
- [ ] Relaunch app.

Expected:

- [ ] Last canvas/strokes reload locally.
- [ ] Latest snapshot metadata/path remains available.

### Partner Sync

- [ ] User A draws a stroke.
- [ ] User B opens or refreshes canvas.
- [ ] Confirm User B receives stroke via polling/API boundary or backend sync.
- [ ] Repeat with User B drawing.

Expected:

- [ ] Strokes are scoped by `sharedSpaceId`.
- [ ] Sequence/after-sequence fetch does not duplicate strokes.
- [ ] Offline strokes are queued or preserved locally.

Backend note:

- [ ] Confirm whether backend supports WebSocket/SSE.
- [ ] If not, confirm polling endpoint behavior.

## 8. Live Canvas Snapshot / Lock Screen

### Snapshot Rendering

- [ ] Draw a stroke.
- [ ] End stroke.
- [ ] Confirm snapshot is generated.
- [ ] Draw multiple strokes quickly.
- [ ] Confirm throttle/coalescing avoids excessive updates.

Expected:

- [ ] Snapshot image shows latest drawing.
- [ ] Snapshot updates on stroke end or throttled interval.
- [ ] App does not attempt high-frequency lock-screen updates per point.

### iOS Lock Screen / WidgetKit Path

- [ ] Confirm App Group configuration is correct.
- [ ] Confirm latest snapshot is written to widget-accessible storage.
- [ ] Add/enable Lock Screen widget or supported surface.
- [ ] Draw in app.
- [ ] Lock device or view widget surface.

Expected:

- [ ] Latest snapshot appears where iOS allows it.
- [ ] Widget/lock-screen surface updates within OS limits.
- [ ] If full target setup is incomplete, required setup is documented.

### Android Notification / Widget Fallback

- [ ] Grant notification permission if required.
- [ ] Draw in app.
- [ ] Confirm notification/widget snapshot updates.
- [ ] Lock device and check lock-screen visibility.

Expected:

- [ ] Android fallback shows latest canvas snapshot where OS permits.
- [ ] Notification/widget update is throttled.
- [ ] No crash if notification permission is denied.

## 9. Backend Contract Checklist

Pairing:

- [ ] `GET /shared-spaces/active`
- [ ] `POST /shared-spaces/invites`
- [ ] `POST /shared-spaces/invites/{code}/accept`
- [ ] `DELETE /shared-spaces/{id}/members/me`

Calendar / Shared Data:

- [ ] Decide whether server prefers `sharedSpaceId`, existing `shared` array, or both.
- [ ] Confirm calendar sync reads/writes paired records correctly.
- [ ] Confirm trip records can be scoped by shared space.
- [ ] Confirm D-Day records can be scoped by shared space.

Live Canvas:

- [ ] `GET /shared-spaces/{sharedSpaceId}/canvas`
- [ ] `POST /shared-spaces/{sharedSpaceId}/canvas/strokes`
- [ ] `GET /shared-spaces/{sharedSpaceId}/canvas/strokes?afterSequence={sequence}`
- [ ] `POST /shared-spaces/{sharedSpaceId}/canvas/clear`
- [ ] `POST /shared-spaces/{sharedSpaceId}/canvas/snapshot`
- [ ] `GET /shared-spaces/{sharedSpaceId}/canvas/snapshot`
- [ ] Optional realtime: `WS /shared-spaces/{sharedSpaceId}/canvas/live`

Media:

- [ ] Confirm upload path for trip photos.
- [ ] Confirm upload path for canvas snapshots if server-rendered or server-hosted.
- [ ] Confirm auth/permission rules for paired users only.

## 10. Regression Checklist

- [ ] Login still works.
- [ ] Logout still clears session.
- [ ] Friend list still works.
- [ ] Friend request accept/reject/delete still works.
- [ ] Calendar existing local data remains visible.
- [ ] Map/trip existing local data remains visible.
- [ ] D-Day existing local data remains visible.
- [ ] App handles missing backend config gracefully.
- [ ] App handles offline mode gracefully.
- [ ] App does not crash on cold start.

## 11. Final Merge Readiness

- [ ] iOS build passes.
- [ ] iOS tests pass or known failures are documented.
- [ ] Android unit tests pass.
- [ ] Android debug APK builds.
- [ ] Manual QA critical paths pass.
- [ ] Backend API gaps are documented or resolved.
- [ ] PR body reflects Pairing and Live Canvas work.
- [ ] Screenshots/videos are attached if useful.
- [ ] Reviewer notes include skipped local verification reasons.
- [ ] PR remains mergeable.

## Known Current Limitations

- Local OpenClaw environment did not have Java/JAVA_HOME, so Android Gradle verification could not be run here.
- Local OpenClaw environment did not have Tuist, so iOS project generation/tests could not be run here.
- True high-frequency lock-screen updates are OS-limited; implementation intentionally uses throttled snapshots.
- Backend realtime/WebSocket support was not present in the repo; current implementation includes API boundary/local-first fallback.
- Shared travel photo and canvas snapshot media sync require backend media contract confirmation.
