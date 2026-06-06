import Foundation

// MARK: - NetworkError

enum NetworkError: LocalizedError {
    case noConnection
    case noData
    case sessionExpired
    case serverError(String)
    case decodeError
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .noConnection:     return "Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng."
        case .noData:           return "Không nhận được dữ liệu từ máy chủ."
        case .sessionExpired:   return "Phiên đăng nhập hết hạn."
        case .serverError(let msg): return msg
        case .decodeError:      return "Phản hồi từ máy chủ không hợp lệ."
        case .invalidURL:       return "Địa chỉ URL không hợp lệ."
        }
    }
}

// MARK: - NetworkManager

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let decoder = JSONDecoder()

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

            // Debug log (xoá khi release)
            #if DEBUG
            if let raw = String(data: data, encoding: .utf8) {
                print("📦 [\(method) \(path)] \(statusCode)\n\(raw)")
            }
            #endif

            // Token hết hạn → refresh rồi thử lại
            if statusCode == 401 && requireAuth {
                self.refreshAccessToken { success in
                    if success {
                        self.request(path: path, method: method, body: body, requireAuth: requireAuth, completion: completion)
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

            completion(self.decode(T.self, from: data, statusCode: statusCode))
        }.resume()
    }

    // MARK: - Decode (có wrapper lẫn không có wrapper)

    private func decode<T: Codable>(_ type: T.Type, from data: Data, statusCode: Int) -> Result<T, Error> {

        // 4xx/5xx → lấy message từ server nếu có
        if statusCode >= 400 {
            let message = extractErrorMessage(from: data)
                ?? httpErrorMessage(for: statusCode)
            return .failure(NetworkError.serverError(message))
        }

        // Thử decode trực tiếp trước (backend trả plain JSON, không có wrapper)
        if let value = try? decoder.decode(T.self, from: data) {
            return .success(value)
        }

        // Fallback: thử decode có wrapper { status, message, data }
        if let wrapped = try? decoder.decode(APIResponse<T>.self, from: data) {
            if wrapped.success, let value = wrapped.data {
                return .success(value)
            }
            let msg = wrapped.message ?? "Lỗi hệ thống từ máy chủ. Vui lòng thử lại."
            return .failure(NetworkError.serverError(msg))
        }

        // Không decode được gì hết
        #if DEBUG
        print("❌ Decode thất bại cho type \(T.self)")
        #endif
        return .failure(NetworkError.decodeError)
    }

    // MARK: - Helpers

    private func extractErrorMessage(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json["message"] as? String
                ?? json["detail"] as? String
                ?? json["error"] as? String
        }
        return nil
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
        default:  return "Đã xảy ra lỗi (mã: \(statusCode))."
        }
    }
}

// MARK: - Auth APIs

extension NetworkManager {

    func login(params: [String: Any], completion: @escaping (Result<AuthData, Error>) -> Void) {
        request(path: "/auth/login", method: "POST", body: params, requireAuth: false) { (result: Result<AuthData, Error>) in
            if case .success(let auth) = result {
                TokenManager.shared.accessToken = auth.accessToken
                TokenManager.shared.refreshToken = auth.refreshToken
            }
            completion(result)
        }
    }

    func register(params: [String: Any], completion: @escaping (Result<AuthData, Error>) -> Void) {
        request(path: "/auth/register", method: "POST", body: params, requireAuth: false) { (result: Result<AuthData, Error>) in
            if case .success(let auth) = result {
                TokenManager.shared.accessToken = auth.accessToken
                TokenManager.shared.refreshToken = auth.refreshToken
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
}

// MARK: - Room APIs

extension NetworkManager {

    func fetchRooms(completion: @escaping (Result<PaginatedResponse<Room>, Error>) -> Void) {
        request(path: "/rooms?page=1&per_page=50", completion: completion)
    }

    func fetchRoom(roomId: Int, completion: @escaping (Result<Room, Error>) -> Void) {
        request(path: "/rooms/\(roomId)", completion: completion)
    }

    func leaveRoom(roomId: Int, completion: @escaping (Result<[String: String], Error>) -> Void) {
        request(path: "/rooms/\(roomId)/leave", method: "POST", completion: completion)
    }

    func createRoom(name: String, description: String?, completion: @escaping (Result<Room, Error>) -> Void) {
        var body: [String: Any] = ["name": name]
        if let desc = description, !desc.isEmpty { body["description"] = desc }
        request(path: "/rooms", method: "POST", body: body, completion: completion)
    }

    func joinRoom(inviteCode: String, completion: @escaping (Result<Room, Error>) -> Void) {
        request(path: "/rooms/join", method: "POST", body: ["invite_code": inviteCode], completion: completion)
    }

    func updateRoom(roomId: Int, name: String?, description: String?, completion: @escaping (Result<Room, Error>) -> Void) {
        var body: [String: Any] = [:]
        if let name = name, !name.isEmpty { body["name"] = name }
        if let desc = description { body["description"] = desc }
        request(path: "/rooms/\(roomId)", method: "PUT", body: body, completion: completion)
    }

    func uploadRoomAvatar(
        roomId: Int,
        imageData: Data,
        completion: @escaping (Result<Room, Error>) -> Void
    ) {
        guard let url = URL(string: "\(Constants.apiBaseURL)/rooms/\(roomId)/avatar") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = TokenManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            if error != nil { completion(.failure(NetworkError.noConnection)); return }
            guard let data = data else { completion(.failure(NetworkError.noData)); return }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200

            if statusCode == 401 {
                self.refreshAccessToken { success in
                    if success {
                        self.uploadRoomAvatar(roomId: roomId, imageData: imageData, completion: completion)
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

            completion(self.decode(Room.self, from: data, statusCode: statusCode))
        }.resume()
    }
}

// MARK: - Message APIs

extension NetworkManager {

    func fetchMessages(roomId: Int, completion: @escaping (Result<PaginatedResponse<Message>, Error>) -> Void) {
        request(path: "/messages/\(roomId)/messages?page=1&per_page=50", completion: completion)
    }

    func uploadFile(
        roomId: Int,
        fileData: Data,
        fileName: String,
        mimeType: String,
        completion: @escaping (Result<Message, Error>) -> Void
    ) {
        guard let url = URL(string: "\(Constants.apiBaseURL)/messages/\(roomId)/messages/file") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = TokenManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            if error != nil { completion(.failure(NetworkError.noConnection)); return }
            guard let data = data else { completion(.failure(NetworkError.noData)); return }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200

            if statusCode == 401 {
                self.refreshAccessToken { success in
                    if success {
                        self.uploadFile(roomId: roomId, fileData: fileData, fileName: fileName, mimeType: mimeType, completion: completion)
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

            completion(self.decode(Message.self, from: data, statusCode: statusCode))
        }.resume()
    }
}

// MARK: - Notification

extension Notification.Name {
    static let didLogoutRequired = Notification.Name("didLogoutRequired")
}
