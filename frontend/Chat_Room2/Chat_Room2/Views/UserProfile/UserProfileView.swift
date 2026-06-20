import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var auth: AuthManager
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Tài khoản")) {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(auth.currentUser?.displayName ?? "Tên người dùng")
                                .font(.headline)
                            Text(auth.currentUser?.email ?? "email@example.com")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Cài đặt")) {
                    Toggle(isOn: .constant(true)) {
                        Text("Thông báo")
                    }
                    Toggle(isOn: .constant(false)) {
                        Text("Chế độ tối")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task { await auth.logout() }
                    } label: {
                        Text("Đăng xuất")
                    }
                }
            }
            .navigationTitle("Cá nhân")
        }
    }
}

#Preview {
    UserProfileView()
        .environmentObject(AuthManager())
}
