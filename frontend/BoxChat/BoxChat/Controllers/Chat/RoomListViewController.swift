import UIKit

class RoomListViewController: UIViewController {
    
    private let headerContainer = UIView()
    private let searchBar: UISearchBar = {
        let search = UISearchBar()
        search.placeholder = "Tìm kiếm"
        search.searchBarStyle = .minimal
        return search
    }()
    
    private let filterScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()
    
    private let filterStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()
    
    private let tableView = UITableView()
    private var rooms: [Room] = []
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupNavBar()
        setupHeader()
        setupTableView()
        fetchRooms()
        
        WebSocketService.shared.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(handleLogoutRequired), name: .didLogoutRequired, object: nil)
    }
    
    private func setupNavBar() {
        let titleLabel = UILabel()
        titleLabel.text = "BoxChat"
        titleLabel.font = .systemFont(ofSize: 28, weight: .heavy)
        titleLabel.textColor = .label
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
        
        let addImg = UIImage(systemName: "plus.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .bold))
        let addButton = UIBarButtonItem(image: addImg, style: .plain, target: self, action: #selector(didTapAddRoom))
        addButton.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func setupHeader() {
        view.addSubview(headerContainer)
        headerContainer.addSubview(searchBar)
        headerContainer.addSubview(filterScrollView)
        filterScrollView.addSubview(filterStackView)
        
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        filterScrollView.translatesAutoresizingMaskIntoConstraints = false
        filterStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let filters = ["Tất cả", "Chưa đọc", "Nhóm", "Bạn bè"]
        for (index, title) in filters.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            button.layer.cornerRadius = 18
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            
            if index == 0 {
                button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
                button.setTitleColor(.systemBlue, for: .normal)
            } else {
                button.backgroundColor = .systemGray6
                button.setTitleColor(.secondaryLabel, for: .normal)
            }
            filterStackView.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            searchBar.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -8),
            
            filterScrollView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            filterScrollView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            filterScrollView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            filterScrollView.heightAnchor.constraint(equalToConstant: 44),
            filterScrollView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -8),
            
            filterStackView.topAnchor.constraint(equalTo: filterScrollView.topAnchor),
            filterStackView.bottomAnchor.constraint(equalTo: filterScrollView.bottomAnchor),
            filterStackView.leadingAnchor.constraint(equalTo: filterScrollView.leadingAnchor, constant: 16),
            filterStackView.trailingAnchor.constraint(equalTo: filterScrollView.trailingAnchor, constant: -16),
            filterStackView.heightAnchor.constraint(equalTo: filterScrollView.heightAnchor)
        ])
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RoomCell.self, forCellReuseIdentifier: RoomCell.identifier)
        
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc private func fetchRooms() {
        NetworkManager.shared.fetchRooms { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                
                if case .success(let response) = result {
                    self?.rooms = response.items
                    self?.tableView.reloadData()
                    
                    for room in response.items {
                        if let last = room.lastMessage {
                            WebSocketService.shared.localLastMessageIds[room.id] = last.id
                        }
                    }
                }
            }
        }
    }
    
    @objc private func handleRefresh() {
        fetchRooms()
    }
    
    @objc private func didTapAddRoom() {
        let actionSheetVC = CreateRoomViewController()
        
        actionSheetVC.onDataChanged = { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.fetchRooms()
            }
        }
        
        if let sheet = actionSheetVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 30
        }
        
        present(actionSheetVC, animated: true)
    }
    
    private func performLogout() {
        WebSocketService.shared.disconnect()
        TokenManager.shared.clear()
        
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let sceneDelegate = windowScene.delegate as? SceneDelegate,
                  let window = sceneDelegate.window else { return }
            
            let loginVC = LoginViewController()
            window.rootViewController = loginVC
            
            UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
    
    @objc private func handleLogoutRequired() {
        DispatchQueue.main.async { self.performLogout() }
    }
}

extension RoomListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }
    
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
    func webSocketDidConnect() {}
    func webSocketDidDisconnect(error: Error?) {}
    
    func webSocketDidReceiveEvent(type: String, payload: [String: Any]) {
        if type == "unread_update",
           let roomId = payload["room_id"] as? Int,
           let unread = payload["unread_count"] as? Int,
           let idx = rooms.firstIndex(where: { $0.id == roomId }) {
            
            rooms[idx].unreadCount = unread
            tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .none)
        }
    }
}
