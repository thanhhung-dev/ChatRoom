import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    private let decoder = JSONDecoder()
    
    private func request<T: Codable>(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        requireAuth: Bool = true,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: "\(Constants.apiBaseURL)\(path)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requireAuth, let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error { completion(.failure(error)); return }
            
            // Xử lý khi Token hết hạn (Mã lỗi 401)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 && requireAuth {
                self?.refreshAccessToken { success in
                    if success {
                        // Thử lại request cũ bằng token mới
                        self?.request(path: path, method: method, body: body, requireAuth: requireAuth, completion: completion)
                    } else {
                        TokenManager.shared.clear()
                        // ÉP BUỘC PHẢI PHÁT NOTIFICATION TRÊN MAIN THREAD ĐỂ UI THAY ĐỔI AN TOÀN
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .didLogoutRequired, object: nil)
                        }
                    }
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không nhận được dữ liệu từ máy chủ"])))
                return
            }
            
            completion(self?.decodeResponse(T.self, from: data) ?? .failure(NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "NetworkManager không khả dụng"])))
        }.resume()
    }
    
    private func decodeResponse<T: Codable>(_ type: T.Type, from data: Data) -> Result<T, Error> {
        do {
            if let apiResponse = try? decoder.decode(APIResponse<T>.self, from: data) {
                if apiResponse.success, let val = apiResponse.data {
                    return .success(val)
                }
                if let err = apiResponse.error {
                    return .failure(NSError(domain: "API", code: 400, userInfo: [NSLocalizedDescriptionKey: err.message]))
                }
            }
            
            return .success(try decoder.decode(T.self, from: data))
        } catch {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Dữ liệu không hợp lệ"
            print("❌ [Lỗi Parse JSON]: \(error)")
            print("↩︎ [Server Response]: \(serverMessage)")
            return .failure(NSError(domain: "API", code: 400, userInfo: [NSLocalizedDescriptionKey: serverMessage]))
        }
    }
    
    func login(params: [String: Any], completion: @escaping (Result<AuthData, Error>) -> Void) {
        request(path: "/auth/login", method: "POST", body: params, requireAuth: false) { (result: Result<AuthData, Error>) in
            if case .success(let data) = result {
                TokenManager.shared.accessToken = data.accessToken
                TokenManager.shared.refreshToken = data.refreshToken
                TokenManager.shared.currentUser = data.user
            }
            completion(result)
        }
    }
    
    func register(params: [String: Any], completion: @escaping (Result<AuthData, Error>) -> Void) {
        request(path: "/auth/register", method: "POST", body: params, requireAuth: false) { (result: Result<AuthData, Error>) in
            if case .success(let data) = result {
                TokenManager.shared.accessToken = data.accessToken
                TokenManager.shared.refreshToken = data.refreshToken
                TokenManager.shared.currentUser = data.user
            }
            completion(result)
        }
    }
    
    func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = TokenManager.shared.refreshToken,
              let url = URL(string: "\(Constants.apiBaseURL)/auth/refresh") else { completion(false); return }
              
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken])
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                completion(false)
                return
            }
            
            switch self.decodeResponse(RefreshResponse.self, from: data) {
            case .success(let dataResponse):
                TokenManager.shared.accessToken = dataResponse.accessToken
                completion(true)
            case .failure:
                completion(false)
            }
        }.resume()
    }
    
    func fetchRooms(completion: @escaping (Result<PaginatedResponse<Room>, Error>) -> Void) {
        request(path: "/rooms?page=1&per_page=50", completion: completion)
    }
    
    func createRoom(name: String, description: String?, completion: @escaping (Result<Room, Error>) -> Void) {
        var body: [String: Any] = ["name": name]
        if let desc = description, !desc.isEmpty {
            body["description"] = desc
        }
        request(path: "/rooms", method: "POST", body: body, completion: completion)
    }
    
    func joinRoom(inviteCode: String, completion: @escaping (Result<Room, Error>) -> Void) {
        request(path: "/rooms/join", method: "POST", body: ["invite_code": inviteCode], completion: completion)
    }
    
    func fetchMessages(roomId: Int, completion: @escaping (Result<PaginatedResponse<Message>, Error>) -> Void) {
        request(path: "/messages/\(roomId)/messages?page=1&per_page=50", completion: completion)
    }
    
    // --- TỐI ƯU LUỒNG UPLOAD FILE ĐÍNH KÈM CHỐNG CRASH DECODE ---
    func uploadFile(
        roomId: Int,
        fileData: Data,
        fileName: String,
        mimeType: String,
        completion: @escaping (Result<Message, Error>) -> Void
    ) {
        guard let url = URL(string: "\(Constants.apiBaseURL)/messages/\(roomId)/messages/file") else {
            completion(.failure(NSError(domain: "API", code: 400, userInfo: [NSLocalizedDescriptionKey: "Địa chỉ URL không hợp lệ"])))
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error { completion(.failure(error)); return }
            
            // Tải file cũng cần kiểm tra Token 401 như API thông thường
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                self?.refreshAccessToken { success in
                    if success {
                        self?.uploadFile(roomId: roomId, fileData: fileData, fileName: fileName, mimeType: mimeType, completion: completion)
                    } else {
                        TokenManager.shared.clear()
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .didLogoutRequired, object: nil)
                        }
                    }
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "API", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không có dữ liệu trả về"])))
                return
            }
            
            completion(self?.decodeResponse(Message.self, from: data) ?? .failure(NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "NetworkManager không khả dụng"])))
        }.resume()
    }
}

extension Notification.Name {
    static let didLogoutRequired = Notification.Name("didLogoutRequired")
}
