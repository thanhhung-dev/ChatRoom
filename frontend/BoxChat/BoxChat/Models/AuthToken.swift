import Foundation

<<<<<<< Updated upstream:frontend/BoxChat/BoxChat/Models/AuthToken.swift
struct AuthData: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
    =======
    // MARK: - AuthData
    
    struct AuthData: Codable {
        let user: UserResponse?
        let accessToken: String
        let refreshToken: String?
        let tokenType: String
        
        enum CodingKeys: String, CodingKey {
            case user
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case tokenType = "token_type"
        }
        
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            user = try c.decodeIfPresent(UserResponse.self, forKey: .user)
            accessToken = try c.decode(String.self, forKey: .accessToken)
            refreshToken = try c.decodeIfPresent(String.self, forKey: .refreshToken)
            tokenType = try c.decodeIfPresent(String.self, forKey: .tokenType) ?? "bearer"
        }
    }
    
    // MARK: - RefreshResponse
    
    struct RefreshResponse: Codable {
        let accessToken: String
        let tokenType: String
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
        }
    }
    
    struct APIResponse<T: Codable>: Codable {
        let success: Bool
        let data: T?
        let error: APIErrorDetail?
        let message: String?
        
        enum CodingKeys: String, CodingKey {
            case success, data, error, message
        }
        
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            success = try c.decodeIfPresent(Bool.self,             forKey: .success) ?? false
            data    = try c.decodeIfPresent(T.self,                forKey: .data)
            error   = try c.decodeIfPresent(APIErrorDetail.self,   forKey: .error)
            message = try c.decodeIfPresent(String.self,           forKey: .message)
        }
    }
    
    struct APIErrorDetail: Codable {
        let code: String
        let message: String
    }
    
    struct PaginatedResponse<T: Codable>: Codable {
        let items: [T]
        let total: Int?
        let page: Int?
        let perPage: Int?
        let totalPages: Int?
        
        enum CodingKeys: String, CodingKey {
            case items, total, page
            case perPage = "per_page"
            case totalPages = "total_pages"
        }
        
        init(from decoder: Decoder) throws {
            if let container = try? decoder.container(keyedBy: CodingKeys.self) {
                self.items = (try? container.decodeIfPresent([T].self, forKey: .items)) ?? []
                self.total = try container.decodeIfPresent(Int.self, forKey: .total)
                self.page = try container.decodeIfPresent(Int.self, forKey: .page)
                self.perPage = try container.decodeIfPresent(Int.self, forKey: .perPage)
                self.totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages)
            }
            else if let singleContainer = try? decoder.singleValueContainer(),
                    let rawArray = try? singleContainer.decode([T].self) {
                self.items = rawArray
                self.total = rawArray.count
                self.page = 1
                self.perPage = rawArray.count
                self.totalPages = 1
            }
            else {
                self.items = []
                self.total = 0
                self.page = 1
                self.perPage = 0
                self.totalPages = 1
            }
        }
        =======
        let accessToken: String
        let tokenType: String
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
        }
    }
    
    // MARK: - PaginatedResponse
    
    struct PaginatedResponse<T: Codable>: Codable {
        let items: [T]
        let total: Int?
        let page: Int?
        let perPage: Int?
        let totalPages: Int?
        
        enum CodingKeys: String, CodingKey {
            case items, total, page
            case perPage = "per_page"
            case totalPages = "total_pages"
        }
        
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            items = (try? c.decodeIfPresent([T].self, forKey: .items)) ?? []
            total = try? c.decodeIfPresent(Int.self, forKey: .total)
            page = try? c.decodeIfPresent(Int.self, forKey: .page)
            perPage = try? c.decodeIfPresent(Int.self, forKey: .perPage)
            totalPages = try? c.decodeIfPresent(Int.self, forKey: .totalPages)
        }
    }
    
    // MARK: - TokenManager
    
    final class TokenManager {
        static let shared = TokenManager()
        
        private let accessKey = "com.boxchat.access_token"
        private let refreshKey = "com.boxchat.refresh_token"
        private let userKey = "com.boxchat.current_user"
        
        private init() {}
        
        var accessToken: String? {
            get { UserDefaults.standard.string(forKey: accessKey) }
            set { UserDefaults.standard.set(newValue, forKey: accessKey) }
        }
        
        var refreshToken: String? {
            get { UserDefaults.standard.string(forKey: refreshKey) }
            set { UserDefaults.standard.set(newValue, forKey: refreshKey) }
        }
        
        var currentUser: UserResponse? {
            get {
                guard let data = UserDefaults.standard.data(forKey: userKey) else { return nil }
                return try? JSONDecoder().decode(UserResponse.self, from: data)
            }
            
            var refreshToken: String? {
                get { UserDefaults.standard.string(forKey: refreshKey) }
                set { UserDefaults.standard.set(newValue, forKey: refreshKey) }
            }
            
            var currentUser: User? {
                get {
                    guard let data = UserDefaults.standard.data(forKey: userKey) else { return nil }
                    return try? JSONDecoder().decode(User.self, from: data)
                }
                set {
                    if let user = newValue, let data = try? JSONEncoder().encode(user) {
                        UserDefaults.standard.set(data, forKey: userKey)
                    } else {
                        UserDefaults.standard.removeObject(forKey: userKey)
                    }
                }
            }
            
            func clear() {
                UserDefaults.standard.removeObject(forKey: accessKey)
                UserDefaults.standard.removeObject(forKey: refreshKey)
                set {
                    if let user = newValue, let data = try? JSONEncoder().encode(user) {
                        UserDefaults.standard.set(data, forKey: userKey)
                    } else {
                        UserDefaults.standard.removeObject(forKey: userKey)
                    }
                }
            }
            
            func clear() {
                UserDefaults.standard.removeObject(forKey: accessKey)
                UserDefaults.standard.removeObject(forKey: refreshKey)
                UserDefaults.standard.removeObject(forKey: userKey)
            }
        }
    }
}
