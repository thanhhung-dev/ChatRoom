import Foundation

protocol WebSocketServiceDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect(error: Error?)
    func webSocketDidReceiveEvent(type: String, payload: [String: Any])
}

final class WebSocketService: NSObject {
    static let shared = WebSocketService()
    
    weak var delegate: WebSocketServiceDelegate?
    private let delegates = NSHashTable<AnyObject>.weakObjects()
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    
    private var pingTimer: Timer?
    private var pongTimeoutTimer: Timer?
    private var reconnectAttempt = 0
    private var isConnected = false
    private var isConnecting = false
    private var shouldReconnect = true
    
    var localLastMessageIds: [Int: Int] = [:]
    private var joinedRoomIds = Set<Int>()
    
    private override init() { super.init() }

    func addDelegate(_ delegate: WebSocketServiceDelegate) {
        let add: () -> Void = { [weak self] in
            guard let self else { return }
            self.delegates.add(delegate)
        }
        if Thread.isMainThread {
            add()
        } else {
            DispatchQueue.main.async { add() }
        }
    }

    func removeDelegate(_ delegate: WebSocketServiceDelegate) {
        let remove: () -> Void = { [weak self] in
            guard let self else { return }
            self.delegates.remove(delegate)
            if self.delegate === delegate {
                self.delegate = nil
            }
        }
        if Thread.isMainThread {
            remove()
        } else {
            DispatchQueue.main.async { remove() }
        }
    }

    private func notifyDelegates(_ block: @escaping (WebSocketServiceDelegate) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            var notified = Set<ObjectIdentifier>()
            if let delegate = self.delegate {
                notified.insert(ObjectIdentifier(delegate as AnyObject))
                block(delegate)
            }
            self.delegates.allObjects
                .compactMap { $0 as? WebSocketServiceDelegate }
                .forEach { delegate in
                    let id = ObjectIdentifier(delegate as AnyObject)
                    guard !notified.contains(id) else { return }
                    notified.insert(id)
                    block(delegate)
                }
        }
    }
    
    // MARK: - Connect / Disconnect
    
    func connect() {
        guard !isConnected, !isConnecting else { return }
        
        shouldReconnect = true
        if let token = TokenManager.shared.accessToken, isTokenExpired(token) {
            print("🔑 WS: token expired, refreshing before connect...")
            NetworkManager.shared.refreshAccessToken { [weak self] success in
                if success {
                    self?.connectWithCurrentToken()
                } else {
                    TokenManager.shared.clear()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .didLogoutRequired, object: nil)
                    }
                }
            }
        } else {
            connectWithCurrentToken()
        }
    }
    
    private func connectWithCurrentToken() {
        guard !isConnected, !isConnecting,
              let token = TokenManager.shared.accessToken,
              let url = URL(string: "\(Constants.webSocketURL)?token=\(token)")
        else { return }
        
        isConnecting = true
        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        webSocketTask = urlSession?.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
    }
    
    private func isTokenExpired(_ token: String) -> Bool {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return true }
        
        var base64 = String(parts[1])
        let remainder = base64.count % 4
        if remainder != 0 { base64 += String(repeating: "=", count: 4 - remainder) }
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval
        else { return true }
        
        return Date().timeIntervalSince1970 >= exp - 30
    }
    
    func disconnect() {
        shouldReconnect = false
        joinedRoomIds.removeAll()
        cleanUp(reconnect: false)
    }
    
    // MARK: - Send
    
    func joinRoom(_ roomId: Int) {
        joinedRoomIds.insert(roomId)
        sendEvent(type: "join_room", payload: ["room_id": roomId])
    }

    func leaveRoom(_ roomId: Int) {
        joinedRoomIds.remove(roomId)
        sendEvent(type: "leave_room", payload: ["room_id": roomId])
    }

    func sendEvent(type: String, payload: [String: Any] = [:]) {
        guard isConnected else { return }
        sendEventNow(type: type, payload: payload)
    }

    private func sendEventNow(type: String, payload: [String: Any]) {
        var frame: [String: Any] = ["type": type]
        if !payload.isEmpty { frame["payload"] = payload }
        frame["timestamp"] = ISO8601DateFormatter().string(from: Date())
        
        guard let data = try? JSONSerialization.data(withJSONObject: frame),
              let json = String(data: data, encoding: .utf8) else { return }
        
        webSocketTask?.send(.string(json)) { error in
            if let error = error {
                print("❌ WS send error [\(type)]: \(error.localizedDescription)")
            }
        }
    }

    private func rejoinAllRooms() {
        for roomId in joinedRoomIds {
            sendEventNow(type: "join_room", payload: ["room_id": roomId])
        }
    }
    
    // MARK: - Listen
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    self.handleIncomingMessage(text)
                }
                self.listen()
            case .failure(let error):
                self.handleDisconnection(error: error)
            }
        }
    }
    
    // MARK: - Handle Messages
    
    private func handleIncomingMessage(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        
        let payload = json["payload"] as? [String: Any] ?? [:]
        
        switch type {
        case "pong":
            DispatchQueue.main.async { [weak self] in
                self?.pongTimeoutTimer?.invalidate()
                self?.pongTimeoutTimer = nil
            }
            
        case "connected":
            isConnected = true
            isConnecting = false
            reconnectAttempt = 0
            startHeartbeat()
            rejoinAllRooms()
            syncMessagesAfterReconnect()
            notifyDelegates { $0.webSocketDidConnect() }
            
        default:
            notifyDelegates { $0.webSocketDidReceiveEvent(type: type, payload: payload) }
        }
    }
    
    // MARK: - Heartbeat
    
    private func startHeartbeat() {
        stopHeartbeat()
        DispatchQueue.main.async { [weak self] in
            self?.pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
                self?.sendPing()
            }
        }
    }
    
    private func stopHeartbeat() {
        DispatchQueue.main.async { [weak self] in
            self?.pingTimer?.invalidate()
            self?.pingTimer = nil
            self?.pongTimeoutTimer?.invalidate()
            self?.pongTimeoutTimer = nil
        }
    }
    
    func sendPing() {
        // 1. Gửi Native WebSocket Ping (Đây là cái Backend đang mong chờ nhất)
        webSocketTask?.sendPing { error in
            if let error = error {
                print("❌ Lỗi gửi native ping: \(error.localizedDescription)")
            } else {
                print("✅ Đã gửi Native Ping thành công")
            }
        }
        
        // 2. Gửi JSON Ping (Dành cho logic app của bạn nếu có)
        let pingMessage = ["type": "ping"]
        if let data = try? JSONSerialization.data(withJSONObject: pingMessage),
           let jsonString = String(data: data, encoding: .utf8) {
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            webSocketTask?.send(message) { error in
                if let error = error {
                    print("❌ Lỗi gửi JSON ping: \(error.localizedDescription)")
                }
            }
        }
    }
    // MARK: - Disconnection & Reconnect
    
    private func cleanUp(reconnect: Bool) {
        stopHeartbeat()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        isConnected = false
        isConnecting = false
        
        if reconnect && shouldReconnect {
            let delay = min(pow(2.0, Double(reconnectAttempt)), 30.0)
            reconnectAttempt += 1
            print("🔄 WS reconnect in \(Int(delay))s (attempt \(reconnectAttempt))")
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.connect()
            }
        } else {
            reconnectAttempt = 0
        }
    }
    
    private func handleDisconnection(error: Error?) {
        guard isConnected || isConnecting else { return }
        print("⚡ WS disconnected: \(error?.localizedDescription ?? "unknown")")
        notifyDelegates { $0.webSocketDidDisconnect(error: error) }
        cleanUp(reconnect: true)
    }
    
    // MARK: - Sync
    
    private func syncMessagesAfterReconnect() {
        for (roomId, lastId) in localLastMessageIds {
            sendEvent(type: "sync_messages", payload: [
                "room_id": roomId,
                "last_message_id": lastId
            ])
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketService: URLSessionWebSocketDelegate {
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        isConnecting = false
    }
    
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        if closeCode.rawValue == 4001 {
            NetworkManager.shared.refreshAccessToken { [weak self] success in
                if success {
                    self?.cleanUp(reconnect: false)
                    self?.connect()
                } else {
                    TokenManager.shared.clear()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .didLogoutRequired, object: nil)
                    }
                }
            }
        } else {
            handleDisconnection(error: nil)
        }
    }
}
