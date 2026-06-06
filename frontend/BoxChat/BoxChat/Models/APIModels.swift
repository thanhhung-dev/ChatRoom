import Foundation

struct AuthData: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}

struct RefreshResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}

struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let total: Int?
    let page: Int?
    let perPage: Int?
    
    enum CodingKeys: String, CodingKey {
        case items, total, page
        case perPage = "per_page"
    }
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.items = (try? container.decodeIfPresent([T].self, forKey: .items)) ?? []
            self.total = try container.decodeIfPresent(Int.self, forKey: .total)
            self.page = try container.decodeIfPresent(Int.self, forKey: .page)
            self.perPage = try container.decodeIfPresent(Int.self, forKey: .perPage)
        } else if let singleContainer = try? decoder.singleValueContainer(),
                  let rawArray = try? singleContainer.decode([T].self) {
            self.items = rawArray
            self.total = rawArray.count
            self.page = 1
            self.perPage = rawArray.count
        } else {
            self.items = []
            self.total = 0
            self.page = 1
            self.perPage = 0
        }
    }
}

class TokenManager {
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
