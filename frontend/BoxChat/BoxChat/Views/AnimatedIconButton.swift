import UIKit

enum BoxChatAnimatedIcon {
  case chats
  case friends
  case explore
  case notifications
  case profile
  case camera
  case reaction
  case comment
  case call
  case attachment

  var symbolName: String {
    switch self {
    case .chats: return "message.fill"
    case .friends: return "person.2.fill"
    case .explore: return "sparkles"
    case .notifications: return "bell.badge.fill"
    case .profile: return "person.crop.circle.fill"
    case .camera: return "camera.fill"
    case .reaction: return "face.smiling.fill"
    case .comment: return "bubble.left.and.bubble.right.fill"
    case .call: return "phone.fill"
    case .attachment: return "paperclip.circle.fill"
    }
  }
}

final class AnimatedIconButton: UIButton {
  private let icon: BoxChatAnimatedIcon

  init(icon: BoxChatAnimatedIcon, title: String? = nil) {
    self.icon = icon
    super.init(frame: .zero)
    setImage(UIImage(systemName: icon.symbolName), for: .normal)
    setTitle(title.map { " \($0)" }, for: .normal)
    titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
    addTarget(self, action: #selector(animateTap), for: .touchUpInside)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func animateTap() {
    if #available(iOS 17.0, *) {
      imageView?.addSymbolEffect(.bounce, options: .nonRepeating)
    }
    UIView.animate(withDuration: 0.12, animations: {
      self.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
    }) { _ in
      UIView.animate(withDuration: 0.18) {
        self.transform = .identity
      }
    }
  }
}

extension UIImage {
  static func boxChatIcon(_ icon: BoxChatAnimatedIcon) -> UIImage? {
    UIImage(systemName: icon.symbolName)
  }
}
