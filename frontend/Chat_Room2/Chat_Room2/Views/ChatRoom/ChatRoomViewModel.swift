import SwiftUI
import Combine

@Observable
class ChatRoomViewModel {
    var messageText: String = ""
    var isTyping: Bool = false
    var chatMessages: [MockMessage] = []
    
    // Danh sách gợi ý trả lời thông minh (Mô phỏng tính năng đầu ra của CoreML)
    var smartReplies: [String] = ["Ok luôn 👍", "Để tôi check", "Tuyệt vời!"]
    
    init() {
        // Load data ảo từ MockData lên
        self.chatMessages = MockData.chatMessages
    }
    
    // Logic gửi tin nhắn văn bản
    func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let newMessage = MockMessage(
            senderName: "Me",
            content: trimmedText,
            imageUrl: nil,
            isCurrentUser: true,
            timestamp: Date(),
            status: .sent
        )
        
        chatMessages.append(newMessage)
        messageText = "" // Xóa trắng thanh nhập chữ sau khi gửi thành công
        
        // Giả lập: Sau khi gửi 1.5s, phía Backend Python gửi tín hiệu "đang nhập" về để test UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.isTyping = true
            }
        }
    }
    
    // Logic khi người dùng nhấn chọn nhanh một nút CoreML Smart Reply
    func selectSmartReply(_ reply: String) {
        messageText = reply
        sendMessage()
    }
}
