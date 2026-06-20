import UIKit

final class GroupInfoViewController: UIViewController {
  private var room: Room
  private var messages: [Message] = []
  private var notificationsEnabled = true

  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  private let avatarView = BCAvatar(size: 88)
  private let titleLabel = UILabel()
  private let memberLabel = UILabel()

  private let optionsContainer: UIView = {
      let view = UIView()
      view.backgroundColor = BCTheme.Colors.surfaceElevated
      view.layer.cornerRadius = BCTheme.Layout.cornerRadiusL
      BCTheme.Shadow.card(view)
      return view
  }()
  private let optionsStack = UIStackView()

  init(room: Room) {
    self.room = room
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = BCTheme.Colors.background
    navigationItem.title = room.isDirect ? "Thông tin riêng tư" : "Thông tin nhóm"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "chevron.left"),
      style: .plain,
      target: self,
      action: #selector(didTapBack)
    )
    navigationItem.rightBarButtonItem = room.isDirect ? nil : UIBarButtonItem(
      title: "Sửa", style: .done, target: self, action: #selector(didTapEdit))
    setupLayout()
    reloadData()
    fetchRoomDetail()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
    reloadData()
  }

  private func setupLayout() {
    view.addSubview(scrollView)
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    contentStack.axis = .vertical
    contentStack.spacing = 26

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: BCTheme.Layout.paddingL),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -BCTheme.Layout.paddingL),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -28),
      contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -(BCTheme.Layout.paddingL * 2)),
    ])

    contentStack.addArrangedSubview(headerView())
    contentStack.addArrangedSubview(actionsView())

    optionsStack.axis = .vertical
    optionsStack.spacing = 0
    optionsStack.translatesAutoresizingMaskIntoConstraints = false

    optionsContainer.addSubview(optionsStack)
    NSLayoutConstraint.activate([
        optionsStack.topAnchor.constraint(equalTo: optionsContainer.topAnchor, constant: 8),
        optionsStack.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor),
        optionsStack.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor),
        optionsStack.bottomAnchor.constraint(equalTo: optionsContainer.bottomAnchor, constant: -8)
    ])

    contentStack.addArrangedSubview(optionsContainer)
  }

  private func reloadData() {
    messages = ChatLocalStore.shared.loadMessages(roomId: room.id)
    avatarView.configure(name: room.displayName, url: room.displayAvatarURL)

    navigationItem.title = room.isDirect ? "Thông tin riêng tư" : "Thông tin nhóm"
    navigationItem.rightBarButtonItem = room.isDirect ? nil : UIBarButtonItem(
      title: "Sửa", style: .done, target: self, action: #selector(didTapEdit))
    titleLabel.text = room.displayName
    memberLabel.text = room.isDirect ? "Tin nhắn riêng tư" : "\(memberCount) thành viên"
    rebuildOptions()
  }

  private func fetchRoomDetail() {
    NetworkManager.shared.fetchRoom(roomId: room.id) { [weak self] result in
      DispatchQueue.main.async {
        if case .success(let detail) = result {
          self?.room = detail
          self?.reloadData()
        }
      }
    }
  }

  private var memberCount: Int {
    max(room.members?.count ?? room.memberCount, 1)
  }

  private var mediaMessages: [Message] {
    messages.filter { message in
      guard message.messageType == "file" else { return false }
      let name = (message.fileName ?? message.fileUrl ?? "").lowercased()
      return ["jpg", "jpeg", "png", "gif", "heic", "mp4", "mov"].contains {
        name.hasSuffix(".\($0)")
      }
    }
  }

  private var fileMessages: [Message] {
    messages.filter { $0.messageType == "file" && !mediaMessages.contains($0) }
  }

  private var linkMessages: [Message] {
    messages.filter { $0.content.range(of: #"https?://"#, options: .regularExpression) != nil }
  }

  private func headerView() -> UIView {
    let container = UIView()

    titleLabel.font = BCTheme.Typography.title
    titleLabel.textColor = BCTheme.Colors.textPrimary
    titleLabel.textAlignment = .center

    memberLabel.font = BCTheme.Typography.bodyBold
    memberLabel.textColor = BCTheme.Colors.textSecondary
    memberLabel.textAlignment = .center

    let stack = UIStackView(arrangedSubviews: [avatarView, titleLabel, memberLabel])
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(stack)

    NSLayoutConstraint.activate([
      avatarView.widthAnchor.constraint(equalToConstant: 88),
      avatarView.heightAnchor.constraint(equalToConstant: 88),
      stack.topAnchor.constraint(equalTo: container.topAnchor),
      stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
    return container
  }

  private func actionsView() -> UIView {
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.distribution = .fillEqually
    stack.spacing = 16

    let actions: [(String, String, Selector)] = [
      ("phone.fill", room.isDirect ? "Gọi" : "Gọi nhóm", #selector(didTapStub)),
      ("magnifyingglass", "Tìm kiếm", #selector(didTapSearch)),
      ("bell.fill", "Thông báo", #selector(didTapNotification)),
    ]

    actions.forEach { icon, title, action in
      let button = UIButton(type: .system)
      var config = UIButton.Configuration.filled()
      config.image = UIImage(systemName: icon)
      config.imagePlacement = .top
      config.imagePadding = 6
      config.title = title
      config.baseBackgroundColor = BCTheme.Colors.surfaceElevated
      config.baseForegroundColor = BCTheme.Colors.textPrimary
      config.cornerStyle = .medium
      config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
        var outgoing = incoming
        outgoing.font = BCTheme.Typography.captionBold
        return outgoing
      }
      button.configuration = config
      button.addTarget(self, action: action, for: .touchUpInside)

      // Add subtle shadow
      BCTheme.Shadow.card(button)

      stack.addArrangedSubview(button)
    }
    stack.heightAnchor.constraint(equalToConstant: 68).isActive = true
    return stack
  }

  private func rebuildOptions() {
    optionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

    addOption(
      icon: "photo.on.rectangle.angled", title: "Ảnh & video",
      subtitle: "\(mediaMessages.count) mục", action: #selector(didTapMedia))
    addSeparator()
    addOption(
      icon: "doc.fill", title: "File", subtitle: "\(fileMessages.count) file",
      action: #selector(didTapFiles))
    addSeparator()
    addOption(
      icon: "link", title: "Link", subtitle: "\(linkMessages.count) link",
      action: #selector(didTapLinks))
    addSeparator()
    if !room.isDirect {
      addOption(
        icon: "person.2.fill", title: "Thành viên", subtitle: "\(memberCount) thành viên",
        action: #selector(didTapMembers))
      addSeparator()
      addOption(
        icon: "qrcode", title: "Mã QR mời nhóm", subtitle: "Quét để tham gia nhóm",
        action: #selector(didTapInviteQR))
      addSeparator()
      addOption(
        icon: "link.circle.fill", title: "Sao chép link mời",
        subtitle: room.inviteCode.isEmpty ? "Chưa có link" : Constants.inviteLink(code: room.inviteCode),
        action: #selector(didTapCopyInvite))
    }
    addSeparator()
    addOption(
      icon: notificationsEnabled ? "bell.fill" : "bell.slash.fill", title: "Thông báo",
      subtitle: notificationsEnabled ? "Đang bật" : "Đang tắt",
      action: #selector(didTapNotification))
    addSeparator()
    if !room.isDirect {
      addOption(
        icon: "rectangle.portrait.and.arrow.right", title: "Rời khỏi nhóm", subtitle: nil,
        destructive: true, action: #selector(didTapLeave))
    }
  }

  private func addOption(
    icon: String, title: String, subtitle: String?, destructive: Bool = false, action: Selector
  ) {
    let row = UIControl()
    row.addTarget(self, action: action, for: .touchUpInside)
    row.heightAnchor.constraint(equalToConstant: 60).isActive = true

    let iconView = UIImageView(image: UIImage(systemName: icon))
    iconView.tintColor = destructive ? BCTheme.Colors.error : BCTheme.Colors.primary
    iconView.contentMode = .scaleAspectFit

    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = BCTheme.Typography.subheadlineBold
    titleLabel.textColor = destructive ? BCTheme.Colors.error : BCTheme.Colors.textPrimary

    let subtitleLabel = UILabel()
    subtitleLabel.text = subtitle
    subtitleLabel.font = BCTheme.Typography.caption
    subtitleLabel.textColor = BCTheme.Colors.textSecondary
    subtitleLabel.isHidden = subtitle == nil

    let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    textStack.axis = .vertical
    textStack.spacing = 2

    let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    chevron.tintColor = BCTheme.Colors.textTertiary

    [iconView, textStack, chevron].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      row.addSubview($0)
    }

    NSLayoutConstraint.activate([
      iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: BCTheme.Layout.paddingM),
      iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 24),
      iconView.heightAnchor.constraint(equalToConstant: 24),

      textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: BCTheme.Layout.paddingM),
      textStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      textStack.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -10),

      chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -BCTheme.Layout.paddingM),
      chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      chevron.widthAnchor.constraint(equalToConstant: 12),
      chevron.heightAnchor.constraint(equalToConstant: 20)
    ])
    optionsStack.addArrangedSubview(row)
  }

  private func addSeparator() {
    let container = UIView()
    container.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true

    let view = UIView()
    view.backgroundColor = BCTheme.Colors.separatorLight
    view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(view)

    NSLayoutConstraint.activate([
      view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 56), // align with text
      view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      view.topAnchor.constraint(equalTo: container.topAnchor),
      view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
    ])

    optionsStack.addArrangedSubview(container)
  }

  @objc private func didTapEdit() {
    let edit = EditGroupInfoViewController(room: room)
    edit.onSaved = { [weak self] updatedRoom in
      self?.room = updatedRoom
      self?.reloadData()
    }
    navigationController?.pushViewController(edit, animated: true)
  }

  @objc private func didTapBack() {
    navigationController?.popViewController(animated: true)
  }

  @objc private func didTapSearch() {
    navigationController?.pushViewController(
      MessageSearchViewController(room: room, messages: messages), animated: true)
  }

  @objc private func didTapMedia() {
    navigationController?.pushViewController(
      MessageCollectionViewController(title: "Ảnh & video", messages: mediaMessages), animated: true
    )
  }

  @objc private func didTapFiles() {
    navigationController?.pushViewController(
      MessageCollectionViewController(title: "File", messages: fileMessages), animated: true)
  }

  @objc private func didTapLinks() {
    navigationController?.pushViewController(
      MessageCollectionViewController(title: "Link", messages: linkMessages), animated: true)
  }

  @objc private func didTapMembers() {
    navigationController?.pushViewController(GroupMembersViewController(room: room), animated: true)
  }

  @objc private func didTapCopyInvite() {
    UIPasteboard.general.string = Constants.inviteLink(code: room.inviteCode)
    BCToast.show("Đã sao chép link mời", style: .success)
  }

  @objc private func didTapInviteQR() {
    guard !room.inviteCode.isEmpty else {
      BCToast.show("Nhóm này chưa có mã mời", style: .error)
      return
    }
    let link = Constants.inviteLink(code: room.inviteCode)
    let qr = QRCodeViewController(
      payload: link,
      heading: "Mã QR mời nhóm",
      detail: "Người khác quét mã này để tham gia \(room.displayName).")
    navigationController?.pushViewController(qr, animated: true)
  }

  @objc private func didTapNotification() {
    notificationsEnabled.toggle()
    rebuildOptions()
  }

  @objc private func didTapLeave() {
    let alert = UIAlertController(
      title: "Rời khỏi nhóm?", message: "Bạn sẽ không còn thấy phòng này trong danh sách.",
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
    alert.addAction(
      UIAlertAction(title: "Rời nhóm", style: .destructive) { [weak self] _ in
        guard let self else { return }
        NetworkManager.shared.leaveRoom(roomId: self.room.id) { _ in
          DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: true)
          }
        }
      })
    present(alert, animated: true)
  }

  @objc private func didTapStub() {
    BCToast.show("Tính năng gọi đang được phát triển", style: .success)
  }
}
