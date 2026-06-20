import SwiftUI

@Observable
class ChatListViewModel {
    var allRooms: [ChatRoomModel] = []
    var searchText: String = "" // Biến lưu trữ từ khóa tìm kiếm
    
    init() {
        // Tải dữ liệu giả lập danh sách phòng chat từ MockRoomsData và map sang ChatRoomModel
        self.allRooms = MockRoomsData.rooms.map { mock in
            ChatRoomModel(
                name: mock.name,
                lastMessage: mock.lastMessage,
                time: mock.timeString,
                unreadCount: mock.unreadCount,
                isOnline: false // Bạn có thể thay đổi logic này (random/true/false) tùy nhu cầu
            )
        }
    }
    
    // Thuộc tính tính toán để lọc danh sách phòng theo thanh Search
    var filteredRooms: [ChatRoomModel] {
        if searchText.isEmpty {
            return allRooms
        } else {
            return allRooms.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}
