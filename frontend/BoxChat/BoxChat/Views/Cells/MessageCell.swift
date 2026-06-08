import UIKit

final class MessageCell: UITableViewCell {
  static let identifier = "MessageCell"

  private let avatarView = UILabel()
  private let nameLabel = UILabel()
  private let bubbleView = UIView()
  private let stackView = UIStackView()
  private let messageLabel = UILabel()
  private let fileCardView = UIView()
  private let fileIconView = UIImageView()
  private let fileNameLabel = UILabel()
  private let fileMetaLabel = UILabel()
  private let messageImageView = UIImageView()
  private let metaLabel = UILabel()
  private let reactionLabel = UILabel()

  private var leadingConstraint: NSLayoutConstraint!
  private var trailingConstraint: NSLayoutConstraint!
  private var imageHeightConstraint: NSLayoutConstraint!
  private var imageDownloadTask: URLSessionDataTask?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    imageDownloadTask?.cancel()
    imageDownloadTask = nil
    messageImageView.image = nil
    messageImageView.isHidden = true
    fileCardView.isHidden = true
    messageLabel.isHidden = false
    reactionLabel.isHidden = true
  }

  private func setupViews() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    avatarView.font = .systemFont(ofSize: 15, weight: .bold)
    avatarView.textAlignment = .center
    avatarView.textColor = .white
    avatarView.backgroundColor = .systemTeal
    avatarView.layer.cornerRadius = 16
    avatarView.clipsToBounds = true

    nameLabel.font = .systemFont(ofSize: 11, weight: .semibold)
    nameLabel.textColor = .secondaryLabel

    bubbleView.layer.cornerRadius = 18
    bubbleView.layer.cornerCurve = .continuous
    bubbleView.layer.shadowColor = UIColor.black.cgColor
    bubbleView.layer.shadowOpacity = 0.06
    bubbleView.layer.shadowRadius = 7
    bubbleView.layer.shadowOffset = CGSize(width: 0, height: 3)

    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.alignment = .fill

    messageLabel.font = .systemFont(ofSize: 15)
    messageLabel.numberOfLines = 0
    // Cho phép label co lại theo nội dung
    messageLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    messageLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

    messageImageView.contentMode = .scaleAspectFill
    messageImageView.clipsToBounds = true
    messageImageView.layer.cornerRadius = 14
    messageImageView.layer.cornerCurve = .continuous
    messageImageView.backgroundColor = .systemGray5
    messageImageView.isHidden = true

    fileCardView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.10)
    fileCardView.layer.cornerRadius = 14
    fileCardView.isHidden = true

    fileIconView.image = UIImage(systemName: "doc.fill")
    fileIconView.tintColor = .systemBlue
    fileIconView.contentMode = .scaleAspectFit

    fileNameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    fileNameLabel.numberOfLines = 1

    fileMetaLabel.font = .systemFont(ofSize: 11)
    fileMetaLabel.textColor = .secondaryLabel

    metaLabel.font = .systemFont(ofSize: 10, weight: .medium)
    metaLabel.textColor = .tertiaryLabel

    reactionLabel.font = .systemFont(ofSize: 13)
    reactionLabel.textAlignment = .center
    reactionLabel.backgroundColor = .clear
    reactionLabel.layer.shadowOpacity = 0
    reactionLabel.clipsToBounds = true
    reactionLabel.isHidden = true

    [avatarView, nameLabel, bubbleView, metaLabel, reactionLabel].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview($0)
    }

    stackView.translatesAutoresizingMaskIntoConstraints = false
    bubbleView.addSubview(stackView)

    [messageImageView, fileCardView, messageLabel].forEach(stackView.addArrangedSubview)

    [fileIconView, fileNameLabel, fileMetaLabel].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      fileCardView.addSubview($0)
    }

    leadingConstraint = bubbleView.leadingAnchor.constraint(
      equalTo: avatarView.trailingAnchor, constant: 8)
    trailingConstraint = bubbleView.trailingAnchor.constraint(
      equalTo: contentView.trailingAnchor, constant: -14)
    imageHeightConstraint = messageImageView.heightAnchor.constraint(equalToConstant: 170)

    NSLayoutConstraint.activate([
      avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
      avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
      avatarView.widthAnchor.constraint(equalToConstant: 32),
      avatarView.heightAnchor.constraint(equalToConstant: 32),

      nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
      nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
      nameLabel.trailingAnchor.constraint(
        lessThanOrEqualTo: contentView.trailingAnchor, constant: -80),

      bubbleView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
      bubbleView.bottomAnchor.constraint(equalTo: metaLabel.topAnchor, constant: -3),
      // Tối đa 74% chiều rộng màn hình
      bubbleView.widthAnchor.constraint(
        lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.74),
      // Tối thiểu đủ chứa nội dung — bubble co sát theo text
      bubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: 48),

      stackView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
      stackView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
      stackView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
      stackView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),

      messageImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 230),

      fileCardView.heightAnchor.constraint(equalToConstant: 58),
      fileIconView.leadingAnchor.constraint(equalTo: fileCardView.leadingAnchor, constant: 12),
      fileIconView.centerYAnchor.constraint(equalTo: fileCardView.centerYAnchor),
      fileIconView.widthAnchor.constraint(equalToConstant: 26),
      fileIconView.heightAnchor.constraint(equalToConstant: 26),

      fileNameLabel.leadingAnchor.constraint(equalTo: fileIconView.trailingAnchor, constant: 10),
      fileNameLabel.trailingAnchor.constraint(equalTo: fileCardView.trailingAnchor, constant: -12),
      fileNameLabel.topAnchor.constraint(equalTo: fileCardView.topAnchor, constant: 11),

      fileMetaLabel.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
      fileMetaLabel.trailingAnchor.constraint(equalTo: fileNameLabel.trailingAnchor),
      fileMetaLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 3),

      metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7),
      metaLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -4),

      reactionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 30),
      reactionLabel.heightAnchor.constraint(equalToConstant: 24),
      reactionLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 6),
      reactionLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 8),
    ])
  }

  func configure(with message: Message, isMe: Bool, reaction: String?, localImage: UIImage?) {
    nameLabel.text = isMe ? "" : (message.displayName ?? message.username ?? "Member")
    nameLabel.isHidden = isMe
    avatarView.isHidden = isMe
    avatarView.text = initials(from: message.displayName ?? message.username ?? "?")

    leadingConstraint.isActive = !isMe
    trailingConstraint.isActive = isMe

    bubbleView.backgroundColor = isMe ? .systemBlue : .secondarySystemGroupedBackground
    messageLabel.textColor = isMe ? .white : .label
    fileNameLabel.textColor = isMe ? .white : .label
    fileMetaLabel.textColor = isMe ? UIColor.white.withAlphaComponent(0.78) : .secondaryLabel

    messageLabel.text = message.content
    messageLabel.isHidden = message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

    configureAttachment(message: message, localImage: localImage)
    if isMediaOnly(message: message, localImage: localImage) {
      bubbleView.backgroundColor = .clear
    }
    metaLabel.text =
      "\(shortTime(from: message.createdAt)) \(statusGlyph(for: message.status, isMe: isMe))"
    reactionLabel.text = reaction
    reactionLabel.isHidden = reaction == nil
  }

  private func configureAttachment(message: Message, localImage: UIImage?) {
    fileCardView.isHidden = true
    messageImageView.isHidden = true
    imageHeightConstraint.isActive = false

    if let localImage {
      messageImageView.image = localImage
      messageImageView.isHidden = false
      imageHeightConstraint.constant = 190
      imageHeightConstraint.isActive = true
      return
    }

    let lowerUrl = message.fileUrl?.lowercased() ?? ""
    let lowerName = message.fileName?.lowercased() ?? ""
    let isImage = ["jpg", "jpeg", "png", "gif", "heic"].contains { ext in
      lowerUrl.hasSuffix(".\(ext)") || lowerName.hasSuffix(".\(ext)")
    }

    if isImage, let url = Constants.mediaURL(from: message.fileUrl) {
      messageImageView.isHidden = false
      imageHeightConstraint.constant = 190
      imageHeightConstraint.isActive = true
      if url.isFileURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
        messageImageView.image = image
        return
      }
      imageDownloadTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
        guard let self, let data, let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.messageImageView.image = image }
      }
      imageDownloadTask?.resume()
      return
    }

    if message.messageType == "file" || message.fileName != nil {
      fileCardView.isHidden = false
      fileNameLabel.text = message.fileName ?? "Tệp đính kèm"
      fileMetaLabel.text = "Tệp đã chọn"
    }
  }

  private func isMediaOnly(message: Message, localImage: UIImage?) -> Bool {
    let hasImage = localImage != nil || message.fileUrl != nil
    let hasText = !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    return hasImage && !hasText
  }

  private func initials(from name: String) -> String {
    let parts = name.split(separator: " ")
    let value = parts.prefix(2).compactMap { $0.first }.map(String.init).joined()
    return value.isEmpty ? "?" : value.uppercased()
  }

  private func shortTime(from isoString: String) -> String {
    let formatter = ISO8601DateFormatter()
    guard let date = formatter.date(from: isoString) else { return "" }
    let out = DateFormatter()
    out.dateFormat = "HH:mm"
    return out.string(from: date)
  }

  private func statusGlyph(for status: String, isMe: Bool) -> String {
    guard isMe else { return "" }
    switch status {
    case "read": return "✓✓"
    case "delivered", "sent": return "✓"
    case "sending": return "..."
    case "local": return "✓"
    default: return ""
    }
  }
}
