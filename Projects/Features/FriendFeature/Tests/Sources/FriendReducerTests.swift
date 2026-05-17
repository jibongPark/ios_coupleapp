import ComposableArchitecture
import FriendDomain
import Testing
@testable import FriendFeature

@MainActor
struct FriendReducerTests {
    @Test
    func didFetchFriendsStoresFriends() async {
        let friend = FriendVO(id: "friend-id", name: "친구")
        let store = TestStore(initialState: FriendReducer.State()) {
            FriendReducer()
        }

        await store.send(.didFetchFriends([friend])) { state in
            state.friends = [friend]
        }
    }

    @Test
    func didAcceptFriendMovesRequestToFriends() async {
        let request = FriendRequestVO(
            senderId: "friend-id",
            senderName: "친구",
            receiverId: "me",
            receiverName: "나"
        )
        let friend = FriendVO(id: "friend-id", name: "친구")
        var state = FriendReducer.State()
        state.requests = [request]
        let store = TestStore(initialState: state) {
            FriendReducer()
        }

        await store.send(.didAcceptFriend(friend)) { state in
            state.requests = []
            state.friends = [friend]
        }
    }

    @Test
    func didFetchActiveSharedSpaceStoresSharedSpace() async {
        let sharedSpace = SharedSpaceVO(
            id: "space-id",
            members: [SharedSpaceMemberVO(userId: "partner-id", name: "파트너")]
        )
        let store = TestStore(initialState: FriendReducer.State()) {
            FriendReducer()
        }

        await store.send(.didFetchActiveSharedSpace(sharedSpace)) { state in
            state.activeSharedSpace = sharedSpace
        }
    }

    @Test
    func didCreatePairingInviteStoresInvite() async {
        let invite = PairingInviteVO(code: "123456", sharedSpaceId: "space-id", inviterId: "me")
        let store = TestStore(initialState: FriendReducer.State()) {
            FriendReducer()
        }

        await store.send(.didCreatePairingInvite(invite)) { state in
            state.pairingInvite = invite
        }
    }

    @Test
    func pairingCodeChangedUpdatesInput() async {
        let store = TestStore(initialState: FriendReducer.State()) {
            FriendReducer()
        }

        await store.send(.pairingCodeChanged("ABC123")) { state in
            state.pairingCode = "ABC123"
        }
    }

    @Test
    func didAcceptPairingInviteStoresSharedSpaceAndClearsCode() async {
        let sharedSpace = SharedSpaceVO(id: "space-id")
        var state = FriendReducer.State()
        state.pairingCode = "ABC123"
        let store = TestStore(initialState: state) {
            FriendReducer()
        }

        await store.send(.didAcceptPairingInvite(sharedSpace)) { state in
            state.activeSharedSpace = sharedSpace
            state.pairingCode = ""
            state.pairingInvite = nil
        }
    }

    @Test
    func didLeaveSharedSpaceClearsSharedSpace() async {
        var state = FriendReducer.State()
        state.activeSharedSpace = SharedSpaceVO(id: "space-id")
        state.pairingInvite = PairingInviteVO(code: "123456", sharedSpaceId: "space-id", inviterId: "me")
        let store = TestStore(initialState: state) {
            FriendReducer()
        }

        await store.send(.didLeaveSharedSpace) { state in
            state.activeSharedSpace = nil
            state.pairingInvite = nil
        }
    }
}
