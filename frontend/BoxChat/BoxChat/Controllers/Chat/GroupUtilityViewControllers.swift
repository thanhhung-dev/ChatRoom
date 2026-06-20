import AVKit
import QuickLook
import UIKit

final class EditGroupInfoViewController: UIViewController {
  var onSaved: ((Room) -> Void)?

  private var room: Room
  private var selectedAvatar: UIImage?
  private let avatarButton = UIButton(type: .system)
  private let avatarImageView = UIImageView()
  private let nameField = UITextField()
  private let descriptionField = UITextField()

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
    avatarImageView.image = UIImage(systemName: "person.3.fill")
    if let url = Constants.mediaURL(from: room.avatarUrl) {
      URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
        guard let self, let data, let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.avatarImageView.image = image }
      }.resume()
    }
    avatarImageView.tintColor = .systemBlue
    avatarImageView.backgroundColor = .secondarySystemBackground
    avatarImageView.contentMode = .scaleAspectFill
    avatarImageView.layer.cornerRadius = 56
    avatarImageView.clipsToBounds = true
    avatarImageView.translatesAutoresizingMaskIntoConstraints = false
    avatarButton.addSubview(avatarImageView)
    avatarButton.addTarget(self, action: #selector(didTapAvatar), for: .touchUpInside)

    let camera = UIImageView(image: UIImage(systemName: "camera.fill"))
    camera.tintColor = .systemBlue
    camera.backgroundColor = .systemBackground
    camera.layer.cornerRadius = 16
    camera.contentMode = .center
    camera.translatesAutoresizingMaskIntoConstraints = false
    avatarButton.addSubview(camera)

    configure(field: nameField, placeholder: "Tên nhóm", text: room.name)
    configure(field: descriptionField, placeholder: "Mô tả nhóm", text: room.description)

    let stack = UIStackView(arrangedSubviews: [
      avatarButton,
      fieldSection("Tên nhóm", nameField),
      fieldSection("Mô tả nhóm", descriptionField),
    ])
    stack.axis = .vertical
    stack.spacing = 24
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

      avatarButton.heightAnchor.constraint(equalToConstant: 120),
      avatarImageView.centerXAnchor.constraint(equalTo: avatarButton.centerXAnchor),
      avatarImageView.topAnchor.constraint(equalTo: avatarButton.topAnchor),
      avatarImageView.widthAnchor.constraint(equalToConstant: 112),
      avatarImageView.heightAnchor.constraint(equalToConstant: 112),
      camera.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
      camera.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
      camera.widthAnchor.constraint(equalToConstant: 34),
      camera.heightAnchor.constraint(equalToConstant: 34),
    ])
  }

  private func configure(field: UITextField, placeholder: String, text: String?) {
    field.placeholder = placeholder
    field.text = text
    field.font = .systemFont(ofSize: 15, weight: .medium)
    field.backgroundColor = .secondarySystemBackground
    field.layer.cornerRadius = 14
    field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 48))
    field.leftViewMode = .always
    field.heightAnchor.constraint(equalToConstant: 48).isActive = true
  }

  private func fieldSection(_ title: String, _ field: UITextField) -> UIView {
    let label = UILabel()
    label.text = title
    label.font = .systemFont(ofSize: 13, weight: .bold)
    label.textColor = .secondaryLabel
    let stack = UIStackView(arrangedSubviews: [label, field])
    stack.axis = .vertical
    stack.spacing = 8
    return stack
  }

  @objc private func didTapAvatar() {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = .photoLibrary
    picker.allowsEditing = true
    present(picker, animated: true)
  }

  @objc private func didTapSave() {
    let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    let description = descriptionField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    navigationItem.rightBarButtonItem?.isEnabled = false

    NetworkManager.shared.updateRoom(roomId: room.id, name: name, description: description) {
      [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        switch result {
        case .success(let updated):
          if let selectedAvatar = self.selectedAvatar,
            let data = selectedAvatar.jpegData(compressionQuality: 0.78)
          {
            NetworkManager.shared.uploadRoomAvatar(roomId: updated.id, imageData: data) {
              [weak self] avatarResult in
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
          let alert = UIAlertController(
            title: "Không thể lưu", message: error.localizedDescription, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default))
          self.present(alert, animated: true)
        }
      }
    }
  }
}

extension EditGroupInfoViewController: UIImagePickerControllerDelegate,
  UINavigationControllerDelegate
{
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)
    let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
    selectedAvatar = image
    avatarImageView.image = image
  }
}

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
    view.backgroundColor = .systemBackground
    title = "Tìm kiếm"
    installGroupBackButton()
    searchBar.placeholder = "Tìm trong \(room.name)"
    searchBar.delegate = self
    tableView.dataSource = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    [searchBar, tableView].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview($0)
    }
    NSLayoutConstraint.activate([
      searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    filtered.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let message = filtered[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = message.content.isEmpty ? (message.fileName ?? "Tin nhắn") : message.content
    config.secondaryText = message.createdAt
    cell.contentConfiguration = config
    return cell
  }
}

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
    view.backgroundColor = .systemBackground
    title = screenTitle
    installGroupBackButton()
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let message = messages[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.image = UIImage(systemName: iconName(for: message))
    config.text = message.fileName ?? message.content
    config.secondaryText = message.createdAt
    cell.contentConfiguration = config
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
    URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
      guard let data, let image = UIImage(data: data) else { return }
      UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
      DispatchQueue.main.async { self?.showNotice("Đã lưu ảnh") }
    }.resume()
  }

  private func saveVideo(from url: URL) {
    URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, _ in
      guard let tempURL else { return }
      UISaveVideoAtPathToSavedPhotosAlbum(tempURL.path, nil, nil, nil)
      DispatchQueue.main.async { self?.showNotice("Đã lưu video") }
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
    present(sheet, animated: true)
  }

  private func playMedia(from url: URL) {
    let player = AVPlayer(url: url)
    let controller = AVPlayerViewController()
    controller.player = player
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
        DispatchQueue.main.async { self.showNotice(error.localizedDescription) }
        return
      }
      guard let tempURL else {
        DispatchQueue.main.async { self.showNotice("Không tải được file.") }
        return
      }

      let safeName = self.safePreviewFileName(fileName, fallbackURL: url)
      let destination = FileManager.default.temporaryDirectory.appendingPathComponent(safeName)
      try? FileManager.default.removeItem(at: destination)
      do {
        try FileManager.default.copyItem(at: tempURL, to: destination)
        DispatchQueue.main.async { self.presentQuickLook(destination) }
      } catch {
        DispatchQueue.main.async { self.showNotice("Không mở được file.") }
      }
    }.resume()
  }

  private func presentQuickLook(_ url: URL) {
    previewFileURL = url
    let controller = QLPreviewController()
    controller.dataSource = self
    present(controller, animated: true)
  }

  private func safePreviewFileName(_ fileName: String?, fallbackURL: URL) -> String {
    let rawName = fileName?.isEmpty == false ? fileName! : fallbackURL.lastPathComponent
    let cleaned = rawName.replacingOccurrences(of: "/", with: "_")
    return cleaned.isEmpty ? "attachment" : cleaned
  }

  private func showNotice(_ message: String) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    present(alert, animated: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
      alert.dismiss(animated: true)
    }
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
    previewFileURL! as NSURL
  }
}

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
    view.backgroundColor = .systemBackground
    title = "Thành viên"
    installGroupBackButton()
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let member = room.members?[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.image = UIImage(systemName: "person.crop.circle.fill")
    config.text = member?.displayName ?? member?.username ?? "Thành viên"
    config.secondaryText = member?.role == "admin" ? "Quản trị viên" : "Thành viên"
    cell.contentConfiguration = config
    cell.accessoryType = member?.userId == TokenManager.shared.currentUser?.id ? .none : .disclosureIndicator
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard let member = room.members?[indexPath.row] else { return }

    if member.userId == TokenManager.shared.currentUser?.id {
      showMemberNotice("Đây là tài khoản của bạn.")
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
      message: "\(member.displayName) sẽ không còn trong nhóm này.",
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
          self.showMemberNotice(error.localizedDescription)
        }
      }
    }
  }

  private func sendFriendRequest(to member: RoomMember) {
    NetworkManager.shared.sendFriendRequest(username: member.username) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success:
          self?.showMemberNotice("Đã gửi lời mời kết bạn tới \(member.displayName).")
        case .failure(let error):
          self?.showMemberNotice(error.localizedDescription)
        }
      }
    }
  }

  private func showMemberNotice(_ message: String) {
    let alert = UIAlertController(title: "Thông báo", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}

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
