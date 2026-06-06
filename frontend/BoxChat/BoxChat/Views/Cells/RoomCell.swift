import UIKit

final class RoomCell: UITableViewCell {
  static let identifier = "RoomCell"

  private let avatarContainer = UIView()
  private let avatarImageView = UIImageView()
  private let avatarPrimary = UILabel()
  private let avatarSecondary = UILabel()
  private let nameLabel = UILabel()
  private let previewLabel = UILabel()
  private let timeLabel = UILabel()
  private let unreadBadge = UILabel()
  private let onlineDot = UIView()
  private var avatarTask: URLSessionDataTask?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    avatarTask?.cancel()
    avatarTask = nil
    avatarImageView.image = nil
    avatarImageView.isHidden = true
  }

  private func setupViews() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    avatarPrimary.font = .systemFont(ofSize: 17, weight: .bold)
    avatarPrimary.textColor = .white
    avatarPrimary.textAlignment = .center
    avatarPrimary.backgroundColor = .systemBlue
    avatarPrimary.layer.cornerRadius = 25
    avatarPrimary.clipsToBounds = true

    avatarImageView.contentMode = .scaleAspectFill
    avatarImageView.layer.cornerRadius = 25
    avatarImageView.clipsToBounds = true
    avatarImageView.isHidden = true

    avatarSecondary.font = .systemFont(ofSize: 12, weight: .bold)
    avatarSecondary.textColor = .white
    avatarSecondary.textAlignment = .center
    avatarSecondary.backgroundColor = .systemTeal
    avatarSecondary.layer.cornerRadius = 16
    avatarSecondary.layer.borderWidth = 2
    avatarSecondary.layer.borderColor = UIColor.systemBackground.cgColor
    avatarSecondary.clipsToBounds = true

    nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
    nameLabel.textColor = .label

    previewLabel.font = .systemFont(ofSize: 14, weight: .medium)
    previewLabel.textColor = .secondaryLabel
    previewLabel.lineBreakMode = .byTruncatingTail

    timeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
    timeLabel.textColor = .secondaryLabel
    timeLabel.textAlignment = .right

    unreadBadge.backgroundColor = .systemBlue
    unreadBadge.textColor = .white
    unreadBadge.font = .systemFont(ofSize: 11, weight: .bold)
    unreadBadge.textAlignment = .center
    unreadBadge.layer.cornerRadius = 10
    unreadBadge.clipsToBounds = true

    onlineDot.backgroundColor = .systemGreen
    onlineDot.layer.cornerRadius = 5
    onlineDot.layer.borderWidth = 2
    onlineDot.layer.borderColor = UIColor.systemBackground.cgColor

    [avatarContainer, nameLabel, previewLabel, timeLabel, unreadBadge].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview($0)
    }

    [avatarPrimary, avatarImageView, avatarSecondary, onlineDot].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      avatarContainer.addSubview($0)
    }

    NSLayoutConstraint.activate([
      avatarContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      avatarContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatarContainer.widthAnchor.constraint(equalToConstant: 58),
      avatarContainer.heightAnchor.constraint(equalToConstant: 58),

      avatarPrimary.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
      avatarPrimary.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
      avatarPrimary.widthAnchor.constraint(equalToConstant: 50),
      avatarPrimary.heightAnchor.constraint(equalToConstant: 50),

      avatarImageView.leadingAnchor.constraint(equalTo: avatarPrimary.leadingAnchor),
      avatarImageView.topAnchor.constraint(equalTo: avatarPrimary.topAnchor),
      avatarImageView.widthAnchor.constraint(equalTo: avatarPrimary.widthAnchor),
      avatarImageView.heightAnchor.constraint(equalTo: avatarPrimary.heightAnchor),

      avatarSecondary.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
      avatarSecondary.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
      avatarSecondary.widthAnchor.constraint(equalToConstant: 32),
      avatarSecondary.heightAnchor.constraint(equalToConstant: 32),

      onlineDot.trailingAnchor.constraint(equalTo: avatarPrimary.trailingAnchor, constant: -2),
      onlineDot.bottomAnchor.constraint(equalTo: avatarPrimary.bottomAnchor, constant: -2),
      onlineDot.widthAnchor.constraint(equalToConstant: 10),
      onlineDot.heightAnchor.constraint(equalToConstant: 10),

      nameLabel.leadingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: 12),
      nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
      nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

      previewLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
      previewLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
      previewLabel.trailingAnchor.constraint(equalTo: unreadBadge.leadingAnchor, constant: -8),
      previewLabel.bottomAnchor.constraint(
        lessThanOrEqualTo: contentView.bottomAnchor, constant: -14),

      timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      timeLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: 1),
      timeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 52),

      unreadBadge.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),
      unreadBadge.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
      unreadBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
      unreadBadge.heightAnchor.constraint(equalToConstant: 20),
    ])
  }

  func configure(with room: Room) {
    nameLabel.text = room.name
    previewLabel.text = preview(for: room)
    timeLabel.text = timeText(for: room)

    if let url = Constants.mediaURL(from: room.avatarUrl) {
      avatarImageView.isHidden = false
      avatarPrimary.text = ""
      avatarTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
        guard let self, let data, let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.avatarImageView.image = image }
      }
      avatarTask?.resume()
    } else {
      avatarImageView.isHidden = true
      avatarImageView.image = nil
      avatarPrimary.backgroundColor = .systemBlue
      avatarPrimary.text = initials(room.name)
    }
    avatarSecondary.text = room.memberCount > 1 ? "\(min(room.memberCount, 9))" : ""
    avatarSecondary.isHidden = room.memberCount <= 1
    onlineDot.isHidden = room.memberCount != 1

    if room.unreadCount > 0 {
      unreadBadge.text = "\(room.unreadCount)"
      unreadBadge.isHidden = false
    } else {
      unreadBadge.isHidden = true
    }
  }

  private func preview(for room: Room) -> String {
    let local = ChatLocalStore.shared.loadMessages(roomId: room.id).last
    let message = local ?? room.lastMessage
    guard let message else {
      return room.description ?? "Hãy bắt đầu cuộc trò chuyện..."
    }
    let prefix = message.userId == TokenManager.shared.currentUser?.id ? "Mình: " : ""
    if message.messageType == "file" {
      return "\(prefix)\(message.fileName ?? "Đã gửi tệp")"
    }
    return "\(prefix)\(message.content)"
  }

  private func timeText(for room: Room) -> String {
    let local = ChatLocalStore.shared.loadMessages(roomId: room.id).last
    let raw = local?.createdAt ?? room.lastMessage?.createdAt ?? room.createdAt
    let iso = ISO8601DateFormatter()
    guard let date = iso.date(from: raw) else { return "" }
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm"
      return formatter.string(from: date)
    }
    if calendar.isDateInYesterday(date) {
      return "Hôm qua"
    }
    let formatter = DateFormatter()
    formatter.dateFormat = "E"
    return formatter.string(from: date)
  }

  private func initials(_ value: String) -> String {
    let parts = value.split(separator: " ")
    let text = parts.prefix(2).compactMap { $0.first }.map(String.init).joined()
    return text.isEmpty ? "B" : text.uppercased()
  }
}
