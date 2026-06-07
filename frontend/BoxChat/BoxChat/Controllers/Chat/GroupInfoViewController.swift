import UIKit

final class GroupInfoViewController: UIViewController {
  private var room: Room
  private var messages: [Message] = []
  private var notificationsEnabled = true

  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  private let avatarView = UIImageView()
  private let titleLabel = UILabel()
  private let memberLabel = UILabel()
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
    view.backgroundColor = .systemBackground
    navigationItem.title = "Thông tin nhóm"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "chevron.left"),
      style: .plain,
      target: self,
      action: #selector(didTapBack)
    )
    navigationItem.rightBarButtonItem = UIBarButtonItem(
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
      contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -28),
      contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48),
    ])

    contentStack.addArrangedSubview(headerView())
    contentStack.addArrangedSubview(actionsView())

    optionsStack.axis = .vertical
    optionsStack.spacing = 0
    contentStack.addArrangedSubview(optionsStack)
  }

  private func reloadData() {
    messages = ChatLocalStore.shared.loadMessages(roomId: room.id)
    avatarView.image = UIImage(systemName: "person.3.fill")
    if let url = Constants.mediaURL(from: room.avatarUrl) {
      URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
        guard let self, let data, let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.avatarView.image = image }
      }.resume()
    }
    titleLabel.text = room.name
    memberLabel.text = "\(memberCount) thành viên"
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

    avatarView.tintColor = .systemBlue
    avatarView.backgroundColor = .secondarySystemBackground
    avatarView.contentMode = .scaleAspectFill
    avatarView.layer.cornerRadius = 44
    avatarView.layer.cornerCurve = .continuous
    avatarView.clipsToBounds = true

    titleLabel.font = .systemFont(ofSize: 22, weight: .heavy)
    titleLabel.textAlignment = .center

    memberLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    memberLabel.textColor = .secondaryLabel
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
      ("phone.fill", "Gọi nhóm", #selector(didTapStub)),
      ("magnifyingglass", "Tìm kiếm", #selector(didTapSearch)),
      ("plus", "Thêm", #selector(didTapStub)),
      ("bell.fill", "Thông báo", #selector(didTapNotification)),
    ]

    actions.forEach { icon, title, action in
      let button = UIButton(type: .system)
      button.tintColor = .label
      button.addTarget(self, action: action, for: .touchUpInside)

      let iconView = UIImageView(image: UIImage(systemName: icon))
      iconView.tintColor = .label
      iconView.contentMode = .scaleAspectFit
      let label = UILabel()
      label.text = title
      label.font = .systemFont(ofSize: 12, weight: .semibold)
      label.textColor = .secondaryLabel
      label.textAlignment = .center
      let vertical = UIStackView(arrangedSubviews: [iconView, label])
      vertical.axis = .vertical
      vertical.alignment = .center
      vertical.spacing = 8
      vertical.isUserInteractionEnabled = false
      vertical.translatesAutoresizingMaskIntoConstraints = false
      button.addSubview(vertical)
      iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true
      NSLayoutConstraint.activate([
        vertical.topAnchor.constraint(equalTo: button.topAnchor),
        vertical.leadingAnchor.constraint(equalTo: button.leadingAnchor),
        vertical.trailingAnchor.constraint(equalTo: button.trailingAnchor),
        vertical.bottomAnchor.constraint(equalTo: button.bottomAnchor),
      ])
      stack.addArrangedSubview(button)
    }
    stack.heightAnchor.constraint(equalToConstant: 54).isActive = true
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
    addOption(
      icon: "person.2.fill", title: "Thành viên", subtitle: "\(memberCount) thành viên",
      action: #selector(didTapMembers))
    addSeparator()
    addOption(
      icon: "doc.on.doc.fill", title: "Sao chép mã mời",
      subtitle: room.inviteCode.isEmpty ? "Chưa có mã" : room.inviteCode,
      action: #selector(didTapCopyInvite))
    addSeparator()
    addOption(
      icon: notificationsEnabled ? "bell.fill" : "bell.slash.fill", title: "Thông báo",
      subtitle: notificationsEnabled ? "Đang bật" : "Đang tắt",
      action: #selector(didTapNotification))
    addSeparator()
    addOption(
      icon: "rectangle.portrait.and.arrow.right", title: "Rời khỏi nhóm", subtitle: nil,
      destructive: true, action: #selector(didTapLeave))
  }

  private func addOption(
    icon: String, title: String, subtitle: String?, destructive: Bool = false, action: Selector
  ) {
    let row = UIControl()
    row.addTarget(self, action: action, for: .touchUpInside)
    row.heightAnchor.constraint(equalToConstant: 68).isActive = true

    let iconView = UIImageView(image: UIImage(systemName: icon))
    iconView.tintColor = destructive ? .systemRed : .label
    iconView.contentMode = .scaleAspectFit

    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
    titleLabel.textColor = destructive ? .systemRed : .label

    let subtitleLabel = UILabel()
    subtitleLabel.text = subtitle
    subtitleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.isHidden = subtitle == nil

    let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    textStack.axis = .vertical
    textStack.spacing = 3

    let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    chevron.tintColor = .tertiaryLabel

    [iconView, textStack, chevron].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      row.addSubview($0)
    }

    NSLayoutConstraint.activate([
      iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 26),
      iconView.heightAnchor.constraint(equalToConstant: 26),
      textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 18),
      textStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      textStack.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -10),
      chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      chevron.widthAnchor.constraint(equalToConstant: 14),
    ])
    optionsStack.addArrangedSubview(row)
  }

  private func addSeparator() {
    let view = UIView()
    view.backgroundColor = .separator.withAlphaComponent(0.25)
    view.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
    optionsStack.addArrangedSubview(view)
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
    UIPasteboard.general.string = room.inviteCode
    showToast("Đã sao chép mã mời")
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
    showToast("Tính năng giao diện đã sẵn sàng")
  }

  private func showToast(_ message: String) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    present(alert, animated: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
      alert.dismiss(animated: true)
    }
  }
}
