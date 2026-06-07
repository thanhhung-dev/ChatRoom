import UIKit

final class RoomAvatarStore {
  static let shared = RoomAvatarStore()

  private let defaults = UserDefaults.standard

  private init() {}

  func saveImage(_ image: UIImage, roomId: Int) {
    guard let data = image.jpegData(compressionQuality: 0.78),
      let url = persist(data: data, fileName: "room_\(roomId).jpg")
    else {
      return
    }
    defaults.set(url.absoluteString, forKey: key(roomId))
  }

  func image(roomId: Int) -> UIImage? {
    guard let raw = defaults.string(forKey: key(roomId)),
      let url = URL(string: raw),
      let data = try? Data(contentsOf: url)
    else {
      return nil
    }
    return UIImage(data: data)
  }

  func imageURL(roomId: Int) -> URL? {
    guard let raw = defaults.string(forKey: key(roomId)) else { return nil }
    return URL(string: raw)
  }

  private func persist(data: Data, fileName: String) -> URL? {
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("BoxChatRoomAvatars", isDirectory: true)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent(fileName)
    do {
      try data.write(to: url, options: [.atomic])
      return url
    } catch {
      return nil
    }
  }

  private func key(_ roomId: Int) -> String {
    "boxchat.room.avatar.\(roomId)"
  }
}
