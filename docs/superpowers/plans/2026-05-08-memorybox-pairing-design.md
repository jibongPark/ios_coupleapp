# MemoryBox Pairing / SharedSpace Design

## Goal

Add a real pairing feature for couples or close friends so two users can share MemoryBox data such as schedules, diary entries, trip photos, and D-Day widgets.

Start with a simple 1:1 pairing experience, but model it internally as a `sharedSpaceId` so the app can later support group sharing without replacing the data model.

## Current State

The app already has friend request flows on iOS and Android:

- Friend list
- Friend requests
- Accept/reject/delete friend
- Invite/request API paths

The iOS calendar model also has `shared: [String]` fields for todos, schedules, and diaries. That gives us a partial sharing hook, but there is no explicit couple/pair/shared-space model yet.

Current gaps:

- No dedicated pairing state
- No `sharedSpaceId` or pair identity
- No automatic sharing for paired users
- No map trip or D-Day sharing model
- No clear unpair/re-pair policy

## Recommended Approach

Use a 1:1 pairing UX backed by a future-proof shared space model.

User-facing behavior:

1. User opens Pairing screen.
2. User can create/share an invite code or enter a partner's code.
3. When the other user accepts, both users become paired.
4. The app stores active pairing information locally.
5. Calendar, trip, and D-Day data are saved/synced under the active `sharedSpaceId` by default.
6. Either user can unpair, which stops future sharing but does not silently delete local data.

Internal model:

```text
SharedSpace
- id: String
- type: pair
- name: String?
- members: [SharedSpaceMember]
- createdAt: Date
- updatedAt: Date

SharedSpaceMember
- userId: String
- name: String
- role: owner | member
- joinedAt: Date

PairingInvite
- code/token: String
- sharedSpaceId: String?
- inviterId: String
- expiresAt: Date
- status: pending | accepted | expired | cancelled
```

Even though `type` starts as `pair`, using `SharedSpace` avoids painting the app into a couple-only corner.

## Data Sharing Rules

### Calendar

Todos, schedules, and diaries should use the existing `shared` fields as a bridge, but the preferred new sync scope is `sharedSpaceId`.

New/updated calendar records should include:

- `sharedSpaceId` when created inside an active pair
- existing owner/user ID
- visibility: private/shared, if private entries are needed later

Initial behavior: paired users' calendar records are shared by default.

### Map Trips / Travel Photos

Trip records need a sharing scope added.

Suggested fields:

- `id`
- `sigunguCode`
- `title/content/date`
- `imagePaths` or remote image URLs
- `ownerId`
- `sharedSpaceId`
- `updatedAt`

Local image handling can stay app-private, but shared trips need backend upload/download or a remote media URL contract.

### D-Day Widgets

D-Day records should also support `sharedSpaceId`.

Suggested behavior:

- Shared D-Day list syncs between paired users.
- Each device can choose its own representative widget item locally.
- Widget display preference can remain device-local unless explicitly shared later.

## API Shape

Exact backend contract can be adjusted to the existing server, but the app should expect these capabilities:

```text
POST   /shared-spaces/invites
POST   /shared-spaces/invites/{code}/accept
GET    /shared-spaces/active
DELETE /shared-spaces/{id}/members/me

GET    /calendar?sharedSpaceId={id}
POST   /calendar/sync
GET    /trips?sharedSpaceId={id}
POST   /trips/sync
GET    /ddays?sharedSpaceId={id}
POST   /ddays/sync
```

If the backend already wants to keep `/friend/*`, pairing can be layered on accept-friend by creating or returning a `sharedSpaceId`.

## UX

Add a Pairing/Shared Space screen reachable from Settings or the side menu.

States:

1. Not paired
   - Show my invite code/link
   - Enter partner code
   - Explain what will be shared

2. Pending
   - Show pending invite/request
   - Allow cancel

3. Paired
   - Show partner name
   - Show shared features: Calendar, Travel, D-Day
   - Allow unpair with confirmation

4. Error/offline
   - Show cached pairing state if available
   - Disable invite/accept actions that require network

## Error Handling

- Missing API base URL: show a non-crashing setup message.
- Expired/invalid invite: show clear retry message.
- Already paired: block accepting another pair unless user unpairs first.
- Network failure: keep local paired state unchanged and retry later.
- Unpair: require confirmation because it changes sharing behavior.

## Testing Plan

### iOS Unit Tests

- Pairing reducer state transitions
- Invite creation success/failure
- Accept invite stores active shared space
- Unpair clears active shared space
- Calendar sharedSpaceId is included when active

### Android Unit Tests

- Pairing repository endpoint paths
- Local pairing state persistence
- Calendar/trip/D-Day records include sharedSpaceId when paired
- Unpair stops future shared writes

### Manual QA

- User A creates invite, User B accepts
- Both apps show paired state
- Calendar entry created by A appears for B after sync
- Trip with image created by A appears for B after sync
- D-Day created by B appears for A after sync
- Unpair stops new sharing

## Rollout Plan

1. Add shared pairing domain models and local active pairing state.
2. Add Pairing screen and reducer/view model.
3. Wire friend accept/invite flow to active shared space.
4. Add sharedSpaceId to calendar sync.
5. Add sharedSpaceId to trip and D-Day persistence/sync.
6. Add tests and update README/manual QA checklist.

## Open Backend Questions

- Does the existing backend already have pair/group tables, or only friends?
- Should accepting a friend request automatically create a pair, or should pairing be a separate explicit action?
- How should shared trip images be uploaded and served?
- Should unpair hide old shared data, copy it locally, or keep it visible as historical data?

## Decision

Proceed with 1:1 pairing UX using `sharedSpaceId` internally. Keep the model extensible for future group sharing.
