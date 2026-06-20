import Foundation

struct ChatRoomModel: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let time: String
    let unreadCount: Int
    let isOnline: Bool
}
