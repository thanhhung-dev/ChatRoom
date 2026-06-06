import Foundation

struct Room: Codable {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    let id: Int
    var name: String
    var description: String?
    let inviteCode: String
    let createdBy: Int?
    var members: [RoomMember]?
    var lastMessage: Message?
    var unreadCount: Int
    let createdAt: String
    var avatarUrl: String?
    var memberCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case members
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case createdAt = "created_at"
        case avatarUrl = "avatar_url"
        case memberCount = "member_count"
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(Int.self, forKey: .id)
        name        = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        inviteCode  = try c.decodeIfPresent(String.self, forKey: .inviteCode) ?? ""
        createdBy   = try c.decodeIfPresent(Int.self, forKey: .createdBy)
        members     = try c.decodeIfPresent([RoomMember].self, forKey: .members)
        lastMessage = try c.decodeIfPresent(Message.self, forKey: .lastMessage)
        unreadCount = try c.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0
        createdAt   = try c.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        avatarUrl   = try c.decodeIfPresent(String.self, forKey: .avatarUrl)
        memberCount = try c.decodeIfPresent(Int.self, forKey: .memberCount) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(description, forKey: .description)
        try c.encode(inviteCode, forKey: .inviteCode)
        try c.encode(createdBy, forKey: .createdBy)
        try c.encode(members, forKey: .members)
        try c.encode(lastMessage, forKey: .lastMessage)
        try c.encode(unreadCount, forKey: .unreadCount)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(avatarUrl, forKey: .avatarUrl)
        try c.encode(memberCount, forKey: .memberCount)
    }
=======
=======
>>>>>>> Stashed changes
  let id: Int
  var name: String
  var description: String?
  var avatarUrl: String?
  let inviteCode: String
  let createdBy: Int?
  var memberCount: Int
  var members: [RoomMember]?
  var lastMessage: Message?
  var unreadCount: Int
  let createdAt: String

  enum CodingKeys: String, CodingKey {
    case id, name, description
    case avatarUrl = "avatar_url"
    case inviteCode = "invite_code"
    case createdBy = "created_by"
    case memberCount = "member_count"
    case members
    case lastMessage = "last_message"
    case unreadCount = "unread_count"
    case createdAt = "created_at"
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(Int.self, forKey: .id)
    name = try c.decode(String.self, forKey: .name)
    description = try c.decodeIfPresent(String.self, forKey: .description)
    avatarUrl = try c.decodeIfPresent(String.self, forKey: .avatarUrl)
    inviteCode = try c.decodeIfPresent(String.self, forKey: .inviteCode) ?? ""
    createdBy = try c.decodeIfPresent(Int.self, forKey: .createdBy)
    memberCount = try c.decodeIfPresent(Int.self, forKey: .memberCount) ?? 0
    members = try c.decodeIfPresent([RoomMember].self, forKey: .members)
    lastMessage = try c.decodeIfPresent(Message.self, forKey: .lastMessage)
    unreadCount = try c.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0
    createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
  }
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
}

struct RoomMember: Codable {
  let userId: Int
  let username: String
  let displayName: String
  let role: String
  var isOnline: Bool
  let joinedAt: String

  enum CodingKeys: String, CodingKey {
    case id
    case user
    case userId = "user_id"
    case username
    case displayName = "display_name"
    case role
    case isOnline = "is_online"
    case joinedAt = "joined_at"
  }

  private enum UserKeys: String, CodingKey {
    case id
    case username
    case displayName = "display_name"
    case isOnline = "is_online"
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    if let user = try? c.nestedContainer(keyedBy: UserKeys.self, forKey: .user) {
      userId = try user.decode(Int.self, forKey: .id)
      username = try user.decode(String.self, forKey: .username)
      displayName = try user.decodeIfPresent(String.self, forKey: .displayName) ?? username
      isOnline = try user.decodeIfPresent(Bool.self, forKey: .isOnline) ?? false
    } else {
      userId = try c.decode(Int.self, forKey: .userId)
      username = try c.decode(String.self, forKey: .username)
      displayName = try c.decodeIfPresent(String.self, forKey: .displayName) ?? username
      isOnline = try c.decodeIfPresent(Bool.self, forKey: .isOnline) ?? false
<<<<<<< Updated upstream
    }
<<<<<<< Updated upstream

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(userId, forKey: .userId)
        try c.encode(username, forKey: .username)
        try c.encode(displayName, forKey: .displayName)
        try c.encode(role, forKey: .role)
        try c.encode(isOnline, forKey: .isOnline)
        try c.encode(joinedAt, forKey: .joinedAt)
    }
=======
=======
    }
>>>>>>> Stashed changes
    role = try c.decodeIfPresent(String.self, forKey: .role) ?? "member"
    joinedAt = try c.decodeIfPresent(String.self, forKey: .joinedAt) ?? ""
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(userId, forKey: .userId)
    try c.encode(username, forKey: .username)
    try c.encode(displayName, forKey: .displayName)
    try c.encode(role, forKey: .role)
    try c.encode(isOnline, forKey: .isOnline)
    try c.encode(joinedAt, forKey: .joinedAt)
  }
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
}
