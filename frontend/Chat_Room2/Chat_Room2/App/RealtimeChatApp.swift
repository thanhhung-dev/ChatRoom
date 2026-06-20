import SwiftUI

@main
struct ChatRoomApp: App {
    @StateObject private var auth = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isAuthenticated {
                    MainTabView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(auth)
        }
    }
}
