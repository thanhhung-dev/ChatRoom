import UIKit

final class MessageCell: UITableViewCell {
  static let identifier = "MessageCell"

  private let avatarView = BCAvatar(size: 32)
  private let nameLabel = UILabel()
  private let bubbleView = UIView()
  private let stackView = UIStackView()
  private let messageLabel = UILabel()
  private let fileCardView = UIView()
  private let fileIconView = UIImageView()
  private let fileNameLabel = UILabel()
  private let fileMetaLabel = UILabel()
  private let messageImageView = UIImageView()

  private let metaStack = UIStackView()
  private let timeLabel = UILabel()
  private let statusImageView = UIImageView()

  private let reactionLabel = UILabel()

  private var leadingConstraint: NSLayoutConstraint!
  private var trailingConstraint: NSLayoutConstraint!
  private var imageHeightConstraint: NSLayoutConstraint!
  private var imageWidthConstraint: NSLayoutConstraint!

  private var imageLoadTask: URLSessionDataTask?

  private static let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let fallbackIsoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    return formatter
  }()

  private static let timeFormatter: DateFormatter = {
    let out = DateFormatter()
    out.dateFormat = "HH:mm"
    return out
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
    registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (cell: MessageCell, _) in
        cell.updateDynamicLayerColors()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    imageLoadTask?.cancel()
    imageLoadTask = nil
    messageImageView.image = nil
    messageImageView.isHidden = true
    fileCardView.isHidden = true
    messageLabel.isHidden = false
    reactionLabel.isHidden = true
    avatarView.prepareForReuse()
  }

  private func setupViews() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    nameLabel.font = BCTheme.Typography.captionBold
    nameLabel.textColor = BCTheme.Colors.textSecondary

    bubbleView.bcCornerRadius(18)
    updateDynamicLayerColors()
    bubbleView.layer.shadowOpacity = 0.06
    bubbleView.layer.shadowRadius = 7
    bubbleView.layer.shadowOffset = CGSize(width: 0, height: 3)

    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.alignment = .fill

    messageLabel.font = BCTheme.Typography.body
    messageLabel.numberOfLines = 0
    messageLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    messageLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

    messageImageView.contentMode = .scaleAspectFill
    messageImageView.clipsToBounds = true
    messageImageView.bcCornerRadius(14)
    messageImageView.backgroundColor = BCTheme.Colors.surfaceElevated
    messageImageView.isHidden = true

    fileCardView.layer.cornerRadius = 14
    fileCardView.isHidden = true

    fileIconView.image = UIImage(systemName: "doc.fill")
    fileIconView.contentMode = .scaleAspectFit

    fileNameLabel.font = BCTheme.Typography.calloutBold
    fileNameLabel.numberOfLines = 1

    fileMetaLabel.font = BCTheme.Typography.caption
    fileMetaLabel.textColor = BCTheme.Colors.textSecondary

    metaStack.axis = .horizontal
    metaStack.spacing = 4
    metaStack.alignment = .center

    timeLabel.font = BCTheme.Typography.micro
    timeLabel.textColor = BCTheme.Colors.textTertiary

    statusImageView.contentMode = .scaleAspectFit
    statusImageView.tintColor = BCTheme.Colors.textTertiary

    metaStack.addArrangedSubview(timeLabel)
    metaStack.addArrangedSubview(statusImageView)

    reactionLabel.font = BCTheme.Typography.subheadline
    reactionLabel.textAlignment = .center
    reactionLabel.backgroundColor = .clear
    reactionLabel.layer.shadowOpacity = 0
    reactionLabel.clipsToBounds = true
    reactionLabel.isHidden = true

    [avatarView, nameLabel, bubbleView, metaStack, reactionLabel].forEach {
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

    leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8)
    trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14)
    imageHeightConstraint = messageImageView.heightAnchor.constraint(equalToConstant: 170)
    imageWidthConstraint = messageImageView.widthAnchor.constraint(equalToConstant: 230)

    NSLayoutConstraint.activate([
      avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
      avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),

      nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
      nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
      nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -80),

      bubbleView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
      bubbleView.bottomAnchor.constraint(equalTo: metaStack.topAnchor, constant: -3),
      bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: BCTheme.Layout.maxBubbleWidthRatio),
      bubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: 48),

      stackView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
      stackView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
      stackView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
      stackView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),

      imageWidthConstraint,

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

      metaStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7),
      metaStack.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -4),
      statusImageView.widthAnchor.constraint(equalToConstant: 12),
      statusImageView.heightAnchor.constraint(equalToConstant: 12),

      reactionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 30),
      reactionLabel.heightAnchor.constraint(equalToConstant: 24),
      reactionLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 6),
      reactionLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 8),
    ])
  }

  private func updateDynamicLayerColors() {
    BCTheme.Shadow.updateShadowColor(bubbleView, color: UIColor.label.withAlphaComponent(0.14))
  }

  func configure(with message: Message, isMe: Bool, reaction: String?, localImage: UIImage?) {
    let senderName = message.displayName ?? message.username ?? "Member"
    nameLabel.text = isMe ? "" : senderName
    nameLabel.isHidden = isMe
    avatarView.isHidden = isMe
    avatarView.configure(name: senderName)

    leadingConstraint.isActive = !isMe
    trailingConstraint.isActive = isMe

    let senderColor = BCTheme.Colors.avatarColor(for: senderName)
    bubbleView.backgroundColor = isMe ? BCTheme.Colors.bubbleOutgoing : BCTheme.Colors.bubbleIncoming
    nameLabel.textColor = senderColor
    messageLabel.textColor = isMe ? BCTheme.Colors.bubbleTextOutgoing : BCTheme.Colors.bubbleTextIncoming
    fileNameLabel.textColor = messageLabel.textColor
    fileMetaLabel.textColor = isMe ? UIColor.white.withAlphaComponent(0.78) : BCTheme.Colors.textSecondary

    fileCardView.backgroundColor = isMe ? UIColor.white.withAlphaComponent(0.2) : BCTheme.Colors.primary.withAlphaComponent(0.1)
    fileIconView.tintColor = isMe ? .white : BCTheme.Colors.primary

    messageLabel.text = message.content
    messageLabel.isHidden = message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

    configureAttachment(message: message, localImage: localImage)
    if isMediaOnly(message: message, localImage: localImage) {
      bubbleView.backgroundColor = .clear
    }

    timeLabel.text = shortTime(from: message.createdAt)
    configureStatus(for: message.status, isMe: isMe)

    reactionLabel.text = reaction
    reactionLabel.isHidden = reaction == nil
  }

  private func configureStatus(for status: String, isMe: Bool) {
      guard isMe else {
          statusImageView.isHidden = true
          return
      }
      statusImageView.isHidden = false
      statusImageView.tintColor = BCTheme.Colors.textTertiary

      switch status {
      case "read":
          statusImageView.image = UIImage(systemName: "checkmark.circle.fill")
          statusImageView.tintColor = BCTheme.Colors.primary
      case "delivered", "sent":
          statusImageView.image = UIImage(systemName: "checkmark")
      case "sending":
          statusImageView.image = UIImage(systemName: "arrow.up.circle")
      case "local":
          statusImageView.image = UIImage(systemName: "checkmark")
      default:
          statusImageView.isHidden = true
      }
  }

  private func configureAttachment(message: Message, localImage: UIImage?) {
    fileCardView.isHidden = true
    messageImageView.isHidden = true
    imageHeightConstraint.isActive = false
    imageWidthConstraint.isActive = false

    if let localImage {
      messageImageView.image = localImage
      messageImageView.isHidden = false
      applyImageSize(localImage)
      return
    }

    let lowerUrl = message.fileUrl?.lowercased() ?? ""
    let lowerName = message.fileName?.lowercased() ?? ""
    let isImage = ["jpg", "jpeg", "png", "gif", "heic"].contains { ext in
      lowerUrl.hasSuffix(".\(ext)") || lowerName.hasSuffix(".\(ext)")
    }
    let isVideo = ["mp4", "mov", "m4v"].contains { ext in
      lowerUrl.hasSuffix(".\(ext)") || lowerName.hasSuffix(".\(ext)")
    }
    let isAudio = ["m4a", "aac", "mp3", "wav"].contains { ext in
      lowerUrl.hasSuffix(".\(ext)") || lowerName.hasSuffix(".\(ext)")
    }

    if isImage, let url = Constants.mediaURL(from: message.fileUrl) {
      messageImageView.isHidden = false
      if url.isFileURL {
        DispatchQueue.global(qos: .userInitiated).async {
          if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            DispatchQueue.main.async { [weak self] in
              self?.messageImageView.image = image
              self?.applyImageSize(image)
            }
          }
        }
        return
      }

      imageLoadTask = ImageCache.shared.load(from: url) { [weak self] image in
          guard let self, let image else { return }
          UIView.transition(with: self.messageImageView, duration: 0.2, options: .transitionCrossDissolve) {
              self.messageImageView.image = image
          }
          self.applyImageSize(image)
      }
      return
    }

    if message.messageType == "file" || message.fileName != nil {
      fileCardView.isHidden = false
      fileIconView.image = UIImage(systemName: isVideo ? "play.rectangle.fill" : (isAudio ? "waveform" : "doc.text.fill"))
      fileNameLabel.text = message.fileName ?? "Tệp đính kèm"
      fileMetaLabel.text = isVideo ? "Video" : (isAudio ? "Tin nhắn thoại" : "Tệp đã chọn")
    }
  }

  private func applyImageSize(_ image: UIImage) {
    let maxWidth: CGFloat = 250
    let minHeight: CGFloat = 150
    let maxHeight: CGFloat = 360
    let ratio = image.size.height / max(image.size.width, 1)
    let width = image.size.width > image.size.height ? maxWidth : min(maxWidth, 220)
    let height = min(maxHeight, max(minHeight, width * ratio))
    imageWidthConstraint.constant = width
    imageHeightConstraint.constant = height
    imageWidthConstraint.isActive = true
    imageHeightConstraint.isActive = true
  }

  private func isMediaOnly(message: Message, localImage: UIImage?) -> Bool {
    let hasImage = localImage != nil || message.fileUrl != nil
    let hasText = !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    return hasImage && !hasText
  }

  private func shortTime(from isoString: String) -> String {
    guard let date = Self.isoFormatter.date(from: isoString) ?? Self.fallbackIsoFormatter.date(from: isoString) else { return "" }
    return Self.timeFormatter.string(from: date)
  }
}
