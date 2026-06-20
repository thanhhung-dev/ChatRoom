import Foundation

struct Constants {
  enum QRPayload {
    case groupInvite(code: String)
    case friend(username: String)
  }

  static let maxUploadSizeMB = 100
  static let maxUploadSizeBytes = maxUploadSizeMB * 1024 * 1024

  #if targetEnvironment(simulator)
    static let apiBaseURL = "http://127.0.0.1:8000/api/v1"
    static let webSocketURL = "ws://127.0.0.1:8000/ws"
  #else
    static let apiBaseURL = "http://192.168.1.33:8000/api/v1"
    static let webSocketURL = "ws://192.168.1.33:8000/ws"
  #endif

  static func mediaURL(from rawValue: String?) -> URL? {
    guard let rawValue, !rawValue.isEmpty else { return nil }
    if let url = URL(string: rawValue), url.scheme != nil {
      return url
    }
    let base = apiBaseURL.replacingOccurrences(of: "/api/v1", with: "")
    return URL(string: base + rawValue)
  }

  static func inviteLink(code: String) -> String {
    let encoded = code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? code
    return "boxchat://join?code=\(encoded)"
  }

  static func friendLink(username: String) -> String {
    let clean = username.trimmingCharacters(in: .whitespacesAndNewlines)
    let encoded = clean.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? clean
    return "boxchat://friend?username=\(encoded)"
  }

  static func inviteCode(from value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let components = URLComponents(string: trimmed),
      let code = components.queryItems?.first(where: { $0.name == "code" })?.value
    else {
      return trimmed
    }
    return code.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  static func qrPayload(from value: String) -> QRPayload? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    if let data = trimmed.data(using: .utf8),
      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    {
      let type = (object["type"] as? String ?? "").lowercased()
      if type.contains("friend"),
        let username = object["username"] as? String ?? object["user"] as? String
      {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? nil : .friend(username: clean)
      }
      if type.contains("join") || type.contains("group") || type.contains("invite"),
        let code = object["code"] as? String ?? object["invite"] as? String
      {
        let clean = code.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? nil : .groupInvite(code: clean)
      }
    }

    if let components = URLComponents(string: trimmed) {
      let host = components.host?.lowercased() ?? ""
      let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
      let target = "\(host)/\(path)"
      if (components.scheme == "boxchat" || target.contains("join")),
        let code = components.queryItems?.first(where: { $0.name == "code" || $0.name == "invite" })?.value,
        !code.isEmpty
      {
        return .groupInvite(code: code.trimmingCharacters(in: .whitespacesAndNewlines))
      }
      if (components.scheme == "boxchat" || target.contains("friend")),
        let username = components.queryItems?.first(where: { $0.name == "username" || $0.name == "user" })?.value,
        !username.isEmpty
      {
        return .friend(username: username.trimmingCharacters(in: .whitespacesAndNewlines))
      }
      if target.contains("friend") {
        let rawUsername = components.path.split(separator: "/").last.map(String.init)
        let username = (rawUsername?.removingPercentEncoding ?? rawUsername)?
          .trimmingCharacters(in: .whitespacesAndNewlines)
        if let username, !username.isEmpty, username.lowercased() != "friend" {
          return .friend(username: username)
        }
      }
    }

    if trimmed.hasPrefix("@") {
      return .friend(username: String(trimmed.dropFirst()))
    }

    let invite = inviteCode(from: trimmed)
    return invite.isEmpty ? nil : .groupInvite(code: invite)
  }
}
