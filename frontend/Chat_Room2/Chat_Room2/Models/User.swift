
import Foundation

struct User: Codable {
    let id: Int
    let username: String
    let email: String
    let display_Name: String?
    let avatar_url: String?
    let is_online: Bool?
    let created_at: Date?
}
