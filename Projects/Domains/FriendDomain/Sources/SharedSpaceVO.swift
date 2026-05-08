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
