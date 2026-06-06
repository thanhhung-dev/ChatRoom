import Foundation

struct Constants {
    
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
}
