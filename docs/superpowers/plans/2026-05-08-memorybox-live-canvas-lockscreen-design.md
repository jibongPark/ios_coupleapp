# MemoryBox Live Canvas / Lock Screen Snapshot Design

## Goal

Add a paired-user drawing and handwriting feature where users can draw or write in the app and share the result with their paired partner. The app should sync strokes in near real time, while each partner's lock screen displays an updated snapshot of the shared canvas within OS limits.

## Recommended Direction

Use a two-layer model:

1. **Live Canvas inside the app**
   - Sync strokes at stroke/event level.
   - Partner can see drawing updates quickly while the app is open.
   - Preserve vector stroke data so the canvas can be replayed, edited, or re-rendered.

2. **Lock Screen Snapshot**
   - Render the latest canvas to an image snapshot.
   - Update lock screen presentation on a throttled cadence, such as every 1-3 seconds or on stroke end.
   - Use the best available platform-specific lock-screen surface.

This avoids promising impossible high-frequency lock screen updates while still delivering the core emotional experience: a partner's drawing or note appears on the other person's screen.

## Platform Constraints

### iOS

- Lock Screen Widgets are not intended for high-frequency real-time updates.
- WidgetKit has refresh limits and timeline behavior.
- Live Activities can appear on the Lock Screen and Dynamic Island, but still have update frequency, payload, and system policy limits.
- Recommended first implementation:
  - App canvas syncs strokes in near real time.
  - A canvas snapshot is written into an App Group container.
  - A WidgetKit Lock Screen widget or Live Activity displays the latest snapshot.
  - Use throttling to avoid excessive updates.

### Android

- Modern Android has limited general-purpose lock screen widget support.
- Lock-screen visible notifications are more reliable than true arbitrary lock screen widgets.
- Home screen widgets can be supported as a fallback.
- Recommended first implementation:
  - App canvas syncs strokes in near real time.
  - A foreground/ongoing or high-visibility notification can display latest snapshot where allowed.
  - Existing widget infrastructure can be extended for home screen snapshot display.

## User Experience

### Entry Point

Add a new feature entry point such as:

- `Live Canvas`
- `우리 낙서장`
- `잠금화면 낙서`

Recommended Korean label: `우리 낙서장`.

### Not Paired

If the user is not paired:

- Explain that the feature requires pairing.
- Show a button/link to the Pairing screen.
- Do not allow publishing strokes to shared sync.

### Paired

If paired:

- Show a blank or last saved shared canvas.
- Tools:
  - Pen
  - Eraser
  - Color selection
  - Stroke width selection
  - Clear canvas with confirmation
- User can draw or handwrite.
- Partner receives strokes in near real time when online.
- Lock screen snapshot updates after stroke end or throttled interval.

### Lock Screen Setup

Show setup instructions in-app:

- iOS: enable Lock Screen widget or Live Activity if available.
- Android: enable notification/widget display depending on implementation.

## Data Model

### SharedCanvas

```text
SharedCanvas
- id: String
- sharedSpaceId: String
- title: String?
- latestSnapshotVersion: Int
- latestSnapshotUrl: String?
- localSnapshotPath: String?
- createdAt: Date
- updatedAt: Date
```

### CanvasStroke

```text
CanvasStroke
- id: String
- canvasId: String
- sharedSpaceId: String
- authorId: String
- sequence: Int
- tool: pen | eraser
- colorHex: String
- lineWidth: Double
- points: [CanvasPoint]
- createdAt: Date
```

### CanvasPoint

```text
CanvasPoint
- x: Double
- y: Double
- t: Double?
- pressure: Double?
```

Coordinates should be normalized from 0.0 to 1.0 so strokes can render correctly across different screen/widget sizes.

### CanvasSnapshot

```text
CanvasSnapshot
- id: String
- canvasId: String
- sharedSpaceId: String
- version: Int
- imageUrl: String?
- localPath: String?
- width: Int
- height: Int
- createdAt: Date
```

## Sync Model

### App-Level Stroke Sync

Preferred realtime transport:

- WebSocket if backend supports it.
- SSE as a fallback.
- Polling as MVP fallback if no realtime channel exists.

Events:

```text
canvas.stroke.started
canvas.stroke.updated
canvas.stroke.ended
canvas.cleared
canvas.snapshot.updated
```

For MVP, only `stroke.ended` is required for network persistence. During active drawing, local UI can update immediately and remote can receive either batched points or final stroke.

### Lock Screen Snapshot Sync

Snapshot update policy:

- Render locally after stroke end.
- Throttle lock screen updates to at most once every 1-3 seconds.
- If multiple strokes occur quickly, coalesce them into one snapshot update.
- Store latest snapshot for widget/notification rendering.

## API Shape

Exact backend routes can be adjusted, but the app should expect capabilities like:

```text
GET    /shared-spaces/{sharedSpaceId}/canvas
POST   /shared-spaces/{sharedSpaceId}/canvas/strokes
GET    /shared-spaces/{sharedSpaceId}/canvas/strokes?afterSequence={sequence}
POST   /shared-spaces/{sharedSpaceId}/canvas/clear
POST   /shared-spaces/{sharedSpaceId}/canvas/snapshot
GET    /shared-spaces/{sharedSpaceId}/canvas/snapshot
```

If realtime is available:

```text
WS /shared-spaces/{sharedSpaceId}/canvas/live
```

## Local Persistence

### iOS

- Store stroke data in a local repository or Realm-backed model.
- Store latest snapshot image in App Group container for widget access.
- Keep current drawing state recoverable across app restart.

### Android

- Store strokes and snapshot metadata in app-private JSON or existing persistence style.
- Store latest snapshot bitmap in app-private files.
- Home widget/notification reads from local snapshot path.

## Snapshot Rendering

Render vector strokes into a bitmap:

- Use normalized canvas points.
- Render at target aspect ratio for lock screen/widget.
- Support light/dark background later.
- MVP background: MemoryBox beige or transparent/white depending on widget surface.

## Error Handling

- Not paired: block shared sync and show pairing CTA.
- Offline: allow local drawing, queue strokes for later sync.
- Sync conflict: order by `sequence` and `createdAt`; prefer append-only strokes.
- Clear canvas: require confirmation and sync `canvas.cleared` event.
- Snapshot update failure: keep showing last successful snapshot.

## Privacy / Safety

- Only paired users in the active `sharedSpaceId` can read/write canvas data.
- Unpairing should stop future sync immediately.
- Decide whether old canvas remains visible after unpairing. Recommended MVP: keep local cached image but stop remote updates and hide shared controls.

## MVP Scope

In scope:

- One shared canvas per active pair.
- Pen, eraser, color, line width.
- Stroke-end persistence and partner sync.
- Throttled snapshot rendering.
- iOS widget/live-activity-capable snapshot storage.
- Android notification/widget snapshot storage.
- Documentation and manual QA.

Out of scope for MVP:

- Multi-page canvases.
- Rich typed text blocks.
- Stickers/images.
- Infinite canvas.
- Pixel-perfect lock screen UI across all devices.
- Guaranteed per-point lock screen updates.

## Implementation Phases

1. Add shared canvas domain models and repository contracts.
2. Add local stroke persistence and snapshot rendering.
3. Add drawing screen using sharedSpaceId.
4. Add network API boundary for strokes/snapshot.
5. Add iOS lock screen snapshot surface.
6. Add Android snapshot notification/widget surface.
7. Add tests and manual QA documentation.

## Verification Plan

### Unit Tests

- Stroke model encoding/decoding.
- Normalized point rendering input.
- Repository queues strokes while offline.
- Snapshot throttle coalesces rapid strokes.
- Not paired state blocks remote publishing.

### Manual QA

- Pair two users.
- User A draws; User B sees update in app.
- Stroke-end updates latest snapshot.
- iOS lock screen/widget shows latest snapshot.
- Android notification/widget shows latest snapshot.
- Offline drawing queues and syncs later.
- Clear canvas syncs to partner.
- Unpair stops future updates.

## Open Questions

- Does the backend support WebSocket/SSE, or should MVP use polling?
- Should snapshot rendering happen on client, server, or both?
- Should lock screen updates use iOS Live Activity first or WidgetKit first?
- Should Android MVP prioritize notification or home widget?
- What is the desired canvas aspect ratio for lock screen display?

## Decision

Proceed with the recommended MVP:

- App-level near-realtime shared drawing.
- Lock screen snapshot updates through throttled platform-specific surfaces.
- Pairing/sharedSpaceId is required for sync.
- First version supports handwriting/drawing strokes; typed text can be added later.
