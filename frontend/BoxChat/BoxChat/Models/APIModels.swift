import Foundation

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
