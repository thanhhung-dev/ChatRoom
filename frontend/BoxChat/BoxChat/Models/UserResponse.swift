import Foundation

struct UserResponse: Codable {
    let id: Int
    let username: String
    let email: String?
    let avatarUrl: String?
}
