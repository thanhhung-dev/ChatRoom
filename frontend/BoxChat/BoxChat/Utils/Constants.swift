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
    static let apiBaseURL = "http://10.220.9.152:8000/api/v1"
    static let webSocketURL = "ws://10.220.9.152:8000/ws"
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
    "boxchat://join?code=\(code)"
  }

  static func friendLink(username: String) -> String {
    "boxchat://friend?username=\(username)"
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

    if let components = URLComponents(string: trimmed) {
      let target = (components.host ?? components.path).lowercased()
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
    }

    if trimmed.hasPrefix("@") {
      return .friend(username: String(trimmed.dropFirst()))
    }

    let invite = inviteCode(from: trimmed)
    return invite.isEmpty ? nil : .groupInvite(code: invite)
  }
}
