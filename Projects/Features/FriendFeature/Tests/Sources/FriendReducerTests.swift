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
}
