import Foundation

struct APIResponse<T: Codable>: Codable {
    let status: String?
    let message: String?
    let data: T?
    
    var success: Bool {
        return status == "success" || status == "true"
    }
    var error: APIResponse<T>? {
        return status != "success" ? self : nil
    }
}
