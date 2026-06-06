import Foundation

// MARK: - UserResponse

struct UserResponse: Codable {
  let id: Int
  let username: String
  let email: String?
  let displayName: String?
  let avatarUrl: String?
  var isOnline: Bool?
  let createdAt: String?

  enum CodingKeys: String, CodingKey {
    case id, username, email
    case displayName = "display_name"
    case avatarUrl = "avatar_url"
    case isOnline = "is_online"
    case createdAt = "created_at"
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(Int.self, forKey: .id)
    username = try c.decode(String.self, forKey: .username)
    email = try c.decodeIfPresent(String.self, forKey: .email)
    displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
    avatarUrl = try c.decodeIfPresent(String.self, forKey: .avatarUrl)
    isOnline = try c.decodeIfPresent(Bool.self, forKey: .isOnline)
    createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
  }
}
