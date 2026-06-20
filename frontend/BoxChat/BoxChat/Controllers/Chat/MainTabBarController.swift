import AVKit
import UIKit
import UniformTypeIdentifiers

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarAppearance()
        setupViewControllers()
    }
    
    private func setupTabBarAppearance() {
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .systemGray
        
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    private func setupViewControllers() {
        let chatListVC = RoomListViewController()
        let chatNav = UINavigationController(rootViewController: chatListVC)
        chatNav.tabBarItem = UITabBarItem(
            title: "Chats",
            image: UIImage.boxChatIcon(.chats),
            selectedImage: UIImage.boxChatIcon(.chats)
        )
        
        let friendsVC = FriendsViewController()
        let friendsNav = UINavigationController(rootViewController: friendsVC)
        friendsNav.tabBarItem = UITabBarItem(
            title: "Danh bạ",
            image: UIImage.boxChatIcon(.friends),
            selectedImage: UIImage.boxChatIcon(.friends)
        )
        
        let exploreVC = ExploreViewController()
        let exploreNav = UINavigationController(rootViewController: exploreVC)
        exploreNav.tabBarItem = UITabBarItem(
            title: "Khám phá",
            image: UIImage.boxChatIcon(.explore),
            selectedImage: UIImage.boxChatIcon(.explore)
        )
        
        let notificationVC = NotificationsViewController()
        let notificationNav = UINavigationController(rootViewController: notificationVC)
        notificationNav.tabBarItem = UITabBarItem(
            title: "Thông báo",
            image: UIImage.boxChatIcon(.notifications),
            selectedImage: UIImage.boxChatIcon(.notifications)
        )
        
        let profileVC = UserProfileViewController()
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: "Cá nhân",
            image: UIImage.boxChatIcon(.profile),
            selectedImage: UIImage.boxChatIcon(.profile)
        )
        
        viewControllers = [chatNav, friendsNav, exploreNav, notificationNav, profileNav]
    }
}

final class ExploreViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()
    private var posts: [FeedPostModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Khám phá"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(composePost)
        )
        setupTable()
        setupEmptyState()
        WebSocketService.shared.addDelegate(self)
        WebSocketService.shared.connect()
        reloadFeed()
    }

    deinit {
        WebSocketService.shared.removeDelegate(self)
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FeedPostCell.self, forCellReuseIdentifier: FeedPostCell.identifier)
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupEmptyState() {
        emptyLabel.text = "Chưa có bài đăng nào từ bạn bè."
        emptyLabel.font = .systemFont(ofSize: 15, weight: .medium)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
        ])
    }

    private func reloadFeed() {
        NetworkManager.shared.fetchFeed { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let posts) = result {
                    self?.posts = posts
                }
                self?.emptyLabel.isHidden = !(self?.posts.isEmpty ?? true)
                self?.tableView.reloadData()
            }
        }
    }

    @objc private func composePost() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Đăng trạng thái", style: .default) { [weak self] _ in
            self?.showTextComposer()
        })
        sheet.addAction(UIAlertAction(title: "Đăng ảnh", style: .default) { [weak self] _ in
            self?.openMediaPicker(kind: .image)
        })
        sheet.addAction(UIAlertAction(title: "Đăng video", style: .default) { [weak self] _ in
            self?.openMediaPicker(kind: .movie)
        })
        sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        present(sheet, animated: true)
    }

    private func showTextComposer(fileData: Data? = nil, fileName: String? = nil, mimeType: String = "application/octet-stream") {
        let alert = UIAlertController(title: "Bài đăng mới", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Bạn đang nghĩ gì?"
        }
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Đăng", style: .default) { [weak self] _ in
            let text = alert.textFields?.first?.text ?? ""
            self?.createPost(content: text, fileData: fileData, fileName: fileName, mimeType: mimeType)
        })
        present(alert, animated: true)
    }

    private func createPost(content: String, fileData: Data?, fileName: String?, mimeType: String) {
        NetworkManager.shared.createFeedPost(
            content: content,
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let post):
                    self?.posts.insert(post, at: 0)
                    self?.emptyLabel.isHidden = true
                    self?.tableView.reloadData()
                case .failure(let error):
                    self?.showError(error)
                }
            }
        }
    }

    private func openMediaPicker(kind: UTType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kind.identifier]
        picker.videoQuality = .typeMedium
        present(picker, animated: true)
    }

    private func showReactionSheet(post: FeedPostModel) {
        let picker = EmojiPickerViewController()
        picker.onSelect = { [weak self] reaction in
            NetworkManager.shared.reactFeedPost(postId: post.id, reaction: reaction) { result in
                DispatchQueue.main.async {
                    if case .success(let updated) = result {
                        self?.replacePost(updated)
                    }
                }
            }
        }
        let nav = UINavigationController(rootViewController: picker)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func replacePost(_ post: FeedPostModel) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = post
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "Không thực hiện được", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ExploreViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FeedPostCell.identifier, for: indexPath) as! FeedPostCell
        let post = posts[indexPath.row]
        cell.configure(with: post)
        cell.onReact = { [weak self] in
            guard let self else { return }
            self.showReactionSheet(post: self.posts.first(where: { $0.id == post.id }) ?? post)
        }
        cell.onComment = { [weak self] in
            let vc = FeedCommentsViewController(post: self?.posts.first(where: { $0.id == post.id }) ?? post)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        guard post.mediaType == "video", let url = Constants.mediaURL(from: post.mediaUrl) else { return }
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        present(controller, animated: true) { player.play() }
    }
}

extension ExploreViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        if let url = info[.mediaURL] as? URL, let data = try? Data(contentsOf: url) {
            showTextComposer(
                fileData: data,
                fileName: "feed_video_\(Int(Date().timeIntervalSince1970)).mov",
                mimeType: "video/quicktime")
            return
        }
        guard let image = info[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.78) else { return }
        showTextComposer(
            fileData: data,
            fileName: "feed_image_\(Int(Date().timeIntervalSince1970)).jpg",
            mimeType: "image/jpeg")
    }
}

extension ExploreViewController: WebSocketServiceDelegate {
    func webSocketDidConnect() {}
    func webSocketDidDisconnect(error: Error?) {}
    func webSocketDidReceiveEvent(type: String, payload: [String: Any]) {
        guard type == "feed_post" else { return }
        reloadFeed()
    }
}

private final class FeedPostCell: UITableViewCell {
    static let identifier = "FeedPostCell"

    var onReact: (() -> Void)?
    var onComment: (() -> Void)?

    private let card = UIView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let contentLabel = UILabel()
    private let mediaImageView = UIImageView()
    private let videoBadge = UILabel()
    private let statsLabel = UILabel()
    private let reactButton = AnimatedIconButton(icon: .reaction, title: "Cảm xúc")
    private let commentButton = AnimatedIconButton(icon: .comment, title: "Bình luận")
    private var imageTask: URLSessionDataTask?
    private var mediaHeightConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        mediaImageView.image = nil
        onReact = nil
        onComment = nil
    }

    private func setup() {
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        timeLabel.font = .systemFont(ofSize: 12, weight: .medium)
        timeLabel.textColor = .secondaryLabel
        contentLabel.font = .systemFont(ofSize: 15)
        contentLabel.numberOfLines = 0

        mediaImageView.contentMode = .scaleAspectFill
        mediaImageView.clipsToBounds = true
        mediaImageView.layer.cornerRadius = 8
        mediaImageView.backgroundColor = .tertiarySystemGroupedBackground

        videoBadge.text = "▶ Video"
        videoBadge.font = .systemFont(ofSize: 13, weight: .semibold)
        videoBadge.textColor = .white
        videoBadge.textAlignment = .center
        videoBadge.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        videoBadge.layer.cornerRadius = 14
        videoBadge.clipsToBounds = true

        statsLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statsLabel.textColor = .secondaryLabel
        reactButton.addTarget(self, action: #selector(didTapReact), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(didTapComment), for: .touchUpInside)

        [nameLabel, timeLabel, contentLabel, mediaImageView, videoBadge, statsLabel, reactButton, commentButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }

        mediaHeightConstraint = mediaImageView.heightAnchor.constraint(equalToConstant: 220)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            timeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            contentLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 10),
            contentLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            mediaImageView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 10),
            mediaImageView.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            mediaImageView.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            mediaHeightConstraint!,

            videoBadge.centerXAnchor.constraint(equalTo: mediaImageView.centerXAnchor),
            videoBadge.centerYAnchor.constraint(equalTo: mediaImageView.centerYAnchor),
            videoBadge.widthAnchor.constraint(equalToConstant: 90),
            videoBadge.heightAnchor.constraint(equalToConstant: 32),

            statsLabel.topAnchor.constraint(equalTo: mediaImageView.bottomAnchor, constant: 10),
            statsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statsLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            reactButton.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 4),
            reactButton.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            reactButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),

            commentButton.centerYAnchor.constraint(equalTo: reactButton.centerYAnchor),
            commentButton.leadingAnchor.constraint(equalTo: reactButton.trailingAnchor, constant: 22),
        ])
    }

    func configure(with post: FeedPostModel) {
        nameLabel.text = post.user.displayName ?? post.user.username
        timeLabel.text = post.createdAt
        contentLabel.text = post.content?.isEmpty == false ? post.content : " "
        statsLabel.text = "\(post.reactionCount) cảm xúc · \(post.commentCount) bình luận"
        reactButton.setTitle((post.myReaction ?? "Cảm xúc"), for: .normal)
        let hasMedia = post.mediaUrl != nil
        mediaImageView.isHidden = !hasMedia
        mediaHeightConstraint?.constant = hasMedia ? 220 : 0
        videoBadge.isHidden = post.mediaType != "video"
        if post.mediaType == "image", let url = Constants.mediaURL(from: post.mediaUrl) {
            imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async { self?.mediaImageView.image = image }
            }
            imageTask?.resume()
        } else if post.mediaType == "video" {
            mediaImageView.image = UIImage(systemName: "play.rectangle.fill")
            mediaImageView.tintColor = .systemBlue
            mediaImageView.contentMode = .center
        }
    }

    @objc private func didTapReact() { onReact?() }
    @objc private func didTapComment() { onComment?() }
}

private final class FeedCommentsViewController: UIViewController {
    private let post: FeedPostModel
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var comments: [FeedCommentModel] = []

    init(post: FeedPostModel) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bình luận"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.bubble"),
            style: .plain,
            target: self,
            action: #selector(addComment)
        )
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        reloadComments()
    }

    private func reloadComments() {
        NetworkManager.shared.fetchFeedComments(postId: post.id) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let comments) = result {
                    self?.comments = comments
                    self?.tableView.reloadData()
                }
            }
        }
    }

    @objc private func addComment() {
        let alert = UIAlertController(title: "Bình luận", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Viết bình luận..." }
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Gửi", style: .default) { [weak self] _ in
            guard let self, let text = alert.textFields?.first?.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            NetworkManager.shared.addFeedComment(postId: self.post.id, content: text) { result in
                DispatchQueue.main.async {
                    if case .success(let comment) = result {
                        self.comments.append(comment)
                        self.tableView.reloadData()
                    }
                }
            }
        })
        present(alert, animated: true)
    }
}

extension FeedCommentsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let comment = comments[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.image = UIImage(systemName: "bubble.left.fill")
        config.text = comment.user.displayName ?? comment.user.username
        config.secondaryText = comment.content
        cell.contentConfiguration = config
        return cell
    }
}

final class NotificationsViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var items: [AppNotificationItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Thông báo"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Xóa", style: .plain, target: self, action: #selector(clearNotifications))
        setupTable()
        loadItems()
        WebSocketService.shared.addDelegate(self)
        WebSocketService.shared.connect()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppNotification(_:)),
            name: .didReceiveAppNotification,
            object: nil)
    }

    deinit {
        WebSocketService.shared.removeDelegate(self)
        NotificationCenter.default.removeObserver(self)
    }

    private func setupTable() {
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

    private func loadItems() {
        items = AppNotificationService.shared.storedItems()
        tableView.reloadData()
    }

    private func saveItems() {
        loadItems()
    }

    @objc private func clearNotifications() {
        items.removeAll()
        AppNotificationService.shared.clear()
        tableView.reloadData()
    }

    @objc private func handleAppNotification(_ notification: Notification) {
        guard let item = notification.object as? AppNotificationItem else {
            loadItems()
            return
        }
        guard !items.contains(where: { $0.id == item.id }) else { return }
        items.insert(item, at: 0)
        items = Array(items.prefix(150))
        tableView.reloadData()
    }
}

extension NotificationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = items[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.image = UIImage(systemName: iconName(for: item))
        config.text = item.title
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd/MM"
        config.secondaryText = "\(item.body) · \(formatter.string(from: item.date))"
        cell.contentConfiguration = config
        return cell
    }

    private func iconName(for item: AppNotificationItem) -> String {
        switch item.type {
        case "friend_request": return "person.badge.plus"
        case "friend_accepted": return "person.2.fill"
        case "friend_rejected": return "person.crop.circle.badge.xmark"
        case "friend_removed": return "person.crop.circle.badge.minus"
        case "feed_post": return "sparkles"
        case "feed_comment": return "text.bubble.fill"
        case "feed_reaction": return "heart.fill"
        case "call_event": return "phone.badge.waveform"
        case "new_message", "message_sent": return "message.badge.filled.fill"
        default: return "bell.badge.fill"
        }
    }
}

extension NotificationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        switch item.type {
        case "friend_request":
            tabBarController?.selectedIndex = 1
        case "feed_post", "feed_comment", "feed_reaction":
            tabBarController?.selectedIndex = 2
        case "new_message", "message_sent":
            tabBarController?.selectedIndex = 0
        default:
            break
        }
    }
}

extension NotificationsViewController: WebSocketServiceDelegate {
    func webSocketDidConnect() {}
    func webSocketDidDisconnect(error: Error?) {}
    func webSocketDidReceiveEvent(type: String, payload: [String: Any]) {
        loadItems()
    }
}
