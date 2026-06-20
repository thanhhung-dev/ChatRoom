import SwiftUI
struct ChatBubbleRow: View {
    let message: MockMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isCurrentUser {
                Spacer() // Đẩy tin nhắn của mình sang phải
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Nội dung tin nhắn (Chữ hoặc Ảnh)
                    messageContentView
                    
                    // Thời gian + Trạng thái dưới chân tin nhắn
                    HStack(spacing: 4) {
                        Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Image(systemName: message.status == .delivered ? "checkmark.circle.fill" : "checkmark")
                            .font(.system(size: 10))
                            .foregroundColor(message.status == .delivered ? .blue : .gray)
                    }
                    .padding(.trailing, 4)
                }
            } else {
                // Tin nhắn của đối phương (nằm bên trái)
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.senderName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    messageContentView
                    
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
                
                Spacer() // Đẩy tin nhắn đối phương sang trái
            }
        }
        .padding(.horizontal, 4)
    }
    
    // Tách riêng phần hiển thị Nội dung để code gọn gàng
    @ViewBuilder
    private var messageContentView: some View {
        if let imageName = message.imageUrl {
            // Nếu là tin nhắn hình ảnh
            Image(systemName: imageName) // Thay bằng Image(imageName) nếu dùng ảnh thật trong Assets
                .resizable()
                .scaledToFill()
                .frame(maxWidth: 220, maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            // Nếu là tin nhắn văn bản thông thường
            Text(message.content)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(message.isCurrentUser ? Color.blue : Color(.secondarySystemGroupedBackground))
                .foregroundColor(message.isCurrentUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}
