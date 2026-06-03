import SwiftUI

struct ChatRoomView: View {
    // Khởi tạo và quản lý ViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ChatRoomViewModel()
    @State private var messageText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 1. HEADER PHÒNG CHAT
            headerView
            
            Divider()
            
            // MARK: - 2. DANH SÁCH TIN NHẮN CHAT
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.chatMessages) { message in
                            ChatBubbleRow(message: message)
                                .id(message.id) // Gắn ID để định vị vị trí cuộn
                        }
                        
                        // Hiển thị Typing Indicator row khi đầu bên kia đang gõ
                        if viewModel.isTyping {
                            typingIndicatorRow
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                // Tự động cuộn mượt mà xuống dưới cùng khi có tin nhắn mới (mảng thay đổi count)
                .onChange(of: viewModel.chatMessages.count) { _, _ in
                    if let lastMessageId = viewModel.chatMessages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastMessageId, anchor: .bottom)
                        }
                    }
                }
            }
            
            // MARK: - 3. HÀNG GỢI Ý THÔNG MINH COREML
            smartReplyRow
            
            // MARK: - 4. THANH CÔNG CỤ CHAT DƯỚI CÙNG
            bottomChatBar
        }
        .navigationBarHidden(true) // Ẩn thanh điều hướng gốc của hệ thống để dùng Header custom
    }
}

// MARK: - Các thành phần UI nhỏ (Subviews Extension)
extension ChatRoomView {
    
    // Giao diện Header phòng chat
    private var headerView: some View {
        HStack(spacing: 15) {
            Button(action: {
    dismiss() // Dòng này sẽ ra lệnh cho NavigationStack lùi lại 1 bước
}) {
    Image(systemName: "chevron.left")
        .font(.title2)
        .foregroundColor(.black)
}
            
            Image(systemName: "person.2.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Hội Dev Python 🐍")
                    .font(.headline)
                Text("3 thành viên online")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            NavigationLink(destination: RoomDetailView()) {
    Image(systemName: "info.circle")
        .font(.title3)
}
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // Hàng nút Smart Reply của CoreML
    private var smartReplyRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.smartReplies, id: \.self) { reply in
                    Button(action: {
                        viewModel.selectSmartReply(reply)
                    }) {
                        Text(reply)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    // Thanh gõ văn bản và các nút chức năng dưới chân màn hình
    private var bottomChatBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Nhấp nút "+" này để toggle bật/tắt hiệu ứng Typing Indicator giả lập
                withAnimation {
                    viewModel.isTyping.toggle()
                }
            }) {
                Image(systemName: "plus")
                    .font(.title3)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
            
            TextField("Nhập tin nhắn...", text: $viewModel.messageText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
            
            Button(action: {
                viewModel.sendMessage()
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .foregroundColor(viewModel.messageText.isEmpty ? .gray : .blue)
                    .padding(8)
            }
            .disabled(viewModel.messageText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
    
    // Dòng thông báo trạng thái đang nhập chữ
    private var typingIndicatorRow: some View {
        HStack {
            Text("Dev BE đang nhập...")
                .font(.caption)
                .foregroundColor(.gray)
                .italic()
            Spacer()
        }
        .padding(.leading, 8)
    }
}

#Preview {
    ChatRoomView()
}
