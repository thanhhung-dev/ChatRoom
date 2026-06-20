import UIKit

final class FriendsViewController: UIViewController {
  private enum Mode: Int {
    case friends
    case requests
    case nearby
    case search
  }

  private let segmentedControl = UISegmentedControl(items: ["Bạn bè", "Lời mời", "Gần đây", "Tìm kiếm"])
  private let searchBar = UISearchBar()
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private let emptyLabel = UILabel()
  private var tableBottomConstraint: NSLayoutConstraint?
  private var searchBarHeightConstraint: NSLayoutConstraint?

  private var mode: Mode = .friends
  private var friends: [FriendshipModel] = []
  private var requests: [FriendRequestModel] = []
  private var nearbyUsers: [LocalDiscoveredUser] = []
  private var searchResults: [UserResponse] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Bạn bè"
    navigationController?.navigationBar.prefersLargeTitles = true
    view.backgroundColor = .systemGroupedBackground
    setupControls()
    setupTableView()
    setupEmptyState()
    setupKeyboardHandling()
    LocalPeerDiscoveryService.shared.delegate = self
    LocalPeerDiscoveryService.shared.start(currentUser: TokenManager.shared.currentUser)
    reloadData()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
    LocalPeerDiscoveryService.shared.delegate = self
    LocalPeerDiscoveryService.shared.start(currentUser: TokenManager.shared.currentUser)
    reloadData()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    LocalPeerDiscoveryService.shared.delegate = nil
    LocalPeerDiscoveryService.shared.stop()
  }

  private func setupControls() {
    segmentedControl.selectedSegmentIndex = 0
    segmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
    searchBar.placeholder = "Tìm theo username"
    searchBar.delegate = self
    searchBar.isHidden = true
    searchBarHeightConstraint = searchBar.heightAnchor.constraint(equalToConstant: 0)

    [segmentedControl, searchBar].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview($0)
    }

    NSLayoutConstraint.activate([
      segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
      segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      searchBar.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
      searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      searchBarHeightConstraint!,
    ])
  }

  private func setupTableView() {
    tableView.dataSource = self
    tableView.delegate = self
    tableView.keyboardDismissMode = .interactive
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)

    tableBottomConstraint = tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
      tableBottomConstraint!,
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }

  private func setupEmptyState() {
    emptyLabel.font = .systemFont(ofSize: 15, weight: .medium)
    emptyLabel.textColor = .secondaryLabel
    emptyLabel.textAlignment = .center
    emptyLabel.numberOfLines = 0
    emptyLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(emptyLabel)
    NSLayoutConstraint.activate([
      emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
      emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -30),
      emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
      emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
    ])
  }

  @objc private func modeChanged() {
    mode = Mode(rawValue: segmentedControl.selectedSegmentIndex) ?? .friends
    let isSearching = mode == .search
    searchBar.isHidden = !isSearching
    searchBarHeightConstraint?.constant = isSearching ? 56 : 0
    if isSearching {
      searchBar.becomeFirstResponder()
    } else {
      searchBar.resignFirstResponder()
    }
    UIView.animate(withDuration: 0.2) {
      self.view.layoutIfNeeded()
    }
    reloadData()
  }

  private func reloadData() {
    switch mode {
    case .friends:
      NetworkManager.shared.fetchFriends { [weak self] result in
        DispatchQueue.main.async {
          if case .success(let items) = result { self?.friends = items }
          self?.refreshTable()
        }
      }
    case .requests:
      NetworkManager.shared.fetchIncomingFriendRequests { [weak self] result in
        DispatchQueue.main.async {
          if case .success(let items) = result { self?.requests = items }
          self?.refreshTable()
        }
      }
    case .nearby:
      refreshTable()
    case .search:
      searchUsers()
    }
  }

  private func refreshTable() {
    switch mode {
    case .friends:
      emptyLabel.text = "Chưa có bạn bè. Hãy tìm username để kết bạn."
      emptyLabel.isHidden = !friends.isEmpty
    case .requests:
      emptyLabel.text = "Chưa có lời mời kết bạn."
      emptyLabel.isHidden = !requests.isEmpty
    case .nearby:
      emptyLabel.text = "Chưa thấy ai gần đây. Hãy mở app trên các máy cùng Wi-Fi và cho phép quyền Local Network."
      emptyLabel.isHidden = !nearbyUsers.isEmpty
    case .search:
      emptyLabel.text = "Nhập username để tìm bạn."
      emptyLabel.isHidden = !searchResults.isEmpty || !(searchBar.text ?? "").isEmpty
    }
    tableView.reloadData()
  }

  private func searchUsers() {
    let query = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !query.isEmpty else {
      searchResults = []
      refreshTable()
      return
    }
    NetworkManager.shared.searchUsers(query: query) { [weak self] result in
      DispatchQueue.main.async {
        if case .success(let users) = result {
          self?.searchResults = users
        }
        self?.refreshTable()
      }
    }
  }

  private func showError(_ error: Error) {
    let alert = UIAlertController(title: "Không thực hiện được", message: error.localizedDescription, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }

  private func sendFriendRequest(username: String, displayName: String) {
    NetworkManager.shared.sendFriendRequest(username: username) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success:
          let alert = UIAlertController(
            title: "Đã gửi lời mời",
            message: "Đợi \(displayName) chấp nhận để chat riêng.",
            preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default))
          self?.present(alert, animated: true)
        case .failure(let error):
          self?.showError(error)
        }
      }
    }
  }

  private func setupKeyboardHandling() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillChangeFrame(_:)),
      name: UIResponder.keyboardWillChangeFrameNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil)

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tapGesture.cancelsTouchesInView = false
    tapGesture.delegate = self
    view.addGestureRecognizer(tapGesture)
  }

  @objc private func dismissKeyboard() {
    view.endEditing(true)
  }

  @objc private func keyboardWillChangeFrame(_ notification: Notification) {
    guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
    else { return }
    let keyboardFrame = view.convert(frame.cgRectValue, from: nil)
    let overlap = max(0, view.bounds.maxY - keyboardFrame.minY)
    updateTableBottomConstraint(overlap: overlap, notification: notification)
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    updateTableBottomConstraint(overlap: 0, notification: notification)
  }

  private func updateTableBottomConstraint(overlap: CGFloat, notification: Notification) {
    tableBottomConstraint?.constant = -overlap
    let duration =
      notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
    let rawCurve =
      notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
      ?? UInt(UIView.AnimationOptions.curveEaseInOut.rawValue)
    UIView.animate(
      withDuration: duration,
      delay: 0,
      options: UIView.AnimationOptions(rawValue: rawCurve << 16),
      animations: { self.view.layoutIfNeeded() })
  }
}

extension FriendsViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(runSearch), object: nil)
    perform(#selector(runSearch), with: nil, afterDelay: 0.35)
  }

  @objc private func runSearch() {
    searchUsers()
  }
}

extension FriendsViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard gestureRecognizer is UITapGestureRecognizer else { return true }
    guard let touchedView = touch.view else { return true }
    return !touchedView.isDescendant(of: searchBar)
  }
}

extension FriendsViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch mode {
    case .friends: return friends.count
    case .requests: return requests.count
    case .nearby: return nearbyUsers.count
    case .search: return searchResults.count
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.imageProperties.tintColor = .systemBlue

    switch mode {
    case .friends:
      let item = friends[indexPath.row]
      config.image = UIImage(systemName: "person.crop.circle.fill")
      config.text = item.friend.displayName ?? item.friend.username
      config.secondaryText = item.room?.name ?? "Chat riêng"
      cell.accessoryType = .disclosureIndicator

    case .requests:
      let item = requests[indexPath.row]
      config.image = UIImage(systemName: "person.badge.plus")
      config.text = item.requester.displayName ?? item.requester.username
      config.secondaryText = "@\(item.requester.username) muốn kết bạn"
      cell.accessoryType = .none

    case .nearby:
      let user = nearbyUsers[indexPath.row]
      config.image = UIImage(systemName: "wifi.circle.fill")
      config.text = user.displayName
      config.secondaryText = "@\(user.username) đang ở gần"
      cell.accessoryType = .none

    case .search:
      let user = searchResults[indexPath.row]
      config.image = UIImage(systemName: "magnifyingglass.circle.fill")
      config.text = user.displayName ?? user.username
      config.secondaryText = "@\(user.username)"
      cell.accessoryType = .none
    }

    cell.contentConfiguration = config
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    switch mode {
    case .friends:
      showFriendActions(friends[indexPath.row])

    case .requests:
      let request = requests[indexPath.row]
      let sheet = UIAlertController(title: request.requester.username, message: nil, preferredStyle: .actionSheet)
      sheet.addAction(UIAlertAction(title: "Chấp nhận", style: .default) { [weak self] _ in
        NetworkManager.shared.acceptFriendRequest(id: request.id) { result in
          DispatchQueue.main.async {
            switch result {
            case .success:
              self?.reloadData()
            case .failure(let error):
              self?.showError(error)
            }
          }
        }
      })
      sheet.addAction(UIAlertAction(title: "Từ chối", style: .destructive) { [weak self] _ in
        NetworkManager.shared.rejectFriendRequest(id: request.id) { _ in
          DispatchQueue.main.async { self?.reloadData() }
        }
      })
      sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
      present(sheet, animated: true)

    case .nearby:
      let user = nearbyUsers[indexPath.row]
      sendFriendRequest(username: user.username, displayName: user.displayName)

    case .search:
      let user = searchResults[indexPath.row]
      sendFriendRequest(username: user.username, displayName: user.displayName ?? user.username)
    }
  }

  func tableView(
    _ tableView: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
  ) -> UISwipeActionsConfiguration? {
    guard mode == .friends else { return nil }
    let action = UIContextualAction(style: .destructive, title: "Xóa") { [weak self] _, _, done in
      guard let self else {
        done(false)
        return
      }
      self.confirmDeleteFriend(self.friends[indexPath.row])
      done(true)
    }
    action.image = UIImage(systemName: "person.crop.circle.badge.minus")
    return UISwipeActionsConfiguration(actions: [action])
  }

  private func showFriendActions(_ friendship: FriendshipModel) {
    let name = friendship.friend.displayName ?? friendship.friend.username
    let sheet = UIAlertController(title: name, message: "@\(friendship.friend.username)", preferredStyle: .actionSheet)
    sheet.addAction(UIAlertAction(title: "Nhắn tin", style: .default) { [weak self] _ in
      guard let self, let room = friendship.room else { return }
      let chatVC = ChatRoomViewController(room: room)
      chatVC.hidesBottomBarWhenPushed = true
      self.navigationController?.pushViewController(chatVC, animated: true)
    })
    sheet.addAction(UIAlertAction(title: "Xóa bạn bè", style: .destructive) { [weak self] _ in
      self?.confirmDeleteFriend(friendship)
    })
    sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
    present(sheet, animated: true)
  }

  private func confirmDeleteFriend(_ friendship: FriendshipModel) {
    let name = friendship.friend.displayName ?? friendship.friend.username
    let alert = UIAlertController(
      title: "Xóa bạn bè?",
      message: "Bạn và \(name) sẽ không còn chat riêng với nhau trong danh sách bạn bè.",
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
    alert.addAction(UIAlertAction(title: "Xóa", style: .destructive) { [weak self] _ in
      self?.deleteFriend(friendship)
    })
    present(alert, animated: true)
  }

  private func deleteFriend(_ friendship: FriendshipModel) {
    NetworkManager.shared.deleteFriendship(id: friendship.id) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success:
          self?.friends.removeAll { $0.id == friendship.id }
          self?.refreshTable()
        case .failure(let error):
          self?.showError(error)
        }
      }
    }
  }
}

extension FriendsViewController: LocalPeerDiscoveryServiceDelegate {
  func localPeerDiscoveryDidUpdateUsers(_ users: [LocalDiscoveredUser]) {
    nearbyUsers = users
    if mode == .nearby {
      refreshTable()
    }
  }
}
