import UIKit

final class FeedCommentCell: UITableViewCell {
  static let identifier = "FeedCommentCell"

  private let avatarView = BCAvatar(size: BCTheme.Layout.avatarS)
  private let nameLabel = UILabel()
  private let contentLabel = UILabel()
  private let timeLabel = UILabel()
  private let bubbleView = UIView()

  private static let isoFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
  }()

  private static let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm, dd/MM"
    return f
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  required init?(coder: NSCoder) { fatalError() }

  private func setupUI() {
    selectionStyle = .none
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    bubbleView.backgroundColor = BCTheme.Colors.surfaceElevated
    bubbleView.layer.cornerRadius = 16
    bubbleView.translatesAutoresizingMaskIntoConstraints = false

    nameLabel.font = BCTheme.Typography.headline
    nameLabel.textColor = BCTheme.Colors.textPrimary
    nameLabel.setContentHuggingPriority(.required, for: .vertical)

    contentLabel.font = BCTheme.Typography.body
    contentLabel.textColor = BCTheme.Colors.textSecondary
    contentLabel.numberOfLines = 0

    timeLabel.font = BCTheme.Typography.caption
    timeLabel.textColor = BCTheme.Colors.textTertiary
    timeLabel.setContentHuggingPriority(.required, for: .horizontal)

    let headerStack = UIStackView(arrangedSubviews: [nameLabel, timeLabel])
    headerStack.axis = .horizontal
    headerStack.spacing = BCTheme.Layout.paddingS
    headerStack.alignment = .firstBaseline

    let textStack = UIStackView(arrangedSubviews: [headerStack, contentLabel])
    textStack.axis = .vertical
    textStack.spacing = 4
    textStack.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(avatarView)
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(textStack)

    NSLayoutConstraint.activate([
      avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: BCTheme.Layout.paddingS),
      avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: BCTheme.Layout.paddingM),

      bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: BCTheme.Layout.paddingS),
      bubbleView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: BCTheme.Layout.paddingS),
      bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -BCTheme.Layout.paddingM),
      bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -BCTheme.Layout.paddingS),

      textStack.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
      textStack.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
      textStack.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
      textStack.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
    ])
  }

  func configure(with comment: FeedCommentModel) {
    let name = comment.user.displayName ?? comment.user.username
    nameLabel.text = name
    contentLabel.text = comment.content ?? comment.mediaName ?? "Ảnh"

    if let date = Self.isoFormatter.date(from: comment.createdAt) {
      timeLabel.text = Self.timeFormatter.string(from: date)
    } else {
      timeLabel.text = comment.createdAt
    }

    avatarView.configure(name: name, url: Constants.mediaURL(from: comment.user.avatarUrl)?.absoluteString)
  }
}
