import Foundation

enum MessageStatus {
    case sent
    case delivered
}

struct MockMessage: Identifiable, Equatable {
    let id = UUID()
    let senderName: String
    let content: String
    let imageUrl: String?
    let isCurrentUser: Bool
    let timestamp: Date
    let status: MessageStatus
    
    static func == (lhs: MockMessage, rhs: MockMessage) -> Bool {
        return lhs.id == rhs.id
    }
}
