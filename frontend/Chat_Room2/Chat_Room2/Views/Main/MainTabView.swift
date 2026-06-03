import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Danh sách phòng chat mà bạn đã làm xong
            ChatListView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Tin nhắn")
                }
                .tag(0)
            
            // Tab 2: Màn hình Cài đặt cá nhân
            UserProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Cá nhân")
                }
                .tag(1)
        }
    }
}

#Preview {
    MainTabView()
}
