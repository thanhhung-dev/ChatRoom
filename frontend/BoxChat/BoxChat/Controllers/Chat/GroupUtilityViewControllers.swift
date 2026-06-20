import AVKit
import QuickLook
import UIKit

// MARK: - EditGroupInfoViewController
final class EditGroupInfoViewController: UIViewController {
  var onSaved: ((Room) -> Void)?

  private var room: Room
  private var selectedAvatar: UIImage?

  private let avatarButton = UIButton(type: .system)
  private let avatarView = BCAvatar(size: 112)

  private let nameField = BCTextField(title: "Tên nhóm", placeholder: "Nhập tên nhóm", isSecure: false)
  private let descriptionField = BCTextField(title: "Mô tả nhóm", placeholder: "Nhập mô tả", isSecure: false)

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
    title = "Sửa thông tin"
    installGroupBackButton()
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Lưu", style: .done, target: self, action: #selector(didTapSave))
    setupLayout()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }

  private func setupLayout() {
    avatarView.configure(name: room.displayName, url: room.avatarUrl)
    avatarView.isUserInteractionEnabled = false
    avatarView.translatesAutoresizingMaskIntoConstraints = false

    avatarButton.addSubview(avatarView)
    avatarButton.addTarget(self, action: #selector(didTapAvatar), for: .touchUpInside)

    let cameraContainer = UIView()
    cameraContainer.backgroundColor = BCTheme.Colors.surface
    cameraContainer.layer.cornerRadius = 16
    cameraContainer.layer.borderWidth = 2
    cameraContainer.layer.borderColor = BCTheme.Colors.background.cgColor
    cameraContainer.translatesAutoresizingMaskIntoConstraints = false

    let camera = UIImageView(image: UIImage(systemName: "camera.fill"))
    camera.tintColor = BCTheme.Colors.primary
    camera.contentMode = .center
    camera.translatesAutoresizingMaskIntoConstraints = false

    cameraContainer.addSubview(camera)
    avatarButton.addSubview(cameraContainer)

    nameField.textField.text = room.name
    descriptionField.textField.text = room.description

    let stack = UIStackView(arrangedSubviews: [
      avatarButton,
      nameField,
      descriptionField,
    ])
    stack.axis = .vertical
    stack.spacing = 24
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: BCTheme.Layout.paddingL),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -BCTheme.Layout.paddingL),

      avatarButton.heightAnchor.constraint(equalToConstant: 120),
      avatarView.centerXAnchor.constraint(equalTo: avatarButton.centerXAnchor),
      avatarView.topAnchor.constraint(equalTo: avatarButton.topAnchor),
      avatarView.widthAnchor.constraint(equalToConstant: 112),
      avatarView.heightAnchor.constraint(equalToConstant: 112),

      cameraContainer.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 4),
      cameraContainer.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: -4),
      cameraContainer.widthAnchor.constraint(equalToConstant: 32),
      cameraContainer.heightAnchor.constraint(equalToConstant: 32),

      camera.centerXAnchor.constraint(equalTo: cameraContainer.centerXAnchor),
      camera.centerYAnchor.constraint(equalTo: cameraContainer.centerYAnchor)
    ])
  }

  @objc private func didTapAvatar() {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = .photoLibrary
    picker.allowsEditing = true
    present(picker, animated: true)
  }

  @objc private func didTapSave() {
    let name = nameField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    let description = descriptionField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    navigationItem.rightBarButtonItem?.isEnabled = false

    NetworkManager.shared.updateRoom(roomId: room.id, name: name, description: description) { [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        switch result {
        case .success(let updated):
          if let selectedAvatar = self.selectedAvatar,
            let data = selectedAvatar.jpegData(compressionQuality: 0.78)
          {
            NetworkManager.shared.uploadRoomAvatar(roomId: updated.id, imageData: data) { [weak self] avatarResult in
              DispatchQueue.main.async {
                guard let self else { return }
                if case .success(let avatarRoom) = avatarResult {
                  self.onSaved?(avatarRoom)
                } else {
                  self.onSaved?(updated)
                }
                self.navigationController?.popViewController(animated: true)
              }
            }
            return
          }
          self.onSaved?(updated)
          self.navigationController?.popViewController(animated: true)
        case .failure(let error):
          BCToast.show(error.localizedDescription, style: .error)
        }
      }
    }
  }
}

extension EditGroupInfoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)
    let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
    selectedAvatar = image
    // For local preview, we can just use an internal UIImageView on top or let BCAvatar be bypassed
    // For simplicity, we just set the avatarView to bypass url loading
    if let img = image {
        // HACK: just overlay an imageview since BCAvatar is URL based
        let overlay = UIImageView(image: img)
        overlay.contentMode = .scaleAspectFill
        overlay.layer.cornerRadius = 56
        overlay.clipsToBounds = true
        overlay.frame = avatarView.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        avatarView.addSubview(overlay)
    }
  }
}

// MARK: - MessageSearchViewController
final class MessageSearchViewController: UIViewController {
  private let room: Room
  private let sourceMessages: [Message]
  private var filtered: [Message] = []
  private let searchBar = UISearchBar()
  private let tableView = UITableView(frame: .zero, style: .plain)

  init(room: Room, messages: [Message]) {
    self.room = room
    self.sourceMessages = messages
    self.filtered = messages
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = BCTheme.Colors.background
    title = "Tìm kiếm"
    installGroupBackButton()

    searchBar.placeholder = "Tìm trong \(room.displayName)"
    searchBar.delegate = self
    searchBar.searchBarStyle = .minimal
    installTapToDismissKeyboard()

    tableView.dataSource = self
    tableView.keyboardDismissMode = .interactive
    tableView.register(MessageSearchCell.self, forCellReuseIdentifier: MessageSearchCell.identifier)
    tableView.backgroundColor = .clear
    tableView.separatorColor = BCTheme.Colors.separatorLight

    [searchBar, tableView].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview($0)
    }

    NSLayoutConstraint.activate([
      searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
      searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
      tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }
}

extension MessageSearchViewController: UISearchBarDelegate, UITableViewDataSource {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    filtered =
      query.isEmpty
      ? sourceMessages : sourceMessages.filter { $0.content.lowercased().contains(query) }
    tableView.reloadData()
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    filtered.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: MessageSearchCell.identifier, for: indexPath) as! MessageSearchCell
    let message = filtered[indexPath.row]
    let query = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    cell.configure(message: message, query: query)
    return cell
  }
}

private final class MessageSearchCell: UITableViewCell {
    static let identifier = "MessageSearchCell"
    private let nameLabel = UILabel()
    private let contentLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = BCTheme.Colors.surface

        nameLabel.font = BCTheme.Typography.captionBold
        nameLabel.textColor = BCTheme.Colors.textSecondary

        contentLabel.font = BCTheme.Typography.body
        contentLabel.textColor = BCTheme.Colors.textPrimary
        contentLabel.numberOfLines = 2

        timeLabel.font = BCTheme.Typography.caption
        timeLabel.textColor = BCTheme.Colors.textTertiary

        let headerStack = UIStackView(arrangedSubviews: [nameLabel, UIView(), timeLabel])
        headerStack.axis = .horizontal

        let stack = UIStackView(arrangedSubviews: [headerStack, contentLabel])
        stack.axis = .vertical
        stack.spacing = 4

        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: BCTheme.Layout.paddingL),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -BCTheme.Layout.paddingL),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: BCTheme.Layout.paddingM),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -BCTheme.Layout.paddingM)
        ])
    }

    func configure(message: Message, query: String) {
        nameLabel.text = message.displayName ?? message.username ?? "Ẩn danh"
        timeLabel.text = message.createdAt

        let fullText = message.content.isEmpty ? (message.fileName ?? "Tin nhắn") : message.content

        if !query.isEmpty, let range = fullText.lowercased().range(of: query.lowercased()) {
            let nsRange = NSRange(range, in: fullText)
            let attributed = NSMutableAttributedString(string: fullText)
            attributed.addAttribute(.foregroundColor, value: BCTheme.Colors.primary, range: nsRange)
            attributed.addAttribute(.font, value: BCTheme.Typography.bodyBold, range: nsRange)
            contentLabel.attributedText = attributed
        } else {
            contentLabel.text = fullText
        }
    }
}

// MARK: - MessageCollectionViewController
final class MessageCollectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  private let screenTitle: String
  private let messages: [Message]
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var previewFileURL: URL?

  init(title: String, messages: [Message]) {
    self.screenTitle = title
    self.messages = messages
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = BCTheme.Colors.background
    title = screenTitle
    installGroupBackButton()
    tableView.dataSource = self
    tableView.delegate = self
    tableView.backgroundColor = .clear
    tableView.register(MessageCollectionCell.self, forCellReuseIdentifier: MessageCollectionCell.identifier)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    messages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: MessageCollectionCell.identifier, for: indexPath) as! MessageCollectionCell
    let message = messages[indexPath.row]
    cell.configure(message: message, iconName: iconName(for: message))
    return cell
  }

  private func iconName(for message: Message) -> String {
    if message.messageType == "file" {
      let name = (message.fileName ?? message.fileUrl ?? "").lowercased()
      if ["jpg", "jpeg", "png", "gif", "heic"].contains(where: { name.hasSuffix(".\($0)") }) {
        return "photo.fill"
      }
      if ["mp4", "mov"].contains(where: { name.hasSuffix(".\($0)") }) {
        return "video.fill"
      }
      return "doc.fill"
    }
    return "link"
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let message = messages[indexPath.row]
    if let link = firstURL(in: message.content) {
      UIApplication.shared.open(link)
      return
    }
    guard let url = Constants.mediaURL(from: message.fileUrl) else { return }
    let name = (message.fileName ?? message.fileUrl ?? "").lowercased()
    if ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(where: { name.hasSuffix(".\($0)") }) {
      saveImage(from: url)
    } else if ["mp4", "mov", "m4v", "webm"].contains(where: { name.hasSuffix(".\($0)") }) {
      showVideoActions(url: url)
    } else {
      previewDocument(from: url, fileName: message.fileName)
    }
  }

  private func saveImage(from url: URL) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
      guard let data, let image = UIImage(data: data) else { return }
      UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
      DispatchQueue.main.async { BCToast.show("Đã lưu ảnh", style: .success) }
    }.resume()
  }

  private func saveVideo(from url: URL) {
    URLSession.shared.downloadTask(with: url) { tempURL, _, _ in
      guard let tempURL else { return }
      UISaveVideoAtPathToSavedPhotosAlbum(tempURL.path, nil, nil, nil)
      DispatchQueue.main.async { BCToast.show("Đã lưu video", style: .success) }
    }.resume()
  }

  private func showVideoActions(url: URL) {
    let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    sheet.addAction(UIAlertAction(title: "Xem video", style: .default) { [weak self] _ in
      self?.playMedia(from: url)
    })
    sheet.addAction(UIAlertAction(title: "Lưu video", style: .default) { [weak self] _ in
      self?.saveVideo(from: url)
    })
    sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
    guard presentedViewController == nil else { return }
    present(sheet, animated: true)
  }

  private func playMedia(from url: URL) {
    let player = AVPlayer(url: url)
    let controller = AVPlayerViewController()
    controller.player = player
    guard presentedViewController == nil else { return }
    present(controller, animated: true) {
      player.play()
    }
  }

  private func previewDocument(from url: URL, fileName: String?) {
    if url.isFileURL {
      presentQuickLook(url)
      return
    }

    URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in
      guard let self else { return }
      if let error {
        DispatchQueue.main.async { BCToast.show(error.localizedDescription, style: .error) }
        return
      }
      guard let tempURL else {
        DispatchQueue.main.async { BCToast.show("Không tải được file.", style: .error) }
        return
      }

      let safeName = self.safePreviewFileName(fileName, fallbackURL: url)
      let destination = FileManager.default.temporaryDirectory.appendingPathComponent(safeName)
      try? FileManager.default.removeItem(at: destination)
      do {
        try FileManager.default.copyItem(at: tempURL, to: destination)
        DispatchQueue.main.async { self.presentQuickLook(destination) }
      } catch {
        DispatchQueue.main.async { BCToast.show("Không mở được file.", style: .error) }
      }
    }.resume()
  }

  private func presentQuickLook(_ url: URL) {
    previewFileURL = url
    let controller = QLPreviewController()
    controller.dataSource = self
    guard presentedViewController == nil else { return }
    present(controller, animated: true)
  }

  private func safePreviewFileName(_ fileName: String?, fallbackURL: URL) -> String {
    let rawName = fileName?.isEmpty == false ? fileName! : fallbackURL.lastPathComponent
    let cleaned = rawName.replacingOccurrences(of: "/", with: "_")
    return cleaned.isEmpty ? "attachment" : cleaned
  }

  private func firstURL(in text: String) -> URL? {
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return detector.firstMatch(in: text, options: [], range: range)?.url
  }
}

extension MessageCollectionViewController: QLPreviewControllerDataSource {
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    previewFileURL == nil ? 0 : 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    (previewFileURL as NSURL?) ?? NSURL(fileURLWithPath: "")
  }
}

private final class MessageCollectionCell: UITableViewCell {
    static let identifier = "MessageCollectionCell"
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = BCTheme.Colors.surface
        accessoryType = .disclosureIndicator

        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        iconView.tintColor = BCTheme.Colors.primary

        titleLabel.font = BCTheme.Typography.bodyBold
        titleLabel.textColor = BCTheme.Colors.textPrimary

        timeLabel.font = BCTheme.Typography.caption
        timeLabel.textColor = BCTheme.Colors.textSecondary

        let textStack = UIStackView(arrangedSubviews: [titleLabel, timeLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        [iconView, textStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: BCTheme.Layout.paddingM),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: BCTheme.Layout.paddingM),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -BCTheme.Layout.paddingM),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(message: Message, iconName: String) {
        titleLabel.text = message.fileName ?? message.content
        timeLabel.text = message.createdAt

        // Thumbnail loading if it's an image
        if message.messageType == "file",
           let urlString = message.fileUrl,
           let url = Constants.mediaURL(from: urlString) {

            let name = (message.fileName ?? urlString).lowercased()
            if ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(where: { name.hasSuffix(".\($0)") }) {
                ImageCache.shared.load(from: url) { [weak self] image in
                    if let image = image {
                        self?.iconView.image = image
                    } else {
                        self?.iconView.image = UIImage(systemName: "photo.fill")
                    }
                }
                return
            }
        }

        // Fallback icon
        iconView.image = UIImage(systemName: iconName)
    }
}

// MARK: - GroupMembersViewController
final class GroupMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  private var room: Room
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)

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
    title = "Thành viên"
    installGroupBackButton()

    tableView.dataSource = self
    tableView.delegate = self
    tableView.backgroundColor = .clear
    tableView.register(GroupMemberCell.self, forCellReuseIdentifier: GroupMemberCell.identifier)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    room.members?.count ?? 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: GroupMemberCell.identifier, for: indexPath) as! GroupMemberCell
    if let member = room.members?[indexPath.row] {
        cell.configure(member: member)
        cell.accessoryType = member.userId == TokenManager.shared.currentUser?.id ? .none : .disclosureIndicator
    }
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard let member = room.members?[indexPath.row] else { return }

    if member.userId == TokenManager.shared.currentUser?.id {
      BCToast.show("Đây là tài khoản của bạn.", style: .success)
      return
    }

    let sheet = UIAlertController(
      title: member.displayName,
      message: "@\(member.username)",
      preferredStyle: .actionSheet)
    sheet.addAction(UIAlertAction(title: "Kết bạn", style: .default) { [weak self] _ in
      self?.sendFriendRequest(to: member)
    })
    if canRemove(member) {
      sheet.addAction(UIAlertAction(title: "Xóa khỏi nhóm", style: .destructive) { [weak self] _ in
        self?.confirmRemoveMember(member)
      })
    }
    sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
    present(sheet, animated: true)
  }

  func tableView(
    _ tableView: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
  ) -> UISwipeActionsConfiguration? {
    guard canRemoveMembers,
      let member = room.members?[indexPath.row],
      canRemove(member)
    else { return nil }
    let action = UIContextualAction(style: .destructive, title: "Xóa") { [weak self] _, _, done in
      self?.confirmRemoveMember(member)
      done(true)
    }
    action.image = UIImage(systemName: "person.crop.circle.badge.minus")
    return UISwipeActionsConfiguration(actions: [action])
  }

  private var canRemoveMembers: Bool {
    guard !room.isDirect,
      let currentId = TokenManager.shared.currentUser?.id,
      let current = room.members?.first(where: { $0.userId == currentId })
    else { return false }
    return current.role == "admin"
  }

  private func canRemove(_ member: RoomMember) -> Bool {
    canRemoveMembers
      && member.userId != TokenManager.shared.currentUser?.id
      && member.role != "admin"
  }

  private func confirmRemoveMember(_ member: RoomMember) {
    let alert = UIAlertController(
      title: "Xóa khỏi nhóm?",
      message: "\(member.displayName ?? member.username) sẽ không còn trong nhóm này.",
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
    alert.addAction(UIAlertAction(title: "Xóa", style: .destructive) { [weak self] _ in
      self?.removeMember(member)
    })
    present(alert, animated: true)
  }

  private func removeMember(_ member: RoomMember) {
    NetworkManager.shared.kickMember(roomId: room.id, userId: member.userId) { [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        switch result {
        case .success:
          self.room.members?.removeAll { $0.userId == member.userId }
          self.tableView.reloadData()
        case .failure(let error):
          BCToast.show(error.localizedDescription, style: .error)
        }
      }
    }
  }

  private func sendFriendRequest(to member: RoomMember) {
    NetworkManager.shared.sendFriendRequest(username: member.username) { result in
      DispatchQueue.main.async {
        switch result {
        case .success:
          BCToast.show("Đã gửi lời mời kết bạn", style: .success)
        case .failure(let error):
          BCToast.show(error.localizedDescription, style: .error)
        }
      }
    }
  }
}

private final class GroupMemberCell: UITableViewCell {
    static let identifier = "GroupMemberCell"
    private let avatar = BCAvatar(size: BCTheme.Layout.avatarM)
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = BCTheme.Colors.surface

        nameLabel.font = BCTheme.Typography.subheadlineBold
        nameLabel.textColor = BCTheme.Colors.textPrimary

        roleLabel.font = BCTheme.Typography.caption
        roleLabel.textColor = BCTheme.Colors.textSecondary

        let stack = UIStackView(arrangedSubviews: [nameLabel, roleLabel])
        stack.axis = .vertical
        stack.spacing = 2

        [avatar, stack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: BCTheme.Layout.paddingM),
            avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            stack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: BCTheme.Layout.paddingM),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -BCTheme.Layout.paddingM),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(member: RoomMember) {
        avatar.configure(name: member.displayName ?? member.username, url: member.avatarUrl)
        nameLabel.text = member.displayName ?? member.username

        if member.role == "admin" {
            roleLabel.text = "Quản trị viên"
            roleLabel.textColor = BCTheme.Colors.primary
        } else {
            roleLabel.text = "Thành viên"
            roleLabel.textColor = BCTheme.Colors.textSecondary
        }
    }
}

// MARK: - Base Helpers
extension UIViewController {
  fileprivate func installGroupBackButton() {
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "chevron.left"),
      style: .plain,
      target: self,
      action: #selector(groupBackTapped)
    )
  }

  @objc fileprivate func groupBackTapped() {
    navigationController?.popViewController(animated: true)
  }
}
