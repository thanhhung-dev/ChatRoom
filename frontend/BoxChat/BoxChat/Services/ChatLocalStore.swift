import Foundation

final class ChatLocalStore {
  static let shared = ChatLocalStore()

  private let defaults = UserDefaults.standard
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  private init() {}

  func loadMessages(roomId: Int) -> [Message] {
    guard let data = defaults.data(forKey: messagesKey(roomId)),
      let messages = try? decoder.decode([Message].self, from: data)
    else {
      return []
    }
    return messages
  }

  func saveMessages(_ messages: [Message], roomId: Int) {
    guard let data = try? encoder.encode(messages) else { return }
    defaults.set(data, forKey: messagesKey(roomId))
  }

  func loadReactions(roomId: Int) -> [Int: String] {
    guard let data = defaults.data(forKey: reactionsKey(roomId)),
      let reactions = try? decoder.decode([Int: String].self, from: data)
    else {
      return [:]
    }
    return reactions
  }

  func saveReactions(_ reactions: [Int: String], roomId: Int) {
    guard let data = try? encoder.encode(reactions) else { return }
    defaults.set(data, forKey: reactionsKey(roomId))
  }

  func persistAttachment(_ data: Data, fileName: String) -> URL? {
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("BoxChatAttachments", isDirectory: true)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let safeName = fileName.replacingOccurrences(of: "/", with: "_")
    let url = directory.appendingPathComponent(safeName)
    do {
      try data.write(to: url, options: [.atomic])
      return url
    } catch {
      return nil
    }
  }

  private func messagesKey(_ roomId: Int) -> String {
    "boxchat.local.messages.\(roomId)"
  }

  private func reactionsKey(_ roomId: Int) -> String {
    "boxchat.local.reactions.\(roomId)"
  }
}
