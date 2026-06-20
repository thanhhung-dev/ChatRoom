import UIKit
import UserNotifications

struct AppNotificationItem: Codable {
  let id: String
  let title: String
  let body: String
  let date: Date
  let type: String
  let targetId: Int?
}

extension Notification.Name {
  static let didReceiveAppNotification = Notification.Name("didReceiveAppNotification")
}

final class AppNotificationService: NSObject {
  static let shared = AppNotificationService()

  private let storageKey = "boxchat.notifications"
  private let center = UNUserNotificationCenter.current()
  private var didConfigure = false

  private override init() {
    super.init()
  }

  func configure() {
    guard !didConfigure else { return }
    didConfigure = true
    center.delegate = self
    requestPermission()
  }

  func requestPermission() {
    center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
  }

  func storedItems() -> [AppNotificationItem] {
    guard let data = UserDefaults.standard.data(forKey: storageKey),
      let decoded = try? JSONDecoder().decode([AppNotificationItem].self, from: data)
    else { return [] }
    return decoded
  }

  func clear() {
    UserDefaults.standard.removeObject(forKey: storageKey)
    UIApplication.shared.applicationIconBadgeNumber = 0
    center.removeAllDeliveredNotifications()
    center.removeAllPendingNotificationRequests()
  }

  func handleWebSocketEvent(type: String, payload: [String: Any]) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in
        self?.handleWebSocketEvent(type: type, payload: payload)
      }
      return
    }
    guard let item = makeItem(type: type, payload: payload) else { return }
    guard save(item) else { return }
    scheduleLocalNotification(item)
    NotificationCenter.default.post(name: .didReceiveAppNotification, object: item)
  }

  private func save(_ item: AppNotificationItem) -> Bool {
    var items = storedItems()
    guard !items.contains(where: { $0.id == item.id }) else { return false }
    items.insert(item, at: 0)
    items = Array(items.prefix(150))
    if let data = try? JSONEncoder().encode(items) {
      UserDefaults.standard.set(data, forKey: storageKey)
    }
    UIApplication.shared.applicationIconBadgeNumber = items.count
    return true
  }

  private func scheduleLocalNotification(_ item: AppNotificationItem) {
    let content = UNMutableNotificationContent()
    content.title = item.title
    content.body = item.body
    content.sound = .default
    content.badge = NSNumber(value: storedItems().count)
    content.userInfo = [
      "type": item.type,
      "target_id": item.targetId ?? -1,
    ]

    let request = UNNotificationRequest(identifier: item.id, content: content, trigger: nil)
    center.add(request)
  }

  private func makeItem(type: String, payload: [String: Any]) -> AppNotificationItem? {
    let supported: Set<String> = [
      "new_message",
      "message_sent",
      "friend_request",
      "friend_accepted",
      "friend_rejected",
      "friend_removed",
      "feed_post",
      "feed_comment",
      "feed_reaction",
      "call_event",
    ]
    guard supported.contains(type) else { return nil }

    let object = payload["message"] as? [String: Any] ?? payload
    if let senderId = object["sender_id"] as? Int,
      senderId == TokenManager.shared.currentUser?.id
    {
      return nil
    }

    let title = titleFor(type: type, object: object)
    let body = bodyFor(type: type, object: object)
    let targetId = object["room_id"] as? Int
      ?? object["post_id"] as? Int
      ?? object["request_id"] as? Int
      ?? object["message_id"] as? Int
    let rawId = object["event_id"] as? String
      ?? object["call_id"] as? String
      ?? "\(object["message_id"] ?? object["post_id"] ?? object["comment_id"] ?? object["request_id"] ?? UUID().uuidString)"
    let id = "boxchat-\(type)-\(rawId)"

    return AppNotificationItem(
      id: id,
      title: title,
      body: body,
      date: Date(),
      type: type,
      targetId: targetId)
  }

  private func titleFor(type: String, object: [String: Any]) -> String {
    object["sender_display_name"] as? String
      ?? object["sender_username"] as? String
      ?? object["actor_display_name"] as? String
      ?? object["actor_username"] as? String
      ?? "BoxChat"
  }

  private func bodyFor(type: String, object: [String: Any]) -> String {
    switch type {
    case "friend_request":
      return "Đã gửi lời mời kết bạn cho bạn"
    case "friend_accepted":
      return "Đã chấp nhận lời mời kết bạn"
    case "friend_rejected":
      return "Đã từ chối lời mời kết bạn"
    case "friend_removed":
      return "Đã xóa kết bạn với bạn"
    case "feed_post":
      return text(object["content"]) ?? text(object["media_name"]) ?? "Đã đăng bài mới"
    case "feed_comment":
      return text(object["content"]) ?? "Đã bình luận bài viết của bạn"
    case "feed_reaction":
      let reaction = text(object["reaction"]) ?? "cảm xúc"
      return "Đã thả \(reaction) vào bài viết của bạn"
    case "call_event":
      let isVideo = object["is_video"] as? Bool ?? false
      let action = object["action"] as? String ?? "call"
      if action == "call_invite" {
        return isVideo ? "Đang gọi video cho bạn" : "Đang gọi thoại cho bạn"
      }
      return "Cập nhật cuộc gọi"
    default:
      return text(object["content"]) ?? text(object["file_name"]) ?? "Tin nhắn mới"
    }
  }

  private func text(_ value: Any?) -> String? {
    guard let text = value as? String,
      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { return nil }
    return text
  }
}

extension AppNotificationService: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}
