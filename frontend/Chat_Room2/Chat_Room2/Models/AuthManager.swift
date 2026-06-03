import Foundation
import Combine

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: AuthUser?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let service: AuthServicing
    
    init(service: AuthServicing = MockAuthService()) {
        self.service = service
    }
    
    func login(email: String, password: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            let user = try await service.login(email: email, password: password)
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Đăng nhập thất bại."
            isAuthenticated = false
        }
        isLoading = false
    }
    
    func register(email: String, password: String, displayName: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            let user = try await service.register(email: email, password: password, displayName: displayName)
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Đăng ký thất bại."
            isAuthenticated = false
        }
        isLoading = false
    }
    
    func logout() async {
        await service.logout()
        currentUser = nil
        isAuthenticated = false
    }
}
