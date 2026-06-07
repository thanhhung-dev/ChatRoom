import UIKit

final class RoomListViewController: UIViewController {
    private enum Filter: String, CaseIterable {
        case all = "Tất cả"
        case unread = "Chưa đọc"
        case groups = "Nhóm"
        case friends = "Bạn bè"
    }

    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let searchContainer = UIView()
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let searchTextField = UITextField()
    private let filterStackView = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()

    private var allRooms: [Room] = []
    private var rooms: [Room] = []
    private var selectedFilter: Filter = .all

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupHeader()
        setupTableView()
        ensureCurrentUserLoaded()
        fetchRooms()
        WebSocketService.shared.addDelegate(self)
        WebSocketService.shared.connect()
        NotificationCenter.default.addObserver(self, selector: #selector(handleLogoutRequired), name: .didLogoutRequired, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        WebSocketService.shared.addDelegate(self)
        WebSocketService.shared.connect()
        joinFetchedRooms()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyFilters(animated: false)
    }

    deinit {
        WebSocketService.shared.removeDelegate(self)
        NotificationCenter.default.removeObserver(self)
    }

    private func setupHeader() {
        titleLabel.attributedText = brandTitle()
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.backgroundColor = .systemBlue
        addButton.layer.cornerRadius = 18
        addButton.addTarget(self, action: #selector(didTapAddRoom), for: .touchUpInside)

        searchContainer.backgroundColor = .secondarySystemBackground
        searchContainer.layer.cornerRadius = 18
        searchContainer.layer.cornerCurve = .continuous

        searchIcon.tintColor = .secondaryLabel
        searchIcon.contentMode = .scaleAspectFit

        searchTextField.placeholder = "Tìm kiếm"
        searchTextField.font = .systemFont(ofSize: 15, weight: .medium)
        searchTextField.borderStyle = .none
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.addTarget(self, action: #selector(searchDidChange), for: .editingChanged)

        filterStackView.axis = .horizontal
        filterStackView.spacing = 10
        filterStackView.alignment = .center
        Filter.allCases.forEach { filterStackView.addArrangedSubview(makeFilterButton($0)) }

        [titleLabel, addButton, searchContainer, filterStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        [searchIcon, searchTextField].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            searchContainer.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 36),
            addButton.heightAnchor.constraint(equalToConstant: 36),

            searchContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchContainer.heightAnchor.constraint(equalToConstant: 46),

            searchIcon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 14),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 18),
            searchIcon.heightAnchor.constraint(equalToConstant: 18),

            searchTextField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 10),
            searchTextField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -12),
            searchTextField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

            filterStackView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 14),
            filterStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            filterStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            filterStackView.heightAnchor.constraint(equalToConstant: 38),
        ])
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RoomCell.self, forCellReuseIdentifier: RoomCell.identifier)
        tableView.rowHeight = 76
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 20, right: 0)
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: filterStackView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func brandTitle() -> NSAttributedString {
        let text = NSMutableAttributedString(string: "Box", attributes: [.font: UIFont.systemFont(ofSize: 32, weight: .heavy), .foregroundColor: UIColor.label])
        text.append(NSAttributedString(string: "Chat", attributes: [.font: UIFont.systemFont(ofSize: 32, weight: .heavy), .foregroundColor: UIColor.systemBlue]))
        return text
    }

    private func makeFilterButton(_ filter: Filter) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(filter.rawValue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.contentEdgeInsets = UIEdgeInsets(top: 9, left: 16, bottom: 9, right: 16)
        button.layer.cornerRadius = 18
        button.layer.cornerCurve = .continuous
        button.tag = Filter.allCases.firstIndex(of: filter) ?? 0
        button.addTarget(self, action: #selector(didTapFilter(_:)), for: .touchUpInside)
        styleFilterButton(button, selected: filter == selectedFilter)
        return button
    }

    private func styleFilterButton(_ button: UIButton, selected: Bool) {
        button.backgroundColor = selected ? UIColor.systemBlue.withAlphaComponent(0.13) : .secondarySystemBackground
        button.setTitleColor(selected ? .systemBlue : .secondaryLabel, for: .normal)
        button.layer.borderWidth = selected ? 0 : 1
        button.layer.borderColor = UIColor.separator.withAlphaComponent(0.28).cgColor
    }

    @objc private func fetchRooms() {
        NetworkManager.shared.fetchRooms { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.refreshControl.endRefreshing()
                if case .success(let response) = result {
                    self.allRooms = response.items
                    response.items.compactMap { $0.lastMessage }.forEach {
                        WebSocketService.shared.localLastMessageIds[$0.roomId] = $0.id
                    }
                    self.joinFetchedRooms()
                    self.applyFilters(animated: true)
                } else if case .failure(let error) = result {
                    self.showAlert(title: "Không tải được phòng", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func handleRefresh() { fetchRooms() }

    private func joinFetchedRooms() {
        allRooms.forEach { room in
            WebSocketService.shared.sendEvent(type: "join_room", payload: ["room_id": room.id])
        }
    }

    private func ensureCurrentUserLoaded() {
        guard TokenManager.shared.currentUser == nil else { return }
        NetworkManager.shared.fetchMe { [weak self] result in
            if case .success(let user) = result {
                TokenManager.shared.currentUser = user
                DispatchQueue.main.async {
                    guard self?.allRooms.isEmpty == false else { return }
                    self?.applyFilters(animated: false)
                }
            }
        }
    }

    @objc private func searchDidChange() { applyFilters(animated: true) }

    @objc private func didTapFilter(_ sender: UIButton) {
        selectedFilter = Filter.allCases[sender.tag]
        filterStackView.arrangedSubviews.compactMap { $0 as? UIButton }.forEach {
            styleFilterButton($0, selected: $0.tag == sender.tag)
        }
        UIView.animate(withDuration: 0.18) { sender.transform = CGAffineTransform(scaleX: 1.04, y: 1.04) }
        completion: { _ in UIView.animate(withDuration: 0.18) { sender.transform = .identity } }
        applyFilters(animated: true)
    }

    private func applyFilters(animated: Bool) {
        let query = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        rooms = allRooms.filter { room in
            let matchesSearch = query.isEmpty || room.name.lowercased().contains(query)
            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .unread: matchesFilter = room.unreadCount > 0
            case .groups: matchesFilter = room.memberCount > 1
            case .friends: matchesFilter = room.memberCount <= 1
            }
            return matchesSearch && matchesFilter
        }
        tableView.reloadData()
        if animated { animateVisibleCells() }
    }

    private func animateVisibleCells() {
        tableView.visibleCells.enumerated().forEach { index, cell in
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 12)
            UIView.animate(withDuration: 0.36, delay: Double(index) * 0.035, usingSpringWithDamping: 0.86, initialSpringVelocity: 0.35, options: [.curveEaseOut]) {
                cell.alpha = 1; cell.transform = .identity
            }
        }
    }

    @objc private func didTapAddRoom() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Tạo nhóm mới", style: .default) { [weak self] _ in self?.openCreateGroup() })
        sheet.addAction(UIAlertAction(title: "Nhập mã mời", style: .default) { [weak self] _ in self?.showJoinRoomPrompt() })
        sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = addButton; popover.sourceRect = addButton.bounds
        }
        present(sheet, animated: true)
    }

    private func openCreateGroup() {
        let createVC = CreateGroupViewController()
        createVC.onDataChanged = { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self?.fetchRooms() }
        }
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func showJoinRoomPrompt() {
        let alert = UIAlertController(title: "Nhập mã mời", message: "Dán mã mời của nhóm chat để tham gia.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Ví dụ: ABC123"
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType = .no
            tf.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Tham gia", style: .default) { [weak self, weak alert] _ in
            let code = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self?.joinRoom(inviteCode: code)
        })
        present(alert, animated: true)
    }

    private func joinRoom(inviteCode: String) {
        guard !inviteCode.isEmpty else { showAlert(title: "Thiếu mã mời", message: "Bạn cần nhập mã mời để tham gia nhóm."); return }
        addButton.isEnabled = false
        NetworkManager.shared.joinRoom(inviteCode: inviteCode) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.addButton.isEnabled = true
                switch result {
                case .success(let room):
                    self.fetchRooms()
                    let chatVC = ChatRoomViewController(room: room)
                    chatVC.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(chatVC, animated: true)
                case .failure(let error):
                    self.showAlert(title: "Không thể tham gia", message: error.localizedDescription)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func performLogout() {
        WebSocketService.shared.disconnect()
        TokenManager.shared.clear()
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let sceneDelegate = windowScene.delegate as? SceneDelegate,
                  let window = sceneDelegate.window else { return }
            window.rootViewController = UINavigationController(rootViewController: WelcomeViewController())
            UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: nil)
        }
    }

    @objc private func handleLogoutRequired() { performLogout() }
    @objc private func setupNavBar() {}
}

extension RoomListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rooms.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RoomCell.identifier, for: indexPath) as! RoomCell
        cell.configure(with: rooms[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chatVC = ChatRoomViewController(room: rooms[indexPath.row])
        chatVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

extension RoomListViewController: WebSocketServiceDelegate {
    func webSocketDidConnect() {
        joinFetchedRooms()
    }
    func webSocketDidDisconnect(error: Error?) {}
    func webSocketDidReceiveEvent(type: String, payload: [String: Any]) {
        switch type {
        case "new_message", "message_sent":
            guard let message = decodeMessage(from: payload),
                  let index = allRooms.firstIndex(where: { $0.id == message.roomId }) else { return }
            allRooms[index].lastMessage = message
            if !isMessageFromCurrentUser(message) {
                allRooms[index].unreadCount += 1
            }
            applyFilters(animated: false)

        case "unread_update":
            guard let roomId = payload["room_id"] as? Int,
                  let unread = payload["unread_count"] as? Int,
                  let index = allRooms.firstIndex(where: { $0.id == roomId }) else { return }
            allRooms[index].unreadCount = unread
            applyFilters(animated: false)

        default:
            break
        }
    }

    private func decodeMessage(from payload: [String: Any]) -> Message? {
        let object = payload["message"] as? [String: Any] ?? payload
        if let messageId = object["message_id"] as? Int {
            return Message(
                id: messageId,
                roomId: object["room_id"] as? Int ?? -1,
                userId: object["sender_id"] as? Int,
                username: object["sender_username"] as? String,
                displayName: object["sender_username"] as? String,
                content: object["content"] as? String ?? "",
                messageType: object["content_type"] as? String ?? "text",
                fileUrl: object["file_url"] as? String,
                fileName: object["file_name"] as? String,
                status: "sent",
                createdAt: object["created_at"] as? String ?? ISO8601DateFormatter().string(from: Date())
            )
        }
        guard let data = try? JSONSerialization.data(withJSONObject: object) else { return nil }
        return try? JSONDecoder().decode(Message.self, from: data)
    }

    private func isMessageFromCurrentUser(_ message: Message) -> Bool {
        if message.id < 0 { return true }
        guard let currentUser = TokenManager.shared.currentUser else { return false }
        if message.userId == currentUser.id { return true }
        if message.username == currentUser.username { return true }
        if let displayName = message.displayName,
           let currentDisplayName = currentUser.displayName,
           displayName == currentDisplayName {
            return true
        }
        return false
    }
}
