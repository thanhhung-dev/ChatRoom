import Foundation

struct Message: Codable, Equatable {
  let id: Int
  let roomId: Int
  let userId: Int?
  let username: String?
  let displayName: String?
  let content: String
  let messageType: String
  let fileUrl: String?
  let fileName: String?
  var status: String
  let createdAt: String

  enum CodingKeys: String, CodingKey {
    case id
    case roomId = "room_id"
    case userId = "user_id"
    case username
    case displayName = "display_name"
    case content
    case messageType = "message_type"
    case fileUrl = "file_url"
    case fileName = "file_name"
    case status
    case createdAt = "created_at"
    case user
  }

  private enum UserKeys: String, CodingKey {
    case id
    case username
    case displayName = "display_name"
  }

  init(
    id: Int,
    roomId: Int,
    userId: Int?,
    username: String?,
    displayName: String?,
    content: String,
    messageType: String = "text",
    fileUrl: String? = nil,
    fileName: String? = nil,
    status: String = "sent",
    createdAt: String = ISO8601DateFormatter().string(from: Date())
  ) {
    self.id = id
    self.roomId = roomId
    self.userId = userId
    self.username = username
    self.displayName = displayName
    self.content = content
    self.messageType = messageType
    self.fileUrl = fileUrl
    self.fileName = fileName
    self.status = status
    self.createdAt = createdAt
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)

    id = try c.decodeIfPresent(Int.self, forKey: .id) ?? -1
    roomId = try c.decodeIfPresent(Int.self, forKey: .roomId) ?? -1

    if let userContainer = try? c.nestedContainer(keyedBy: UserKeys.self, forKey: .user) {
      userId = try userContainer.decodeIfPresent(Int.self, forKey: .id)
      username = try userContainer.decodeIfPresent(String.self, forKey: .username)
      displayName = try userContainer.decodeIfPresent(String.self, forKey: .displayName)
    } else {
      userId = try c.decodeIfPresent(Int.self, forKey: .userId)
      username = try c.decodeIfPresent(String.self, forKey: .username)
      displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
    }

    content = try c.decodeIfPresent(String.self, forKey: .content) ?? ""

    messageType = try c.decodeIfPresent(String.self, forKey: .messageType) ?? "text"
    status = try c.decodeIfPresent(String.self, forKey: .status) ?? "sent"

    fileUrl = try c.decodeIfPresent(String.self, forKey: .fileUrl)
    fileName = try c.decodeIfPresent(String.self, forKey: .fileName)

    createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(id, forKey: .id)
    try c.encode(roomId, forKey: .roomId)
    try c.encodeIfPresent(userId, forKey: .userId)
    try c.encodeIfPresent(username, forKey: .username)
    try c.encodeIfPresent(displayName, forKey: .displayName)
    try c.encode(content, forKey: .content)
    try c.encode(messageType, forKey: .messageType)
    try c.encodeIfPresent(fileUrl, forKey: .fileUrl)
    try c.encodeIfPresent(fileName, forKey: .fileName)
    try c.encode(status, forKey: .status)
    try c.encode(createdAt, forKey: .createdAt)
  }
}
