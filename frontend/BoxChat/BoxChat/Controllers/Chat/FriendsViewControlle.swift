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
  private let refreshControl = UIRefreshControl()

  private lazy var emptyStateView = BCEmptyState(
    title: "Chưa có bạn bè",
    message: "Hãy tìm username để kết bạn.",
    iconName: "person.2.slash"
  )

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
    view.backgroundColor = BCTheme.Colors.background

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
    searchBar.searchBarStyle = .minimal
    searchBarHeightConstraint = searchBar.heightAnchor.constraint(equalToConstant: 0)

    [segmentedControl, searchBar].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview($0)
    }

    NSLayoutConstraint.activate([
      segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
      segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: BCTheme.Layout.paddingM),
      segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -BCTheme.Layout.paddingM),

      searchBar.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 4),
      searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
      searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
      searchBarHeightConstraint!,
    ])
  }

  private func setupTableView() {
    tableView.dataSource = self
    tableView.delegate = self
    tableView.keyboardDismissMode = .interactive
    tableView.backgroundColor = .clear
    tableView.rowHeight = 64

    tableView.register(FriendCell.self, forCellReuseIdentifier: FriendCell.identifier)
    tableView.register(FriendRequestCell.self, forCellReuseIdentifier: FriendRequestCell.identifier)
    tableView.register(NearbyCell.self, forCellReuseIdentifier: NearbyCell.identifier)
    tableView.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.identifier)

    refreshControl.tintColor = BCTheme.Colors.primary
    refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    tableView.refreshControl = refreshControl

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
    emptyStateView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(emptyStateView)
    NSLayoutConstraint.activate([
      emptyStateView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
      emptyStateView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -30),
      emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: BCTheme.Layout.paddingL),
      emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -BCTheme.Layout.paddingL),
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

  @objc private func handleRefresh() {
    reloadData()
  }

  private func reloadData() {
    switch mode {
    case .friends:
      NetworkManager.shared.fetchFriends { [weak self] result in
        DispatchQueue.main.async {
          self?.refreshControl.endRefreshing()
          if case .success(let items) = result { self?.friends = items }
          self?.refreshTable()
        }
      }
    case .requests:
      NetworkManager.shared.fetchIncomingFriendRequests { [weak self] result in
        DispatchQueue.main.async {
          self?.refreshControl.endRefreshing()
          if case .success(let items) = result { self?.requests = items }
          self?.refreshTable()
        }
      }
    case .nearby:
      refreshControl.endRefreshing()
      refreshTable()
    case .search:
      refreshControl.endRefreshing()
      searchUsers()
    }
  }

  private func refreshTable() {
    switch mode {
    case .friends:
      emptyStateView.configure(title: "Chưa có bạn bè", message: "Hãy tìm username để kết bạn.", iconName: "person.2.slash")
      emptyStateView.isHidden = !friends.isEmpty
    case .requests:
      emptyStateView.configure(title: "Không có lời mời", message: "Chưa có lời mời kết bạn nào.", iconName: "person.crop.circle.badge.exclamationmark")
      emptyStateView.isHidden = !requests.isEmpty
    case .nearby:
      emptyStateView.configure(title: "Chưa tìm thấy ai", message: "Hãy mở app trên các máy cùng Wi-Fi và cho phép quyền Local Network.", iconName: "wifi.slash")
      emptyStateView.isHidden = !nearbyUsers.isEmpty
    case .search:
      emptyStateView.configure(title: "Tìm kiếm", message: "Nhập username để tìm bạn.", iconName: "magnifyingglass")
      emptyStateView.isHidden = !searchResults.isEmpty || !(searchBar.text ?? "").isEmpty
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

  private func sendFriendRequest(username: String, displayName: String) {
    NetworkManager.shared.sendFriendRequest(username: username) { result in
      DispatchQueue.main.async {
        switch result {
        case .success:
          BCToast.show("Đã gửi lời mời tới \(displayName)", style: .success)
        case .failure(let error):
          BCToast.show(error.localizedDescription, style: .error)
        }
      }
    }
  }

  private func setupKeyboardHandling() {
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

    installTapToDismissKeyboard()
  }

  @objc private func dismissKeyboard() { view.endEditing(true) }

  @objc private func keyboardWillChangeFrame(_ notification: Notification) {
    guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
    let keyboardFrame = view.convert(frame.cgRectValue, from: nil)
    let overlap = max(0, view.bounds.maxY - keyboardFrame.minY)
    updateTableBottomConstraint(overlap: overlap, notification: notification)
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    updateTableBottomConstraint(overlap: 0, notification: notification)
  }

  private func updateTableBottomConstraint(overlap: CGFloat, notification: Notification) {
    tableBottomConstraint?.constant = -overlap
    let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
    let rawCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UInt(UIView.AnimationOptions.curveEaseInOut.rawValue)
    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: rawCurve << 16), animations: { self.view.layoutIfNeeded() })
  }
}

extension FriendsViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(runSearch), object: nil)
    perform(#selector(runSearch), with: nil, afterDelay: 0.35)
  }
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }
  @objc private func runSearch() { searchUsers() }
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
    switch mode {
    case .friends:
      let cell = tableView.dequeueReusableCell(withIdentifier: FriendCell.identifier, for: indexPath) as! FriendCell
      cell.configure(friend: friends[indexPath.row].friend, room: friends[indexPath.row].room)
      return cell

    case .requests:
      let cell = tableView.dequeueReusableCell(withIdentifier: FriendRequestCell.identifier, for: indexPath) as! FriendRequestCell
      let request = requests[indexPath.row]
      cell.configure(request: request)
      cell.onAccept = { [weak self] in
        NetworkManager.shared.acceptFriendRequest(id: request.id) { result in
          DispatchQueue.main.async {
            switch result {
            case .success:
                BCToast.show("Đã chấp nhận kết bạn", style: .success)
                self?.reloadData()
            case .failure(let error):
                BCToast.show(error.localizedDescription, style: .error)
            }
          }
        }
      }
      cell.onDecline = { [weak self] in
        NetworkManager.shared.rejectFriendRequest(id: request.id) { _ in
          DispatchQueue.main.async { self?.reloadData() }
        }
      }
      return cell

    case .nearby:
      let cell = tableView.dequeueReusableCell(withIdentifier: NearbyCell.identifier, for: indexPath) as! NearbyCell
      cell.configure(user: nearbyUsers[indexPath.row])
      return cell

    case .search:
      let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.identifier, for: indexPath) as! SearchResultCell
      cell.configure(user: searchResults[indexPath.row])
      return cell
    }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    switch mode {
    case .friends:
      showFriendActions(friends[indexPath.row])

    case .requests:
        break // Handled by buttons

    case .nearby:
      let user = nearbyUsers[indexPath.row]
      sendFriendRequest(username: user.username, displayName: user.displayName)

    case .search:
      let user = searchResults[indexPath.row]
      sendFriendRequest(username: user.username, displayName: user.displayName ?? user.username)
    }
  }

  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
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
          BCToast.show(error.localizedDescription, style: .error)
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

// MARK: - Custom Cells

private final class FriendCell: UITableViewCell {
    static let identifier = "FriendCell"
    private let avatar = BCAvatar(size: BCTheme.Layout.avatarS)
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        accessoryType = .disclosureIndicator
        backgroundColor = BCTheme.Colors.surface

        nameLabel.font = BCTheme.Typography.subheadlineBold
        nameLabel.textColor = BCTheme.Colors.textPrimary

        usernameLabel.font = BCTheme.Typography.caption
        usernameLabel.textColor = BCTheme.Colors.textSecondary

        let stack = UIStackView(arrangedSubviews: [nameLabel, usernameLabel])
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
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -BCTheme.Layout.paddingM),
        ])
    }

    func configure(friend: UserResponse, room: Room?) {
        avatar.configure(name: friend.displayName ?? friend.username, url: friend.avatarUrl)
        nameLabel.text = friend.displayName ?? friend.username
        usernameLabel.text = room?.name ?? "@\(friend.username)"
    }
}

private final class FriendRequestCell: UITableViewCell {
    static let identifier = "FriendRequestCell"
    private let avatar = BCAvatar(size: BCTheme.Layout.avatarM)
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let acceptButton = UIButton(type: .system)
    private let declineButton = UIButton(type: .system)

    var onAccept: (() -> Void)?
    var onDecline: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        selectionStyle = .none
        backgroundColor = BCTheme.Colors.surface

        nameLabel.font = BCTheme.Typography.subheadlineBold
        nameLabel.textColor = BCTheme.Colors.textPrimary

        usernameLabel.font = BCTheme.Typography.caption
        usernameLabel.textColor = BCTheme.Colors.textSecondary

        let textStack = UIStackView(arrangedSubviews: [nameLabel, usernameLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        var acceptConfig = UIButton.Configuration.filled()
        acceptConfig.image = UIImage(systemName: "checkmark")
        acceptConfig.baseBackgroundColor = BCTheme.Colors.primary
        acceptConfig.baseForegroundColor = .white
        acceptConfig.cornerStyle = .capsule
        acceptButton.configuration = acceptConfig
        acceptButton.addAction(UIAction { [weak self] _ in self?.onAccept?() }, for: .touchUpInside)

        var declineConfig = UIButton.Configuration.filled()
        declineConfig.image = UIImage(systemName: "xmark")
        declineConfig.baseBackgroundColor = BCTheme.Colors.surfaceElevated
        declineConfig.baseForegroundColor = BCTheme.Colors.textSecondary
        declineConfig.cornerStyle = .capsule
        declineButton.configuration = declineConfig
        declineButton.addAction(UIAction { [weak self] _ in self?.onDecline?() }, for: .touchUpInside)

        let btnStack = UIStackView(arrangedSubviews: [acceptButton, declineButton])
        btnStack.axis = .horizontal
        btnStack.spacing = 8

        [avatar, textStack, btnStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: BCTheme.Layout.paddingM),
            avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: BCTheme.Layout.paddingM),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            btnStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -BCTheme.Layout.paddingM),
            btnStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            btnStack.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 8),

            acceptButton.widthAnchor.constraint(equalToConstant: 36),
            acceptButton.heightAnchor.constraint(equalToConstant: 36),
            declineButton.widthAnchor.constraint(equalToConstant: 36),
            declineButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    func configure(request: FriendRequestModel) {
        avatar.configure(name: request.requester.displayName ?? request.requester.username, url: request.requester.avatarUrl)
        nameLabel.text = request.requester.displayName ?? request.requester.username
        usernameLabel.text = "@\(request.requester.username)"
    }
}

private final class NearbyCell: UITableViewCell {
    static let identifier = "NearbyCell"
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let infoLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = BCTheme.Colors.surface

        iconView.image = UIImage(systemName: "wifi.circle.fill")
        iconView.tintColor = BCTheme.Colors.primary
        iconView.contentMode = .scaleAspectFit

        nameLabel.font = BCTheme.Typography.subheadlineBold
        nameLabel.textColor = BCTheme.Colors.textPrimary

        infoLabel.font = BCTheme.Typography.caption
        infoLabel.textColor = BCTheme.Colors.textSecondary

        let stack = UIStackView(arrangedSubviews: [nameLabel, infoLabel])
        stack.axis = .vertical
        stack.spacing = 2

        [iconView, stack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: BCTheme.Layout.paddingM),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            stack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: BCTheme.Layout.paddingM),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -BCTheme.Layout.paddingM)
        ])
    }

    func configure(user: LocalDiscoveredUser) {
        nameLabel.text = user.displayName
        infoLabel.text = "@\(user.username) đang ở gần"
    }
}

private final class SearchResultCell: UITableViewCell {
    static let identifier = "SearchResultCell"
    private let avatar = BCAvatar(size: BCTheme.Layout.avatarM)
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let addButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        selectionStyle = .none
        backgroundColor = BCTheme.Colors.surface

        nameLabel.font = BCTheme.Typography.subheadlineBold
        nameLabel.textColor = BCTheme.Colors.textPrimary

        usernameLabel.font = BCTheme.Typography.caption
        usernameLabel.textColor = BCTheme.Colors.textSecondary

        let stack = UIStackView(arrangedSubviews: [nameLabel, usernameLabel])
        stack.axis = .vertical
        stack.spacing = 2

        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "person.badge.plus")
        config.baseBackgroundColor = BCTheme.Colors.primarySoft
        config.baseForegroundColor = BCTheme.Colors.primary
        config.cornerStyle = .capsule
        addButton.configuration = config
        addButton.isUserInteractionEnabled = false // let row selection handle action

        [avatar, stack, addButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: BCTheme.Layout.paddingM),
            avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            stack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: BCTheme.Layout.paddingM),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -BCTheme.Layout.paddingM),
            addButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addButton.leadingAnchor.constraint(greaterThanOrEqualTo: stack.trailingAnchor, constant: 8),
            addButton.widthAnchor.constraint(equalToConstant: 36),
            addButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    func configure(user: UserResponse) {
        avatar.configure(name: user.displayName ?? user.username, url: user.avatarUrl)
        nameLabel.text = user.displayName ?? user.username
        usernameLabel.text = "@\(user.username)"
    }
}
