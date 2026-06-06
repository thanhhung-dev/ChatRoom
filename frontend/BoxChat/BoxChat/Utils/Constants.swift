import Foundation

struct Constants {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    
    #if targetEnvironment(simulator)
    static let apiBaseURL = "http://127.0.0.1:8000/api/v1"
    static let webSocketURL = "ws://127.0.0.1:8000/ws"
    
    #else
    static let apiBaseURL = "http://127.0.0.1:8000/api/v1"
    static let webSocketURL = "ws://172.25.15.130:8000/ws"
    
    #endif

    static func mediaURL(from path: String?) -> URL? {
        guard let path = path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }
        
        let baseURLString: String
        #if targetEnvironment(simulator)
        baseURLString = "http://127.0.0.1:8000"
        #else
        baseURLString = "http://172.25.15.130:8000"
        #endif
        
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "\(baseURLString)/\(cleanPath)")
    }
=======

  #if targetEnvironment(simulator)
    static let apiBaseURL = "http://127.0.0.1:8000/api/v1"
    static let webSocketURL = "ws://127.0.0.1:8000/ws"
=======

  #if targetEnvironment(simulator)
    static let apiBaseURL = "http://127.0.0.1:8000/api/v1"
    static let webSocketURL = "ws://127.0.0.1:8000/ws"
>>>>>>> Stashed changes
=======

  #if targetEnvironment(simulator)
    static let apiBaseURL = "http://127.0.0.1:8000/api/v1"
    static let webSocketURL = "ws://127.0.0.1:8000/ws"
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
}
