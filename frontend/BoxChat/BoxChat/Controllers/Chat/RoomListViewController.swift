import UIKit

final class RoomListViewController: UIViewController {
    private enum Filter: String, CaseIterable {
        case all = "Tất cả"
        case unread = "Chưa đọc"
        case groups = "Nhóm"
        case friends = "Bạn bè"
    }
    
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    private let tableView = UITableView()
    private var rooms: [Room] = []
    
    // Thêm một UIRefreshControl để người dùng có thể vuốt màn hình từ trên xuống để làm mới danh sách
=======
=======
>>>>>>> Stashed changes
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let searchContainer = UIView()
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let searchTextField = UITextField()
    private let filterStackView = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .plain)
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    private let refreshControl = UIRefreshControl()
    
    private var allRooms: [Room] = []
    private var rooms: [Room] = []
    private var selectedFilter: Filter = .all
    
    override func viewDidLoad() {
        super.viewDidLoad()
<<<<<<< Updated upstream
<<<<<<< Updated upstream
        title = "Tin Nhắn"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground
        
=======
=======
>>>>>>> Stashed changes
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupHeader()
>>>>>>> Stashed changes
        setupTableView()
        setupNavBar()
        fetchRooms()
        
        WebSocketService.shared.delegate = self
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleLogoutRequired), name: .didLogoutRequired, object: nil)
    }
    
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
=======
>>>>>>> Stashed changes
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyFilters(animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupHeader() {
        titleLabel.text = "BoxChat"
        titleLabel.font = .systemFont(ofSize: 32, weight: .heavy)
        titleLabel.textColor = .label
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
        
        Filter.allCases.forEach { filter in
            let button = makeFilterButton(filter)
            filterStackView.addArrangedSubview(button)
        }
        
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
            searchTextField.trailingAnchor.constraint(
                equalTo: searchContainer.trailingAnchor, constant: -12),
            searchTextField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            
            filterStackView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 14),
            filterStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            filterStackView.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            filterStackView.heightAnchor.constraint(equalToConstant: 38),
        ])
    }
    
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
<<<<<<< Updated upstream
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
=======
            tableView.topAnchor.constraint(equalTo: filterStackView.bottomAnchor, constant: 8),
>>>>>>> Stashed changes
=======
            tableView.topAnchor.constraint(equalTo: filterStackView.bottomAnchor, constant: 8),
>>>>>>> Stashed changes
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    private func setupNavBar() {
        
        let addImg = UIImage(systemName: "plus.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .bold))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: addImg, style: .plain, target: self, action: #selector(didTapAddRoom))
=======
=======
>>>>>>> Stashed changes
    private func brandTitle() -> NSAttributedString {
        let text = NSMutableAttributedString(
            string: "Box",
            attributes: [
                .font: UIFont.systemFont(ofSize: 32, weight: .heavy),
                .foregroundColor: UIColor.label,
            ]
        )
        text.append(
            NSAttributedString(
                string: "Chat",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 32, weight: .heavy),
                    .foregroundColor: UIColor.systemBlue,
                ]
            ))
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
        button.backgroundColor =
        selected ? UIColor.systemBlue.withAlphaComponent(0.13) : .secondarySystemBackground
        button.setTitleColor(selected ? .systemBlue : .secondaryLabel, for: .normal)
        button.layer.borderWidth = selected ? 0 : 1
        button.layer.borderColor = UIColor.separator.withAlphaComponent(0.28).cgColor
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    }
    
    @objc private func fetchRooms() {
        NetworkManager.shared.fetchRooms { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.refreshControl.endRefreshing()
                if case .success(let response) = result {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
                    print("📊 [Debug] Đã lấy thành công \(response.items.count) phòng từ Server Database.")
                    
                    self?.rooms = response.items
                    self?.tableView.reloadData()
                    
                    // Cập nhật ID tin nhắn cuối cùng cho WebSocket bám sát trạng thái
                    for room in response.items {
                        if let last = room.lastMessage {
                            WebSocketService.shared.localLastMessageIds[room.id] = last.id
                        }
                    }
                } else if case .failure(let error) = result {
                    print("❌ [Lỗi Fetch Rooms]: \(error.localizedDescription)")
=======
                    self.allRooms = response.items
                    response.items.compactMap { $0.lastMessage }.forEach {
                        WebSocketService.shared.localLastMessageIds[$0.roomId] = $0.id
                    }
                    self.applyFilters(animated: true)
                } else if case .failure(let error) = result {
                    self.showAlert(title: "Không tải được phòng", message: error.localizedDescription)
>>>>>>> Stashed changes
=======
                    self.allRooms = response.items
                    response.items.compactMap { $0.lastMessage }.forEach {
                        WebSocketService.shared.localLastMessageIds[$0.roomId] = $0.id
                    }
                    self.applyFilters(animated: true)
                } else if case .failure(let error) = result {
                    self.showAlert(title: "Không tải được phòng", message: error.localizedDescription)
>>>>>>> Stashed changes
                }
            }
        }
    }
    
    @objc private func handleRefresh() {
        fetchRooms()
    }
    
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    // Gọi Custom Sheet Kính mờ đồng bộ giao diện Đăng Nhập
=======
=======
>>>>>>> Stashed changes
    @objc private func searchDidChange() {
        applyFilters(animated: true)
    }
    
    @objc private func didTapFilter(_ sender: UIButton) {
        selectedFilter = Filter.allCases[sender.tag]
        filterStackView.arrangedSubviews.compactMap { $0 as? UIButton }.forEach { button in
            styleFilterButton(button, selected: button.tag == sender.tag)
        }
        UIView.animate(withDuration: 0.18) {
            sender.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
        } completion: { _ in
            UIView.animate(withDuration: 0.18) { sender.transform = .identity }
        }
        applyFilters(animated: true)
    }
    
    private func applyFilters(animated: Bool) {
        let query =
        searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        rooms = allRooms.filter { room in
            let matchesSearch = query.isEmpty || room.name.lowercased().contains(query)
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .unread:
                matchesFilter = room.unreadCount > 0
            case .groups:
                matchesFilter = room.memberCount > 1
            case .friends:
                matchesFilter = room.memberCount <= 1
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
            UIView.animate(
                withDuration: 0.36,
                delay: Double(index) * 0.035,
                usingSpringWithDamping: 0.86,
                initialSpringVelocity: 0.35,
                options: [.curveEaseOut]
            ) {
                cell.alpha = 1
                cell.transform = .identity
            }
        }
    }
    
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    @objc private func didTapAddRoom() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(
            UIAlertAction(title: "Tạo nhóm mới", style: .default) { [weak self] _ in
                self?.openCreateGroup()
            })
        sheet.addAction(
            UIAlertAction(title: "Nhập mã mời", style: .default) { [weak self] _ in
                self?.showJoinRoomPrompt()
            })
        sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        
<<<<<<< Updated upstream
<<<<<<< Updated upstream
        // Lắng nghe sự kiện lưu dữ liệu thành công để reload lại danh sách phòng
        actionSheetVC.onDataChanged = { [weak self] in
=======
=======
>>>>>>> Stashed changes
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = addButton
            popover.sourceRect = addButton.bounds
        }
        present(sheet, animated: true)
    }
    
    private func openCreateGroup() {
        let createVC = CreateGroupViewController()
        createVC.onDataChanged = { [weak self] in
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.fetchRooms()
            }
        }
<<<<<<< Updated upstream
<<<<<<< Updated upstream
        
        // Cấu hình hiển thị dạng Bottom Sheet nửa màn hình cao cấp giống Apple, Telegram
        if let sheet = actionSheetVC.sheetPresentationController {
            sheet.detents = [.medium()] // Chỉ mở nửa màn hình
            sheet.prefersGrabberVisible = true // Thêm thanh gờ nhỏ ở đầu để vuốt đóng xuống dễ dàng
            sheet.preferredCornerRadius = 30 // Bo góc đồng bộ với thẻ kính
=======
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
=======
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func showJoinRoomPrompt() {
        let alert = UIAlertController(
            title: "Nhập mã mời",
            message: "Dán mã mời của nhóm chat để tham gia.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Ví dụ: ABC123"
            textField.autocapitalizationType = .allCharacters
            textField.autocorrectionType = .no
            textField.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(
            UIAlertAction(title: "Tham gia", style: .default) { [weak self, weak alert] _ in
                guard let self else { return }
                let code =
                alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                self.joinRoom(inviteCode: code)
            })
        present(alert, animated: true)
    }
    
    private func joinRoom(inviteCode: String) {
        guard !inviteCode.isEmpty else {
            showAlert(title: "Thiếu mã mời", message: "Bạn cần nhập mã mời để tham gia nhóm.")
            return
        }
        
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
>>>>>>> Stashed changes
    }
    
    private func showJoinRoomPrompt() {
        let alert = UIAlertController(
            title: "Nhập mã mời",
            message: "Dán mã mời của nhóm chat để tham gia.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Ví dụ: ABC123"
            textField.autocapitalizationType = .allCharacters
            textField.autocorrectionType = .no
            textField.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(
            UIAlertAction(title: "Tham gia", style: .default) { [weak self, weak alert] _ in
                guard let self else { return }
                let code =
                alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                self.joinRoom(inviteCode: code)
            })
        present(alert, animated: true)
    }
    
    private func joinRoom(inviteCode: String) {
        guard !inviteCode.isEmpty else {
            showAlert(title: "Thiếu mã mời", message: "Bạn cần nhập mã mời để tham gia nhóm.")
            return
>>>>>>> Stashed changes
        }
        
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
    
    // --- XỬ LÝ ĐĂNG XUẤT NGẦM (Giữ lại xử lý logic khi server yêu cầu logout) ---
    private func performLogout() {
        WebSocketService.shared.disconnect()
        TokenManager.shared.clear()
        
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let sceneDelegate = windowScene.delegate as? SceneDelegate,
                  let window = sceneDelegate.window
            else { return }
            window.rootViewController = LoginViewController()
            UIView.transition(
                with: window,
                duration: 0.4,
                options: .transitionCrossDissolve,
                animations: nil,
                completion: nil
            )
        }
    }
    
    @objc private func handleLogoutRequired() {
        performLogout()
    }
}

// MARK: - UITableView DataSource & Delegate
extension RoomListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
        tableView.dequeueReusableCell(withIdentifier: RoomCell.identifier, for: indexPath)
        as! RoomCell
        cell.configure(with: rooms[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chatVC = ChatRoomViewController(room: rooms[indexPath.row])
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

// MARK: - WebSocketServiceDelegate
extension RoomListViewController: WebSocketServiceDelegate {
    func webSocketDidConnect() {}
    func webSocketDidDisconnect(error: Error?) {}
    
    func webSocketDidReceiveEvent(type: String, payload: [String: Any]) {
        if type == "unread_update",
           let roomId = payload["room_id"] as? Int,
           let unread = payload["unread_count"] as? Int,
           let index = allRooms.firstIndex(where: { $0.id == roomId })
        {
            allRooms[index].unreadCount = unread
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
        }
    }
}
