//
//  MockData.swift
//  Chat_Room
//
//  Created by Cao Hai on 1/6/26.
//

import Foundation

struct MockRoom: Identifiable {
    let id: UUID
    let name: String
    let lastMessage: String
    let unreadCount: Int
    let timeString: String
}

struct MockRoomsData {
    static let rooms = [
        MockRoom(id: UUID(), name: "Hội Dev Python 🐍", lastMessage: "Backend xong API auth rồi nhé ông ơi!", unreadCount: 3, timeString: "10:30"),
        MockRoom(id: UUID(), name: "Kèo Nhậu Cuối Tuần 🍻", lastMessage: "Chốt địa điểm chưa anh em?", unreadCount: 0, timeString: "Hôm qua"),
        MockRoom(id: UUID(), name: "iOS SwiftUI 18+", lastMessage: "Hiệu ứng mới của iOS 18 mượt thật sự.", unreadCount: 0, timeString: "28 thg 5")
    ]
}

// Mock chat messages used by ChatRoomViewModel
struct MockData {
    static let chatMessages: [MockMessage] = [
        MockMessage(
            senderName: "Alice",
            content: "Chào team, mọi người ổn chứ?",
            imageUrl: nil,
            isCurrentUser: false,
            timestamp: Date().addingTimeInterval(-3600),
            status: .delivered
        ),
        MockMessage(
            senderName: "Me",
            content: "Ổn nha! Sprint này tiến độ sao rồi?",
            imageUrl: nil,
            isCurrentUser: true,
            timestamp: Date().addingTimeInterval(-3500),
            status: .sent
        ),
        MockMessage(
            senderName: "Bob",
            content: "API auth đã xong, đang viết docs.",
            imageUrl: nil,
            isCurrentUser: false,
            timestamp: Date().addingTimeInterval(-3400),
            status: .delivered
        ),
        MockMessage(
            senderName: "Me",
            content: "Tuyệt vời! 👏",
            imageUrl: nil,
            isCurrentUser: true,
            timestamp: Date().addingTimeInterval(-3300),
            status: .sent
        )
    ]
}
