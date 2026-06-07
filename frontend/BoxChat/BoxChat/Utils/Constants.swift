import Foundation

struct Constants {

  #if targetEnvironment(simulator)
    static let apiBaseURL = "http://127.0.0.1:8000/api/v1"
    static let webSocketURL = "ws://127.0.0.1:8000/ws"

  #else
    static let apiBaseURL = "http://192.168.0.6:8000/api/v1"
    static let webSocketURL = "ws://192.168.0.6:8000/ws"
  #endif

  static func mediaURL(from rawValue: String?) -> URL? {
    guard let rawValue, !rawValue.isEmpty else { return nil }
    if let url = URL(string: rawValue), url.scheme != nil {
      return url
    }
    let base = apiBaseURL.replacingOccurrences(of: "/api/v1", with: "")
    return URL(string: base + rawValue)
  }
}
