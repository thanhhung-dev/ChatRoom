import SwiftUI

struct ChatListView: View {
    @State private var viewModel = ChatListViewModel()
    
    var body: some View {
        NavigationStack {
            // Render danh sách các phòng đã được lọc
            List(viewModel.filteredRooms) { room in
                // NavigationLink để bấm vào nhảy sang màn hình ChatRoomView
                NavigationLink(destination: ChatRoomView()) {
                    ChatRoomRowView(room: room)
                }
            }
            .listStyle(.plain) // Giúp danh sách nhìn phẳng và hiện đại hơn
            .navigationTitle("Tin nhắn")
            .searchable(text: $viewModel.searchText, prompt: "Tìm kiếm phòng chat...")
            .toolbar {
                // Nút tạo phòng mới ở góc phải trên cùng
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Action mở popup tạo phòng
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
    }
}

// MARK: - Component hiển thị 1 dòng phòng chat
struct ChatRoomRowView: View {
    let room: ChatRoomModel
    
    var body: some View {
        HStack(spacing: 15) {
            // Khối Avatar nhóm + Trạng thái Online
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.2.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                
                // Hiển thị chấm xanh nếu có người đang online
                if room.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }
            
            // Khối Tên phòng và Tin nhắn cuối
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(room.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1) // Cắt chữ bằng "..." nếu tin nhắn quá dài
            }
            
            Spacer()
            
            // Khối Thời gian và Badge số tin nhắn chưa đọc
            VStack(alignment: .trailing, spacing: 6) {
                Text(room.time)
                    .font(.caption)
                    .foregroundColor(room.unreadCount > 0 ? .blue : .gray)
                
                if room.unreadCount > 0 {
                    Text("\(room.unreadCount)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                } else {
                    Spacer().frame(height: 16) // Mẹo: Giữ layout cố định không bị co giật khi không có badge
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ChatListView()
}
