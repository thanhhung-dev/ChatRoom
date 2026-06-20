import Foundation

struct AuthUser: Equatable, Identifiable {
    let id: UUID
    let email: String
    let displayName: String
}

protocol AuthServicing {
    func login(email: String, password: String) async throws -> AuthUser
    func register(email: String, password: String, displayName: String) async throws -> AuthUser
    func logout() async
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case weakPassword
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Email hoặc mật khẩu không đúng."
        case .weakPassword: return "Mật khẩu quá yếu."
        case .networkUnavailable: return "Không có kết nối mạng."
        }
    }
}

final class MockAuthService: AuthServicing {
    var shouldFailLogin = false
    var artificialDelay: Duration = .seconds(0.6)
    
    func login(email: String, password: String) async throws -> AuthUser {
        try await Task.sleep(for: artificialDelay)
        if shouldFailLogin || email.isEmpty || password.isEmpty {
            throw AuthError.invalidCredentials
        }
        return AuthUser(id: UUID(), email: email, displayName: email.components(separatedBy: "@").first ?? "User")
    }
    
    func register(email: String, password: String, displayName: String) async throws -> AuthUser {
        try await Task.sleep(for: artificialDelay)
        if password.count < 6 {
            throw AuthError.weakPassword
        }
        return AuthUser(id: UUID(), email: email, displayName: displayName.isEmpty ? "New User" : displayName)
    }
    
    func logout() async {
        // no-op for mock
        await Task.sleep(0)
    }
}
