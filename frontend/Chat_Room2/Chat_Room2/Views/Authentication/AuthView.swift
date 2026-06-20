import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var isLogin: Bool = true
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                        .scaleEffect(isLogin ? 1.0 : 1.1)
                        .animation(.easeInOut, value: isLogin)
                    
                    Text(isLogin ? "Chào mừng trở lại!" : "Tạo tài khoản mới")
                        .font(.largeTitle)
                        .bold()
                        .contentTransition(.numericText())
                }
                .padding(.bottom, 20)
                
                VStack(spacing: 16) {
                    if !isLogin {
                        TextField("Tên hiển thị", text: $username)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    
                    SecureField("Mật khẩu", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                if let error = auth.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: {
                    Task {
                        if isLogin {
                            await auth.login(email: email, password: password)
                        } else {
                            await auth.register(email: email, password: password, displayName: username)
                        }
                    }
                }) {
                    HStack {
                        if auth.isLoading {
                            ProgressView().tint(.white)
                        }
                        Text(isLogin ? "Đăng nhập" : "Đăng ký")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(auth.isLoading ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(auth.isLoading)
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isLogin.toggle()
                        password = ""
                        auth.errorMessage = nil
                    }
                }) {
                    Text(isLogin ? "Chưa có tài khoản? **Đăng ký ngay**" : "Đã có tài khoản? **Đăng nhập**")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.top, 50)
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}
