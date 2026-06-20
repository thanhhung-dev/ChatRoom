import UIKit

final class RoomCell: UITableViewCell {
  static let identifier = "RoomCell"

  private let avatarContainer = UIView()
  private let avatarView = BCAvatar(size: BCTheme.Layout.avatarM)
  private let avatarSecondary = UILabel()

  private let nameLabel = UILabel()
  private let previewLabel = UILabel()
  private let timeLabel = UILabel()
  private let unreadBadge = UILabel()

  private var badgeWidthConstraint: NSLayoutConstraint!

  private static let isoFormatter: ISO8601DateFormatter = {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      return formatter
  }()

  private static let fallbackIsoFormatter: ISO8601DateFormatter = {
      return ISO8601DateFormatter()
  }()

  private static let timeFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm"
      return formatter
  }()

  private static let dayFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "E"
      return formatter
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
    registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (cell: RoomCell, _) in
        cell.updateDynamicLayerColors()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    avatarView.prepareForReuse()
    unreadBadge.isHidden = true
  }

  private func setupViews() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    avatarSecondary.font = BCTheme.Typography.captionBold
    avatarSecondary.textColor = .white
    avatarSecondary.textAlignment = .center
    avatarSecondary.backgroundColor = BCTheme.Colors.accent
    avatarSecondary.layer.cornerRadius = 10
    avatarSecondary.layer.borderWidth = 2
    updateDynamicLayerColors()
    avatarSecondary.clipsToBounds = true

    nameLabel.font = BCTheme.Typography.headline
    nameLabel.textColor = BCTheme.Colors.textPrimary

    previewLabel.font = BCTheme.Typography.body
    previewLabel.textColor = BCTheme.Colors.textSecondary
    previewLabel.lineBreakMode = .byTruncatingTail

    timeLabel.font = BCTheme.Typography.captionBold
    timeLabel.textColor = BCTheme.Colors.textTertiary
    timeLabel.textAlignment = .right

    unreadBadge.backgroundColor = BCTheme.Colors.primary
    unreadBadge.textColor = BCTheme.Colors.textOnPrimary
    unreadBadge.font = BCTheme.Typography.captionBold
    unreadBadge.textAlignment = .center
    unreadBadge.clipsToBounds = true
    unreadBadge.isHidden = true

    [avatarContainer, nameLabel, previewLabel, timeLabel, unreadBadge].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview($0)
    }

    [avatarView, avatarSecondary].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      avatarContainer.addSubview($0)
    }

    badgeWidthConstraint = unreadBadge.widthAnchor.constraint(equalToConstant: 20)

    NSLayoutConstraint.activate([
      avatarContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: BCTheme.Layout.paddingL),
      avatarContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatarContainer.widthAnchor.constraint(equalToConstant: BCTheme.Layout.avatarM),
      avatarContainer.heightAnchor.constraint(equalToConstant: BCTheme.Layout.avatarM),

      avatarView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
      avatarView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
      avatarView.widthAnchor.constraint(equalToConstant: BCTheme.Layout.avatarM),
      avatarView.heightAnchor.constraint(equalToConstant: BCTheme.Layout.avatarM),

      avatarSecondary.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: 4),
      avatarSecondary.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 4),
      avatarSecondary.widthAnchor.constraint(equalToConstant: 20),
      avatarSecondary.heightAnchor.constraint(equalToConstant: 20),

      nameLabel.leadingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: BCTheme.Layout.paddingM),
      nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
      nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

      timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -BCTheme.Layout.paddingL),
      timeLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: 1),
      timeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),

      unreadBadge.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),
      unreadBadge.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 6),
      unreadBadge.heightAnchor.constraint(equalToConstant: 20),
      badgeWidthConstraint,

      previewLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
      previewLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
      previewLabel.trailingAnchor.constraint(equalTo: unreadBadge.leadingAnchor, constant: -8),
      previewLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -14),
    ])
  }

  private func updateDynamicLayerColors() {
    avatarSecondary.layer.borderColor = BCTheme.Colors.surface.cgColor
  }

  func configure(with room: Room) {
    nameLabel.text = room.displayName

    // Configure Avatar using BCAvatar
    let url = Constants.mediaURL(from: room.displayAvatarURL)
    avatarView.configure(name: room.displayName, imageURL: url, showOnline: room.isDirect)
    avatarView.updateTraitColors()

    // Secondary badge for group member count
    avatarSecondary.text = room.isDirect ? "" : (room.memberCount > 2 ? "\(min(room.memberCount, 9))" : "")
    avatarSecondary.isHidden = room.isDirect || room.memberCount <= 2

    // Configure Unread Badge
    if room.unreadCount > 0 {
      let count = room.unreadCount
      let text = count > 9 ? "9+" : "\(count)"
      unreadBadge.text = text

      let badgeWidth: CGFloat = text.count == 1 ? 20 : 28
      badgeWidthConstraint.constant = badgeWidth
      unreadBadge.layer.cornerRadius = 10
      unreadBadge.isHidden = false
    } else {
      unreadBadge.isHidden = true
    }

    // Set initial values from memory
    previewLabel.text = preview(for: room, message: room.lastMessage)
    timeLabel.text = timeText(for: room, rawTime: room.lastMessage?.createdAt ?? room.createdAt)

    // Async fetch from local store to prevent main thread blocking during scroll
    let roomId = room.id
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        guard let localMessage = ChatLocalStore.shared.loadMessages(roomId: roomId).last else { return }

        // If local is newer or we didn't have one
        let currentIso = room.lastMessage?.createdAt ?? ""
        let localIso = localMessage.createdAt

        if localIso > currentIso {
            let pText = self?.preview(for: room, message: localMessage)
            let tText = self?.timeText(for: room, rawTime: localIso)

            DispatchQueue.main.async {
                self?.previewLabel.text = pText
                self?.timeLabel.text = tText
            }
        }
    }
  }

  private func preview(for room: Room, message: Message?) -> String {
    guard let message else {
      return room.description ?? "Hãy bắt đầu cuộc trò chuyện..."
    }
    let prefix = message.userId == TokenManager.shared.currentUser?.id ? "Mình: " : ""
    if message.messageType == "file" {
      return "\(prefix)\(message.fileName ?? "Đã gửi tệp")"
    }
    return "\(prefix)\(message.content)"
  }

  private func timeText(for room: Room, rawTime: String) -> String {
    guard let date = Self.isoFormatter.date(from: rawTime) ?? Self.fallbackIsoFormatter.date(from: rawTime) else { return "" }
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      return Self.timeFormatter.string(from: date)
    }
    if calendar.isDateInYesterday(date) { return "Hôm qua" }
    return Self.dayFormatter.string(from: date)
  }

  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    super.setHighlighted(highlighted, animated: animated)
    UIView.animate(withDuration: 0.15) {
        self.contentView.backgroundColor = highlighted ? BCTheme.Colors.surfaceElevated : .clear
    }
  }
}
