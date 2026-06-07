import Foundation

// MARK: - APIResponse

struct APIResponse<T: Codable>: Codable {
  let success: Bool
  let data: T?
  let error: String?

  let message: String?

  enum CodingKeys: String, CodingKey {
    case success, data, error, message
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)

    success = try c.decodeIfPresent(Bool.self, forKey: .success) ?? false
    data = try c.decodeIfPresent(T.self, forKey: .data)
    error = try c.decodeIfPresent(String.self, forKey: .error)
    message = try c.decodeIfPresent(String.self, forKey: .message)
  }
}
