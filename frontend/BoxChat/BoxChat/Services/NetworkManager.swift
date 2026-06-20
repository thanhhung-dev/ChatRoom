import Foundation

// MARK: - NetworkError

enum NetworkError: LocalizedError {
  case noConnection
  case noData
  case sessionExpired
  case serverError(String)
  case decodeError
  case invalidURL
  case fileTooLarge(maxMB: Int)

  var errorDescription: String? {
    switch self {
    case .noConnection: return "Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng."
    case .noData: return "Không nhận được dữ liệu từ máy chủ."
    case .sessionExpired: return "Phiên đăng nhập hết hạn."
    case .serverError(let msg): return msg
    case .decodeError: return "Phản hồi từ máy chủ không hợp lệ."
    case .invalidURL: return "Địa chỉ URL không hợp lệ."
    case .fileTooLarge(let maxMB): return "File vượt quá \(maxMB)MB. Vui lòng chọn file nhỏ hơn."
    }
  }
}

// MARK: - NetworkManager

final class NetworkManager {
  static let shared = NetworkManager()
  private init() {}

  private let decoder: JSONDecoder = {
    let d = JSONDecoder()
    return d
  }()

  // MARK: - Core Request

  func request<T: Codable>(
    path: String,
    method: String = "GET",
    body: [String: Any]? = nil,
    requireAuth: Bool = true,
    completion: @escaping (Result<T, Error>) -> Void
  ) {
    guard let url = URL(string: "\(Constants.apiBaseURL)\(path)") else {
      completion(.failure(NetworkError.invalidURL))
      return
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = method
    urlRequest.timeoutInterval = 12
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if requireAuth, let token = TokenManager.shared.accessToken {
      urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    if let body = body {
      urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: body)
    }

    URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
      guard let self = self else { return }

      if error != nil {
        completion(.failure(NetworkError.noConnection))
        return
      }

      guard let data = data else {
        completion(.failure(NetworkError.noData))
        return
      }

      let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200

      #if DEBUG
        if let raw = String(data: data, encoding: .utf8) {
          print("📦 [\(method) \(path)] \(statusCode)\n\(raw)")
        }
      #endif

      if statusCode == 401 && requireAuth {
        self.refreshAccessToken { success in
          if success {
            self.request(
              path: path, method: method, body: body,
              requireAuth: requireAuth, completion: completion)
          } else {
            TokenManager.shared.clear()
            DispatchQueue.main.async {
              NotificationCenter.default.post(name: .didLogoutRequired, object: nil)
            }
            completion(.failure(NetworkError.sessionExpired))
          }
        }
        return
      }

      completion(self.decodeWrapped(T.self, from: data, statusCode: statusCode))
    }.resume()
  }

  // MARK: - Decode

  private func decodeWrapped<T: Codable>(_ type: T.Type, from data: Data, statusCode: Int)
    -> Result<T, Error>
  {

    if statusCode >= 400 {
      if let wrapper = try? decoder.decode(APIResponse<EmptyData>.self, from: data) {
        let msg = wrapper.error ?? wrapper.message ?? httpErrorMessage(for: statusCode)
        return .failure(NetworkError.serverError(msg))
      }
      let msg = extractErrorMessage(from: data) ?? httpErrorMessage(for: statusCode)
      return .failure(NetworkError.serverError(msg))
    }

    if data.isEmpty || statusCode == 204 {
      let emptyObject = Data("{}".utf8)
      if let value = try? decoder.decode(T.self, from: emptyObject) {
        return .success(value)
      }
    }

    if let value = try? decoder.decode(T.self, from: data) {
      return .success(value)
    }

    if let wrapper = try? decoder.decode(APIResponse<T>.self, from: data) {
      if wrapper.success, let value = wrapper.data {
        return .success(value)
      }
      let msg = wrapper.error ?? wrapper.message ?? "Lỗi hệ thống từ máy chủ. Vui lòng thử lại."
      return .failure(NetworkError.serverError(msg))
    }

    #if DEBUG
      print("❌ Decode thất bại cho type \(T.self)")
      if let raw = String(data: data, encoding: .utf8) { print(raw) }
    #endif
    return .failure(NetworkError.decodeError)
  }

  // MARK: - Helpers

  private func extractErrorMessage(from data: Data) -> String? {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return nil
    }

    if let detail = json["detail"] as? String {
      return localizedServerDetail(detail)
    }

    if let details = json["detail"] as? [[String: Any]] {
      let messages = details.compactMap { item -> String? in
        guard let message = item["msg"] as? String else { return nil }
        if let loc = item["loc"] as? [Any], let field = loc.last as? String {
          return "\(localizedFieldName(field)): \(message)"
        }
        return message
      }
      if !messages.isEmpty {
        return messages.joined(separator: "\n")
      }
    }

    return json["message"] as? String ?? json["error"] as? String
  }

  private func localizedFieldName(_ field: String) -> String {
    switch field {
    case "username": return "Tên đăng nhập"
    case "email": return "Email"
    case "password": return "Mật khẩu"
    default: return field
    }
  }

  private func localizedServerDetail(_ detail: String) -> String {
    switch detail {
    case "Username already registered": return "Tên đăng nhập đã được sử dụng."
    case "Email already registered": return "Email đã được sử dụng."
    default: return detail
    }
  }

  private func httpErrorMessage(for statusCode: Int) -> String {
    switch statusCode {
    case 400: return "Yêu cầu không hợp lệ."
    case 401: return "Tài khoản hoặc mật khẩu không chính xác."
    case 403: return "Bạn không có quyền thực hiện thao tác này."
    case 404: return "Không tìm thấy tài nguyên yêu cầu."
    case 409: return "Dữ liệu đã tồn tại."
    case 422: return "Dữ liệu gửi lên không đúng định dạng."
    case 500: return "Lỗi máy chủ nội bộ. Vui lòng thử lại sau."
    default: return "Đã xảy ra lỗi (mã: \(statusCode))."
    }
  }

  private struct EmptyData: Codable {}
}

// MARK: - Auth APIs

extension NetworkManager {

  func login(params: [String: Any], completion: @escaping (Result<AuthData, Error>) -> Void) {
    request(path: "/auth/login", method: "POST", body: params, requireAuth: false) {
      (result: Result<AuthData, Error>) in
      if case .success(let auth) = result {
        TokenManager.shared.accessToken = auth.accessToken
        if let rt = auth.refreshToken { TokenManager.shared.refreshToken = rt }
        if let user = auth.user { TokenManager.shared.currentUser = user }
      }
      completion(result)
    }
  }

  func register(params: [String: Any], completion: @escaping (Result<AuthData, Error>) -> Void) {
    request(path: "/auth/register", method: "POST", body: params, requireAuth: false) {
      (result: Result<AuthData, Error>) in
      if case .success(let auth) = result {
        TokenManager.shared.accessToken = auth.accessToken
        if let rt = auth.refreshToken { TokenManager.shared.refreshToken = rt }
        if let user = auth.user { TokenManager.shared.currentUser = user }
      }
      completion(result)
    }
  }

  func refreshAccessToken(completion: @escaping (Bool) -> Void) {
    guard let refreshToken = TokenManager.shared.refreshToken else {
      completion(false)
      return
    }
    request(
      path: "/auth/refresh",
      method: "POST",
      body: ["refresh_token": refreshToken],
      requireAuth: false
    ) { (result: Result<RefreshResponse, Error>) in
      if case .success(let response) = result {
        TokenManager.shared.accessToken = response.accessToken

        completion(true)
      } else {
        completion(false)
      }
    }
  }

  func logout(completion: ((Bool) -> Void)? = nil) {
    guard let refreshToken = TokenManager.shared.refreshToken else {
      TokenManager.shared.clear()
      completion?(true)
      return
    }
    struct LogoutResponse: Codable { let message: String? }
    request(
      path: "/auth/logout",
      method: "POST",
      body: ["refresh_token": refreshToken]
    ) { (result: Result<LogoutResponse, Error>) in
      TokenManager.shared.clear()
      completion?(true)
    }
  }
}

// MARK: - User APIs

extension NetworkManager {

  func fetchMe(completion: @escaping (Result<UserResponse, Error>) -> Void) {
    request(path: "/users/me", completion: completion)
  }

  func updateMe(
    displayName: String?, avatarUrl: String?,
    completion: @escaping (Result<UserResponse, Error>) -> Void
  ) {
    var body: [String: Any] = [:]
    if let name = displayName { body["display_name"] = name }
    if let url = avatarUrl { body["avatar_url"] = url }
    request(path: "/users/me", method: "PATCH", body: body, completion: completion)
  }

  func uploadUserAvatar(
    imageData: Data,
    fileName: String = "avatar.jpg",
    completion: @escaping (Result<UserResponse, Error>) -> Void
  ) {
    uploadMultipart(
      path: "/users/me/avatar",
      fileData: imageData,
      fileName: fileName,
      mimeType: "image/jpeg",
      completion: completion
    )
  }

  func changePassword(
    current: String, new: String, completion: @escaping (Result<Bool, Error>) -> Void
  ) {
    struct Resp: Codable { let message: String? }
    let body: [String: Any] = ["current_password": current, "new_password": new]
    request(path: "/users/me/password", method: "PUT", body: body) {
      (result: Result<Resp, Error>) in
      switch result {
      case .success: completion(.success(true))
      case .failure(let err): completion(.failure(err))
      }
    }
  }
}

// MARK: - Friend APIs

extension NetworkManager {
  func searchUsers(
    query: String, completion: @escaping (Result<[UserResponse], Error>) -> Void
  ) {
    let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
    request(path: "/friends/search?q=\(encoded)", completion: completion)
  }

  func sendFriendRequest(
    username: String, completion: @escaping (Result<FriendRequestModel, Error>) -> Void
  ) {
    request(
      path: "/friends/requests",
      method: "POST",
      body: ["username": username],
      completion: completion
    )
  }

  func fetchIncomingFriendRequests(
    completion: @escaping (Result<[FriendRequestModel], Error>) -> Void
  ) {
    request(path: "/friends/requests/incoming", completion: completion)
  }

  func acceptFriendRequest(
    id: Int, completion: @escaping (Result<FriendshipModel, Error>) -> Void
  ) {
    request(path: "/friends/requests/\(id)/accept", method: "POST", completion: completion)
  }

  func rejectFriendRequest(id: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
    struct Empty: Codable {}
    request(path: "/friends/requests/\(id)/reject", method: "POST") { (result: Result<Empty, Error>) in
      switch result {
      case .success: completion(.success(true))
      case .failure(let error): completion(.failure(error))
      }
    }
  }

  func fetchFriends(completion: @escaping (Result<[FriendshipModel], Error>) -> Void) {
    request(path: "/friends", completion: completion)
  }

  func deleteFriendship(id: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
    struct Empty: Codable {}
    request(path: "/friends/\(id)", method: "DELETE") { (result: Result<Empty, Error>) in
      switch result {
      case .success:
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

// MARK: - Feed APIs

extension NetworkManager {
  struct UploadMediaItem {
    let data: Data
    let fileName: String
    let mimeType: String
  }

  func fetchFeed(completion: @escaping (Result<[FeedPostModel], Error>) -> Void) {
    request(path: "/feed/posts", completion: completion)
  }

  func createFeedPost(
    content: String,
    fileData: Data? = nil,
    fileName: String? = nil,
    mimeType: String = "application/octet-stream",
    completion: @escaping (Result<FeedPostModel, Error>) -> Void
  ) {
    if let fileData, let fileName {
      guard fileData.count <= Constants.maxUploadSizeBytes else {
        completion(.failure(NetworkError.fileTooLarge(maxMB: Constants.maxUploadSizeMB)))
        return
      }
      uploadMultipart(
        path: "/feed/posts",
        fileData: fileData,
        fileName: fileName,
        mimeType: mimeType,
        extraFields: ["content": content],
        completion: completion
      )
      return
    }

    uploadMultipart(
      path: "/feed/posts",
      fileData: Data(),
      fileName: "",
      mimeType: mimeType,
      extraFields: ["content": content],
      includeFilePart: false,
      completion: completion
    )
  }

  func createFeedPost(
    content: String,
    mediaItems: [UploadMediaItem],
    completion: @escaping (Result<FeedPostModel, Error>) -> Void
  ) {
    let totalBytes = mediaItems.reduce(0) { $0 + $1.data.count }
    guard totalBytes <= Constants.maxUploadSizeBytes else {
      completion(.failure(NetworkError.fileTooLarge(maxMB: Constants.maxUploadSizeMB)))
      return
    }
    guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !mediaItems.isEmpty else {
      completion(.failure(NetworkError.serverError("Bài đăng cần có nội dung hoặc ảnh.")))
      return
    }
    uploadMultipartFiles(
      path: "/feed/posts",
      files: mediaItems,
      fileFieldName: "files",
      extraFields: ["content": content],
      completion: completion
    )
  }

  func reactFeedPost(
    postId: Int,
    reaction: String,
    completion: @escaping (Result<FeedPostModel, Error>) -> Void
  ) {
    request(
      path: "/feed/posts/\(postId)/reactions",
      method: "POST",
      body: ["reaction": reaction],
      completion: completion
    )
  }

  func updateFeedPost(
    postId: Int,
    content: String,
    completion: @escaping (Result<FeedPostModel, Error>) -> Void
  ) {
    request(
      path: "/feed/posts/\(postId)",
      method: "PATCH",
      body: ["content": content],
      completion: completion
    )
  }

  func deleteFeedPost(postId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
    struct Empty: Codable {}
    request(path: "/feed/posts/\(postId)", method: "DELETE") { (result: Result<Empty, Error>) in
      switch result {
      case .success:
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func fetchFeedComments(
    postId: Int,
    completion: @escaping (Result<[FeedCommentModel], Error>) -> Void
  ) {
    request(path: "/feed/posts/\(postId)/comments", completion: completion)
  }

  func addFeedComment(
    postId: Int,
    content: String,
    fileData: Data? = nil,
    fileName: String? = nil,
    mimeType: String = "application/octet-stream",
    completion: @escaping (Result<FeedCommentModel, Error>) -> Void
  ) {
    if let fileData, let fileName {
      guard fileData.count <= Constants.maxUploadSizeBytes else {
        completion(.failure(NetworkError.fileTooLarge(maxMB: Constants.maxUploadSizeMB)))
        return
      }
      uploadMultipart(
        path: "/feed/posts/\(postId)/comments",
        fileData: fileData,
        fileName: fileName,
        mimeType: mimeType,
        extraFields: ["content": content],
        completion: completion
      )
      return
    }

    uploadMultipart(
      path: "/feed/posts/\(postId)/comments",
      fileData: Data(),
      fileName: "",
      mimeType: mimeType,
      extraFields: ["content": content],
      includeFilePart: false,
      completion: completion
    )
  }
}

// MARK: - Room APIs

extension NetworkManager {

  func fetchRooms(
    page: Int = 1, search: String? = nil,
    completion: @escaping (Result<PaginatedResponse<Room>, Error>) -> Void
  ) {
    var path = "/rooms?page=\(page)&per_page=50"
    if let q = search, !q.isEmpty { path += "&search=\(q)" }
    request(path: path, completion: completion)
  }

  func fetchRoom(roomId: Int, completion: @escaping (Result<Room, Error>) -> Void) {
    request(path: "/rooms/\(roomId)", completion: completion)
  }

  func createRoom(
    name: String, description: String?,
    completion: @escaping (Result<Room, Error>) -> Void
  ) {
    var body: [String: Any] = ["name": name]
    if let desc = description, !desc.isEmpty { body["description"] = desc }
    request(path: "/rooms", method: "POST", body: body, completion: completion)
  }

  func joinRoom(inviteCode: String, completion: @escaping (Result<Room, Error>) -> Void) {
    request(
      path: "/rooms/join", method: "POST", body: ["invite_code": inviteCode], completion: completion
    )
  }

  func uploadRoomAvatar(
    roomId: Int,
    imageData: Data,
    fileName: String = "avatar.jpg",
    completion: @escaping (Result<Room, Error>) -> Void
  ) {
    uploadMultipart(
      path: "/rooms/\(roomId)/avatar",
      fileData: imageData,
      fileName: fileName,
      mimeType: "image/jpeg",
      completion: completion
    )
  }

  func leaveRoom(roomId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
    struct Resp: Codable { let message: String? }
    request(path: "/rooms/\(roomId)/leave", method: "POST") { (result: Result<Resp, Error>) in
      switch result {
      case .success: completion(.success(true))
      case .failure(let err): completion(.failure(err))
      }
    }
  }

  func regenerateInviteCode(
    roomId: Int, completion: @escaping (Result<InviteCodeResponse, Error>) -> Void
  ) {
    request(path: "/rooms/\(roomId)/invite-code", method: "POST", completion: completion)
  }

  func updateRoom(
    roomId: Int, name: String?, description: String?,
    completion: @escaping (Result<Room, Error>) -> Void
  ) {
    var body: [String: Any] = [:]
    if let name { body["name"] = name }
    if let description { body["description"] = description }
    request(path: "/rooms/\(roomId)", method: "PATCH", body: body, completion: completion)
  }

  func kickMember(roomId: Int, userId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
    struct Resp: Codable { let message: String? }
    request(path: "/rooms/\(roomId)/members/\(userId)", method: "DELETE") {
      (result: Result<Resp, Error>) in
      switch result {
      case .success: completion(.success(true))
      case .failure(let err): completion(.failure(err))
      }
    }
  }

  func makeAdmin(roomId: Int, userId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
    struct Resp: Codable {}
    request(path: "/rooms/\(roomId)/members/\(userId)/make-admin", method: "POST") {
      (result: Result<Resp, Error>) in
      switch result {
      case .success: completion(.success(true))
      case .failure(let err): completion(.failure(err))
      }
    }
  }

  struct InviteCodeResponse: Codable {
    let inviteCode: String
    enum CodingKeys: String, CodingKey { case inviteCode = "invite_code" }
  }
}

// MARK: - Message APIs

extension NetworkManager {

  func fetchMessages(
    roomId: Int, page: Int = 1, beforeId: Int? = nil,
    completion: @escaping (Result<PaginatedResponse<Message>, Error>) -> Void
  ) {
    var path = "/rooms/\(roomId)/messages?page=\(page)&per_page=50"
    if let bid = beforeId { path += "&before_id=\(bid)" }
    request(path: path, completion: completion)
  }

  func sendMessage(
    roomId: Int, content: String, completion: @escaping (Result<Message, Error>) -> Void
  ) {
    request(
      path: "/rooms/\(roomId)/messages",
      method: "POST",
      body: ["content": content, "message_type": "text"],
      completion: completion
    )
  }

  func uploadFile(
    roomId: Int,
    fileData: Data,
    fileName: String,
    mimeType: String,
    caption: String? = nil,
    completion: @escaping (Result<Message, Error>) -> Void
  ) {
    guard fileData.count <= Constants.maxUploadSizeBytes else {
      completion(.failure(NetworkError.fileTooLarge(maxMB: Constants.maxUploadSizeMB)))
      return
    }

    uploadMultipart(
      path: "/rooms/\(roomId)/messages/file",
      fileData: fileData,
      fileName: fileName,
      mimeType: mimeType,
      extraFields: caption.map { ["content": $0] } ?? [:],
      completion: completion
    )
  }

  private func uploadMultipart<T: Codable>(
    path: String,
    fileData: Data,
    fileName: String,
    mimeType: String,
    extraFields: [String: String] = [:],
    includeFilePart: Bool = true,
    completion: @escaping (Result<T, Error>) -> Void
  ) {
    guard let url = URL(string: "\(Constants.apiBaseURL)\(path)") else {
      completion(.failure(NetworkError.invalidURL))
      return
    }

    let boundary = "Boundary-\(UUID().uuidString)"
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.timeoutInterval = 30
    urlRequest.setValue(
      "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    if let token = TokenManager.shared.accessToken {
      urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    var bodyData = Data()

    if includeFilePart {
      bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
      bodyData.append(
        "Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(
          using: .utf8)!)
      bodyData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
      bodyData.append(fileData)
      bodyData.append("\r\n".data(using: .utf8)!)
    }

    for (name, value) in extraFields where !value.isEmpty {
      bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
      bodyData.append(
        "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
      bodyData.append("\(value)\r\n".data(using: .utf8)!)
    }
    bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
    urlRequest.httpBody = bodyData

    URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
      guard let self = self else { return }
      if error != nil {
        completion(.failure(NetworkError.noConnection))
        return
      }
      guard let data = data else {
        completion(.failure(NetworkError.noData))
        return
      }

      let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200

      if statusCode == 401 {
        self.refreshAccessToken { success in
          if success {
            self.uploadMultipart(
              path: path,
              fileData: fileData,
              fileName: fileName,
              mimeType: mimeType,
              extraFields: extraFields,
              includeFilePart: includeFilePart,
              completion: completion
            )
          } else {
            TokenManager.shared.clear()
            DispatchQueue.main.async {
              NotificationCenter.default.post(name: .didLogoutRequired, object: nil)
            }
            completion(.failure(NetworkError.sessionExpired))
          }
        }
        return
      }
      completion(self.decodeWrapped(T.self, from: data, statusCode: statusCode))
    }.resume()
  }

  private func uploadMultipartFiles<T: Codable>(
    path: String,
    files: [UploadMediaItem],
    fileFieldName: String,
    extraFields: [String: String] = [:],
    completion: @escaping (Result<T, Error>) -> Void
  ) {
    guard let url = URL(string: "\(Constants.apiBaseURL)\(path)") else {
      completion(.failure(NetworkError.invalidURL))
      return
    }

    let boundary = "Boundary-\(UUID().uuidString)"
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.timeoutInterval = 60
    urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    if let token = TokenManager.shared.accessToken {
      urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    var bodyData = Data()
    for file in files {
      bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
      bodyData.append("Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(file.fileName)\"\r\n".data(using: .utf8)!)
      bodyData.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
      bodyData.append(file.data)
      bodyData.append("\r\n".data(using: .utf8)!)
    }

    for (name, value) in extraFields where !value.isEmpty {
      bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
      bodyData.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
      bodyData.append("\(value)\r\n".data(using: .utf8)!)
    }
    bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
    urlRequest.httpBody = bodyData

    URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
      guard let self else { return }
      if error != nil {
        completion(.failure(NetworkError.noConnection))
        return
      }
      guard let data else {
        completion(.failure(NetworkError.noData))
        return
      }

      let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
      if statusCode == 401 {
        self.refreshAccessToken { success in
          if success {
            self.uploadMultipartFiles(
              path: path,
              files: files,
              fileFieldName: fileFieldName,
              extraFields: extraFields,
              completion: completion
            )
          } else {
            TokenManager.shared.clear()
            DispatchQueue.main.async {
              NotificationCenter.default.post(name: .didLogoutRequired, object: nil)
            }
            completion(.failure(NetworkError.sessionExpired))
          }
        }
        return
      }
      completion(self.decodeWrapped(T.self, from: data, statusCode: statusCode))
    }.resume()
  }
}

// MARK: - Notification

extension Notification.Name {
  static let didLogoutRequired = Notification.Name("didLogoutRequired")
}
