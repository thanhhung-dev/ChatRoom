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

final class MessageCollectionViewController: UIViewController, UITableViewDataSource {
  private let screenTitle: String
  private let messages: [Message]
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)

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
}

final class GroupMembersViewController: UIViewController, UITableViewDataSource {
  private let room: Room
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
    return cell
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
