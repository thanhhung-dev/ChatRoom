import AVKit
import PhotosUI
import UIKit
import UniformTypeIdentifiers

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarAppearance()
        setupViewControllers()
    }

    private func setupTabBarAppearance() {
        tabBar.tintColor = BCTheme.Colors.primary
        tabBar.unselectedItemTintColor = BCTheme.Colors.textTertiary

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

fileprivate struct FeedDraftImage {
    let image: UIImage
    let data: Data
    let fileName: String
    let mimeType: String

    var uploadItem: NetworkManager.UploadMediaItem {
        NetworkManager.UploadMediaItem(data: data, fileName: fileName, mimeType: mimeType)
    }
}

fileprivate extension UIImage {
    func feedUploadPrepared(maxPixel: CGFloat = 2048, quality: CGFloat = 0.78) -> (image: UIImage, data: Data)? {
        let longestSide = max(size.width, size.height)
        let scale = longestSide > maxPixel ? maxPixel / longestSide : 1
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let normalized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard let data = normalized.jpegData(compressionQuality: quality) else { return nil }
        return (normalized, data)
    }
}

final class ExploreViewController: UIViewController {
    private enum MediaPickTarget {
        case postImage
        case postVideo
        case commentImage(postId: Int)
    }

    private let composerView = UIView()
    private let composerAvatar = UIImageView()
    private let promptButton = UIButton(type: .system)
    private let photoButton = UIButton(type: .system)
    private let videoButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private var posts: [FeedPostModel] = []
    private var expandedCommentPostId: Int?
    private var pendingCommentImages: [Int: (data: Data, fileName: String, mimeType: String)] = [:]
    private var mediaPickTarget: MediaPickTarget?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        navigationController?.navigationBar.prefersLargeTitles = false
        view.backgroundColor = BCTheme.Colors.backgroundGrouped
        setupComposer()
        setupTable()
        installTapToDismissKeyboard()
        setupEmptyState()
        WebSocketService.shared.addDelegate(self)
        WebSocketService.shared.connect()
        reloadFeed()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateComposerHeaderLayout()
    }

    deinit {
        WebSocketService.shared.removeDelegate(self)
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FeedPostCell.self, forCellReuseIdentifier: FeedPostCell.identifier)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.backgroundColor = BCTheme.Colors.backgroundGrouped
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 360
        tableView.tableHeaderView = composerView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        updateComposerHeaderLayout()
    }

    private func setupComposer() {
        composerView.backgroundColor = BCTheme.Colors.surface
        composerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 132)

        composerAvatar.image = UIImage(systemName: "person.crop.circle.fill")
        composerAvatar.tintColor = BCTheme.Colors.textTertiary
        composerAvatar.contentMode = .scaleAspectFill
        composerAvatar.layer.cornerRadius = 22
        composerAvatar.clipsToBounds = true

        if let url = Constants.mediaURL(from: TokenManager.shared.currentUser?.avatarUrl) {
            ImageCache.shared.loadInto(composerAvatar, from: url)
        }

        promptButton.setTitle("Hôm nay bạn thế nào?", for: .normal)
        promptButton.setTitleColor(BCTheme.Colors.textSecondary, for: .normal)
        promptButton.titleLabel?.font = BCTheme.Typography.bodyBold
        promptButton.contentHorizontalAlignment = .left
        promptButton.addTarget(self, action: #selector(didTapPrompt), for: .touchUpInside)

        configureComposerButton(photoButton, title: "Ảnh", icon: "photo.fill", color: .systemGreen)
        configureComposerButton(videoButton, title: "Video", icon: "video.fill", color: .systemPink)
        photoButton.addTarget(self, action: #selector(didTapPhoto), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(didTapVideo), for: .touchUpInside)

        let topLine = UIStackView(arrangedSubviews: [composerAvatar, promptButton])
        topLine.axis = .horizontal
        topLine.alignment = .center
        topLine.spacing = 12

        let actionLine = UIStackView(arrangedSubviews: [photoButton, videoButton])
        actionLine.axis = .horizontal
        actionLine.spacing = 14
        actionLine.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [topLine, actionLine])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        composerView.addSubview(stack)
        composerAvatar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: composerView.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: composerView.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: composerView.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: composerView.bottomAnchor, constant: -14),

            composerAvatar.widthAnchor.constraint(equalToConstant: 44),
            composerAvatar.heightAnchor.constraint(equalToConstant: 44),
            photoButton.heightAnchor.constraint(equalToConstant: 42),
        ])
    }

    private func updateComposerHeaderLayout() {
        guard tableView.tableHeaderView === composerView else { return }
        let width = tableView.bounds.width > 0 ? tableView.bounds.width : view.bounds.width
        let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let size = composerView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        guard composerView.frame.width != width || abs(composerView.frame.height - size.height) > 0.5 else { return }
        composerView.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
        tableView.tableHeaderView = composerView
    }

    private func configureComposerButton(_ button: UIButton, title: String, icon: String, color: UIColor) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 6
        config.baseForegroundColor = BCTheme.Colors.textPrimary
        config.baseBackgroundColor = BCTheme.Colors.surfaceElevated
        config.background.backgroundColor = BCTheme.Colors.surfaceElevated
        config.cornerStyle = .capsule
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = BCTheme.Typography.bodyBold
            return out
        }
        button.configuration = config
        button.tintColor = color
    }

    private func setupEmptyState() {
        emptyLabel.text = "Chưa có bài đăng nào từ bạn bè."
        emptyLabel.font = BCTheme.Typography.bodyBold
        emptyLabel.textColor = BCTheme.Colors.textSecondary
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

    @objc private func didTapPrompt() {
        view.endEditing(true)
        showTextComposer()
    }
    @objc private func didTapPhoto() {
        view.endEditing(true)
        openMultiImagePicker()
    }

    @objc private func didTapVideo() {
        view.endEditing(true)
        mediaPickTarget = .postVideo
        openMediaPicker(kind: .movie)
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

    private func createPost(content: String, images: [FeedDraftImage]) {
        NetworkManager.shared.createFeedPost(
            content: content,
            mediaItems: images.map(\.uploadItem)
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

    private func openMultiImagePicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 12
        configuration.selection = .ordered
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func showImagePostComposer(images: [FeedDraftImage]) {
        let controller = FeedImageComposerViewController(images: images)
        controller.onPost = { [weak self, weak controller] content, selectedImages in
            controller?.dismiss(animated: true)
            self?.createPost(content: content, images: selectedImages)
        }
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }

    private func openMediaPicker(kind: UTType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kind.identifier]
        picker.videoQuality = .typeMedium
        present(picker, animated: true)
    }

    private func likePost(_ post: FeedPostModel) {
        NetworkManager.shared.reactFeedPost(postId: post.id, reaction: "❤️") { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updated):
                    self?.replacePost(updated)
                case .failure(let error):
                    self?.showError(error)
                }
            }
        }
    }

    private func toggleCommentComposer(for post: FeedPostModel) {
        expandedCommentPostId = expandedCommentPostId == post.id ? nil : post.id
        tableView.reloadData()
    }

    private func pickCommentImage(for post: FeedPostModel) {
        mediaPickTarget = .commentImage(postId: post.id)
        openMediaPicker(kind: .image)
    }

    private func sendComment(for post: FeedPostModel, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let pendingImage = pendingCommentImages[post.id]
        guard !trimmed.isEmpty || pendingImage != nil else { return }

        NetworkManager.shared.addFeedComment(
            postId: post.id,
            content: trimmed,
            fileData: pendingImage?.data,
            fileName: pendingImage?.fileName,
            mimeType: pendingImage?.mimeType ?? "application/octet-stream"
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.pendingCommentImages[post.id] = nil
                    self.expandedCommentPostId = nil
                    self.reloadFeed()
                case .failure(let error):
                    self.showError(error)
                }
            }
        }
    }

    private func replacePost(_ post: FeedPostModel) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = post
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }

    private func showOwnerMenu(for post: FeedPostModel) {
        guard post.user.id == TokenManager.shared.currentUser?.id else { return }
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Sửa bài đăng", style: .default) { [weak self] _ in
            self?.showEditPost(post)
        })
        sheet.addAction(UIAlertAction(title: "Xóa bài đăng", style: .destructive) { [weak self] _ in
            self?.confirmDeletePost(post)
        })
        sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        present(sheet, animated: true)
    }

    private func showEditPost(_ post: FeedPostModel) {
        let alert = UIAlertController(title: "Sửa bài đăng", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Bạn đang nghĩ gì?"
            field.text = post.content
        }
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let text = alert?.textFields?.first?.text ?? ""
            NetworkManager.shared.updateFeedPost(postId: post.id, content: text) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let updated):
                        self.replacePost(updated)
                    case .failure(let error):
                        self.showError(error)
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    private func confirmDeletePost(_ post: FeedPostModel) {
        let alert = UIAlertController(
            title: "Xóa bài đăng?",
            message: "Bài đăng sẽ bị xóa khỏi Khám Phá.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Xóa", style: .destructive) { [weak self] _ in
            self?.deletePost(post)
        })
        present(alert, animated: true)
    }

    private func deletePost(_ post: FeedPostModel) {
        NetworkManager.shared.deleteFeedPost(postId: post.id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.posts.removeAll { $0.id == post.id }
                    self.emptyLabel.isHidden = !self.posts.isEmpty
                    self.tableView.reloadData()
                case .failure(let error):
                    self.showError(error)
                }
            }
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
        cell.configure(
            with: post,
            isCommentExpanded: expandedCommentPostId == post.id,
            hasPendingCommentImage: pendingCommentImages[post.id] != nil
        )
        cell.onMore = { [weak self] in
            self?.showOwnerMenu(for: self?.posts.first(where: { $0.id == post.id }) ?? post)
        }
        cell.onReact = { [weak self] in
            guard let self else { return }
            self.likePost(self.posts.first(where: { $0.id == post.id }) ?? post)
        }
        cell.onComment = { [weak self] in
            let vc = FeedCommentsViewController(post: post)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        cell.onAttachCommentImage = { [weak self] in
            self?.pickCommentImage(for: self?.posts.first(where: { $0.id == post.id }) ?? post)
        }
        cell.onSendComment = { [weak self] text in
            self?.sendComment(for: self?.posts.first(where: { $0.id == post.id }) ?? post, text: text)
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
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        mediaPickTarget = nil
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        if let url = info[.mediaURL] as? URL, let data = try? Data(contentsOf: url) {
            mediaPickTarget = nil
            showTextComposer(
                fileData: data,
                fileName: "feed_video_\(Int(Date().timeIntervalSince1970)).mov",
                mimeType: "video/quicktime")
            return
        }
        guard let image = info[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.78) else { return }
        if case .commentImage(let postId) = mediaPickTarget {
            pendingCommentImages[postId] = (
                data: data,
                fileName: "comment_image_\(Int(Date().timeIntervalSince1970)).jpg",
                mimeType: "image/jpeg"
            )
            mediaPickTarget = nil
            expandedCommentPostId = postId
            tableView.reloadData()
            return
        }
        mediaPickTarget = nil
        showTextComposer(
            fileData: data,
            fileName: "feed_image_\(Int(Date().timeIntervalSince1970)).jpg",
            mimeType: "image/jpeg")
    }
}

extension ExploreViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        var images = Array<FeedDraftImage?>(repeating: nil, count: results.count)
        let group = DispatchGroup()

        for (index, result) in results.enumerated() {
            guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                defer { group.leave() }
                guard let image = object as? UIImage,
                      let prepared = image.feedUploadPrepared() else { return }
                images[index] = FeedDraftImage(
                    image: prepared.image,
                    data: prepared.data,
                    fileName: "feed_image_\(Int(Date().timeIntervalSince1970))_\(index + 1).jpg",
                    mimeType: "image/jpeg"
                )
            }
        }

        group.notify(queue: .main) { [weak self] in
            let selectedImages = images.compactMap { $0 }
            guard !selectedImages.isEmpty else { return }
            self?.showImagePostComposer(images: selectedImages)
        }
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

private final class FeedImageComposerViewController: UIViewController, UITextViewDelegate {
    var onPost: ((String, [FeedDraftImage]) -> Void)?

    private let images: [FeedDraftImage]
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let gridView = UIStackView()
    private let bottomBar = UIView()
    private let postButton = UIButton(type: .system)

    init(images: [FeedDraftImage]) {
        self.images = images
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.10, green: 0.12, blue: 0.13, alpha: 1)
        setupTopBar()
        setupContent()
        setupBottomBar()
        installTapToDismissKeyboard()
    }

    private func setupTopBar() {
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = "Bài viết mới"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        [closeButton, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
        ])
    }

    private func setupContent() {
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        let avatarView = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        avatarView.tintColor = .white.withAlphaComponent(0.55)
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 30
        if let url = Constants.mediaURL(from: TokenManager.shared.currentUser?.avatarUrl) {
            ImageCache.shared.loadInto(avatarView, from: url)
        }

        let nameLabel = UILabel()
        nameLabel.text = TokenManager.shared.currentUser?.displayName ?? TokenManager.shared.currentUser?.username ?? "Bạn"
        nameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        nameLabel.textColor = .white

        let identityStack = UIStackView(arrangedSubviews: [avatarView, nameLabel])
        identityStack.axis = .horizontal
        identityStack.alignment = .center
        identityStack.spacing = 14

        let chips = UIStackView(arrangedSubviews: [
            makeChip(icon: "music.note", title: "Nhạc"),
            makeChip(icon: "person.2.fill", title: "Mọi người"),
            makeChip(icon: "mappin.circle.fill", title: "Vị trí"),
            makeChip(icon: "face.smiling.fill", title: "Cảm xúc/hoạt động"),
        ])
        chips.axis = .horizontal
        chips.spacing = 10
        chips.alignment = .leading

        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.font = .systemFont(ofSize: 24, weight: .regular)
        textView.textContainerInset = .zero
        textView.delegate = self

        placeholderLabel.text = "Bạn đang nghĩ gì?"
        placeholderLabel.textColor = .white.withAlphaComponent(0.45)
        placeholderLabel.font = .systemFont(ofSize: 24, weight: .regular)

        gridView.axis = .vertical
        gridView.spacing = 4
        buildImageGrid()

        [identityStack, chips, textView, placeholderLabel, gridView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -88),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),

            identityStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            identityStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            identityStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),

            chips.topAnchor.constraint(equalTo: identityStack.bottomAnchor, constant: 26),
            chips.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            chips.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),

            textView.topAnchor.constraint(equalTo: chips.bottomAnchor, constant: 32),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 70),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 5),

            gridView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 14),
            gridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
    }

    private func setupBottomBar() {
        bottomBar.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)

        let imageButton = UIButton(type: .system)
        imageButton.setImage(UIImage(systemName: "photo.on.rectangle.angled"), for: .normal)
        imageButton.tintColor = .white

        var config = UIButton.Configuration.filled()
        config.title = "Đăng"
        config.baseBackgroundColor = BCTheme.Colors.primary
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = .systemFont(ofSize: 20, weight: .bold)
            return out
        }
        postButton.configuration = config
        postButton.addTarget(self, action: #selector(didTapPost), for: .touchUpInside)

        [imageButton, postButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            bottomBar.addSubview($0)
        }

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 88),

            imageButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 28),
            imageButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor, constant: -6),
            imageButton.widthAnchor.constraint(equalToConstant: 44),
            imageButton.heightAnchor.constraint(equalToConstant: 44),

            postButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -28),
            postButton.centerYAnchor.constraint(equalTo: imageButton.centerYAnchor),
            postButton.widthAnchor.constraint(equalToConstant: 118),
            postButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    private func makeChip(icon: String, title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: icon)
        config.title = title
        config.imagePadding = 8
        config.baseForegroundColor = .white
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.12)
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 14, bottom: 9, trailing: 14)
        let button = UIButton(configuration: config)
        button.isUserInteractionEnabled = false
        return button
    }

    private func buildImageGrid() {
        let rows = stride(from: 0, to: images.count, by: 2).map { startIndex -> UIStackView in
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 4
            row.distribution = .fillEqually
            for index in startIndex..<min(startIndex + 2, images.count) {
                row.addArrangedSubview(makeImageTile(image: images[index].image, index: index))
            }
            if row.arrangedSubviews.count == 1 {
                row.addArrangedSubview(UIView())
            }
            return row
        }
        rows.forEach { gridView.addArrangedSubview($0) }
    }

    private func makeImageTile(image: UIImage, index: Int) -> UIView {
        let container = UIView()
        container.clipsToBounds = true
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.heightAnchor.constraint(equalTo: container.widthAnchor),
        ])
        return container
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    @objc private func didTapPost() {
        onPost?(textView.text.trimmingCharacters(in: .whitespacesAndNewlines), images)
    }
}

private final class FeedPostCell: UITableViewCell, UITextFieldDelegate {
    static let identifier = "FeedPostCell"

    var onMore: (() -> Void)?
    var onReact: (() -> Void)?
    var onComment: (() -> Void)?
    var onAttachCommentImage: (() -> Void)?
    var onSendComment: ((String) -> Void)?

    private let card = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let moreButton = UIButton(type: .system)
    private let contentLabel = UILabel()
    private let mediaImageView = UIImageView()
    private let videoBadge = UILabel()
    private let actionStack = UIStackView()
    private let reactButton = UIButton(type: .system)
    private let reactionCountButton = UIButton(type: .system)
    private let commentButton = UIButton(type: .system)
    private let commentComposer = UIView()
    private let commentTextField = UITextField()
    private let commentAttachButton = UIButton(type: .system)
    private let commentSendButton = UIButton(type: .system)
    private let pendingImageLabel = UILabel()
    private var imageTask: URLSessionDataTask?
    private var avatarTask: URLSessionDataTask?
    private var mediaHeightConstraint: NSLayoutConstraint?
    private var commentTopConstraint: NSLayoutConstraint?
    private var commentHeightConstraint: NSLayoutConstraint?

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
        avatarTask?.cancel()
        mediaImageView.image = nil
        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        mediaImageView.contentMode = .scaleAspectFill
        moreButton.isHidden = true
        onMore = nil
        onReact = nil
        onComment = nil
        onAttachCommentImage = nil
        onSendComment = nil
        commentTextField.text = nil
        pendingImageLabel.isHidden = true
    }

    private func setup() {
        card.bcCardStyle(cornerRadius: BCTheme.Layout.radiusM)
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.tintColor = BCTheme.Colors.textTertiary
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.clipsToBounds = true

        nameLabel.font = BCTheme.Typography.headline
        nameLabel.textColor = BCTheme.Colors.textPrimary
        timeLabel.font = BCTheme.Typography.subheadline
        timeLabel.textColor = BCTheme.Colors.textSecondary
        contentLabel.font = BCTheme.Typography.body
        contentLabel.textColor = BCTheme.Colors.textPrimary
        contentLabel.numberOfLines = 0

        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = BCTheme.Colors.textSecondary
        moreButton.addTarget(self, action: #selector(didTapMore), for: .touchUpInside)

        mediaImageView.contentMode = .scaleAspectFill
        mediaImageView.clipsToBounds = true
        mediaImageView.layer.cornerRadius = BCTheme.Layout.radiusS
        mediaImageView.backgroundColor = BCTheme.Colors.surfaceElevated

        let playIcon = NSTextAttachment()
        playIcon.image = UIImage(systemName: "play.fill")?.withTintColor(.white)
        videoBadge.attributedText = NSAttributedString(attachment: playIcon)
        videoBadge.textAlignment = .center
        videoBadge.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        videoBadge.layer.cornerRadius = 22
        videoBadge.clipsToBounds = true
        videoBadge.font = .systemFont(ofSize: 22, weight: .bold)
        videoBadge.textColor = .white

        configureActionButton(reactButton, image: "heart", title: "Thích")
        configureActionButton(reactionCountButton, image: nil, title: "❤️ 0")
        configureActionButton(commentButton, image: "text.bubble", title: "0")
        actionStack.axis = .horizontal
        actionStack.spacing = 12
        actionStack.alignment = .center
        actionStack.distribution = .fillProportionally
        reactButton.addTarget(self, action: #selector(didTapReact), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(didTapComment), for: .touchUpInside)

        [reactButton, reactionCountButton, commentButton].forEach {
            actionStack.addArrangedSubview($0)
        }

        setupCommentComposer()

        [avatarImageView, nameLabel, timeLabel, moreButton, contentLabel, mediaImageView, videoBadge, actionStack, commentComposer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }

        mediaHeightConstraint = mediaImageView.heightAnchor.constraint(equalToConstant: 220)
        commentTopConstraint = commentComposer.topAnchor.constraint(equalTo: actionStack.bottomAnchor, constant: 0)
        commentHeightConstraint = commentComposer.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            avatarImageView.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            avatarImageView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 44),
            avatarImageView.heightAnchor.constraint(equalToConstant: 44),

            moreButton.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            moreButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            moreButton.widthAnchor.constraint(equalToConstant: 32),
            moreButton.heightAnchor.constraint(equalToConstant: 32),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -10),

            timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            timeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            contentLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 14),
            contentLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            mediaImageView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 12),
            mediaImageView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            mediaImageView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            mediaHeightConstraint!,

            videoBadge.centerXAnchor.constraint(equalTo: mediaImageView.centerXAnchor),
            videoBadge.centerYAnchor.constraint(equalTo: mediaImageView.centerYAnchor),
            videoBadge.widthAnchor.constraint(equalToConstant: 44),
            videoBadge.heightAnchor.constraint(equalToConstant: 44),

            actionStack.topAnchor.constraint(equalTo: mediaImageView.bottomAnchor, constant: 12),
            actionStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            actionStack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -16),

            commentTopConstraint!,
            commentComposer.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            commentComposer.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            commentComposer.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            commentHeightConstraint!,
        ])
    }

    private func setupCommentComposer() {
        commentComposer.backgroundColor = BCTheme.Colors.surface
        commentComposer.layer.cornerRadius = 20
        commentComposer.layer.cornerCurve = .continuous
        commentComposer.clipsToBounds = true

        commentTextField.placeholder = "Viết bình luận..."
        commentTextField.font = BCTheme.Typography.body
        commentTextField.returnKeyType = .send
        commentTextField.delegate = self

        commentAttachButton.setImage(UIImage(systemName: "photo"), for: .normal)
        commentAttachButton.tintColor = BCTheme.Colors.primary
        commentAttachButton.addTarget(self, action: #selector(didTapAttachCommentImage), for: .touchUpInside)

        commentSendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        commentSendButton.tintColor = BCTheme.Colors.primary
        commentSendButton.addTarget(self, action: #selector(didTapSendComment), for: .touchUpInside)

        pendingImageLabel.text = "Đã chọn ảnh"
        pendingImageLabel.font = BCTheme.Typography.captionBold
        pendingImageLabel.textColor = BCTheme.Colors.primary
        pendingImageLabel.isHidden = true

        [commentAttachButton, commentTextField, pendingImageLabel, commentSendButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            commentComposer.addSubview($0)
        }

        NSLayoutConstraint.activate([
            commentAttachButton.leadingAnchor.constraint(equalTo: commentComposer.leadingAnchor, constant: 10),
            commentAttachButton.centerYAnchor.constraint(equalTo: commentComposer.centerYAnchor),
            commentAttachButton.widthAnchor.constraint(equalToConstant: 30),
            commentAttachButton.heightAnchor.constraint(equalToConstant: 30),

            commentSendButton.trailingAnchor.constraint(equalTo: commentComposer.trailingAnchor, constant: -10),
            commentSendButton.centerYAnchor.constraint(equalTo: commentComposer.centerYAnchor),
            commentSendButton.widthAnchor.constraint(equalToConstant: 30),
            commentSendButton.heightAnchor.constraint(equalToConstant: 30),

            pendingImageLabel.trailingAnchor.constraint(equalTo: commentSendButton.leadingAnchor, constant: -8),
            pendingImageLabel.centerYAnchor.constraint(equalTo: commentComposer.centerYAnchor),

            commentTextField.leadingAnchor.constraint(equalTo: commentAttachButton.trailingAnchor, constant: 8),
            commentTextField.trailingAnchor.constraint(equalTo: pendingImageLabel.leadingAnchor, constant: -8),
            commentTextField.topAnchor.constraint(equalTo: commentComposer.topAnchor),
            commentTextField.bottomAnchor.constraint(equalTo: commentComposer.bottomAnchor),
        ])
    }

    func configure(with post: FeedPostModel, isCommentExpanded: Bool, hasPendingCommentImage: Bool) {
        nameLabel.text = post.user.displayName ?? post.user.username
        timeLabel.text = relativeTime(from: post.createdAt)
        contentLabel.text = post.content?.isEmpty == false ? post.content : " "
        moreButton.isHidden = post.user.id != TokenManager.shared.currentUser?.id
        reactButton.configuration?.title = "Thích"
        reactButton.configuration?.image = UIImage(systemName: post.myReaction == nil ? "heart" : "heart.fill")
        reactButton.configuration?.baseForegroundColor = post.myReaction == nil ? BCTheme.Colors.textPrimary : .systemRed
        reactionCountButton.configuration?.title = "❤️ \(post.reactionCount)"
        commentButton.configuration?.title = "\(post.commentCount)"
        commentComposer.isHidden = !isCommentExpanded
        commentTopConstraint?.constant = isCommentExpanded ? 10 : 0
        commentHeightConstraint?.constant = isCommentExpanded ? 44 : 0
        pendingImageLabel.isHidden = !hasPendingCommentImage
        let mediaItems = post.mediaItems.sorted { $0.sortOrder < $1.sortOrder }
        let firstMediaUrl = mediaItems.first?.mediaUrl ?? post.mediaUrl
        let firstMediaType = mediaItems.first?.mediaType ?? post.mediaType
        let hasMedia = firstMediaUrl != nil
        mediaImageView.isHidden = !hasMedia
        mediaHeightConstraint?.constant = hasMedia ? 280 : 0
        videoBadge.isHidden = true
        if let url = Constants.mediaURL(from: post.user.avatarUrl) {
            avatarTask = ImageCache.shared.loadInto(avatarImageView, from: url)
        }
        if firstMediaType == "image", let url = Constants.mediaURL(from: firstMediaUrl) {
            imageTask = ImageCache.shared.load(from: url) { [weak self] image in
                guard let self = self, let image = image else { return }
                self.mediaImageView.image = image
                self.mediaHeightConstraint?.constant = min(420, max(220, image.size.height / max(image.size.width, 1) * UIScreen.main.bounds.width))
            }
            if mediaItems.count > 1 {
                videoBadge.attributedText = nil
                videoBadge.text = "+\(mediaItems.count - 1)"
                videoBadge.isHidden = false
            }
        } else if firstMediaType == "video" {
            let playIcon = NSTextAttachment()
            playIcon.image = UIImage(systemName: "play.fill")?.withTintColor(.white)
            videoBadge.attributedText = NSAttributedString(attachment: playIcon)
            mediaImageView.image = UIImage(systemName: "play.rectangle.fill")
            mediaImageView.tintColor = BCTheme.Colors.primary
            mediaImageView.contentMode = .center
            videoBadge.isHidden = false
        }
    }

    private func configureActionButton(_ button: UIButton, image: String?, title: String) {
        var config = UIButton.Configuration.plain()
        if let image {
            config.image = UIImage(systemName: image)
        }
        config.title = title
        config.imagePadding = 6
        config.baseForegroundColor = BCTheme.Colors.textPrimary
        config.baseBackgroundColor = BCTheme.Colors.surfaceElevated
        config.background.backgroundColor = BCTheme.Colors.surfaceElevated
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = BCTheme.Typography.bodyBold
            return out
        }
        button.configuration = config
    }

    private func relativeTime(from raw: String) -> String {
        guard let date = serverDate(from: raw) else { return "" }
        let seconds = max(0, Int(Date().timeIntervalSince(date)))
        if seconds < 60 { return "Vừa xong" }
        if seconds < 3600 { return "\(seconds / 60) phút" }
        if seconds < 86400 { return "\(seconds / 3600) giờ" }
        return "\(seconds / 86400) ngày"
    }

    private func serverDate(from raw: String) -> Date? {
        let isoWithFraction = ISO8601DateFormatter()
        isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoWithFraction.date(from: raw) { return date }

        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: raw) { return date }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: raw) { return date }
        }
        return nil
    }

    @objc private func didTapMore() { onMore?() }
    @objc private func didTapReact() { onReact?() }
    @objc private func didTapComment() { onComment?() }
    @objc private func didTapAttachCommentImage() {
        commentTextField.resignFirstResponder()
        onAttachCommentImage?()
    }
    @objc private func didTapSendComment() {
        onSendComment?(commentTextField.text ?? "")
        commentTextField.resignFirstResponder()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapSendComment()
        return true
    }
}


final class NotificationsViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var items: [AppNotificationItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Thông báo"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = BCTheme.Colors.backgroundGrouped
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
        tableView.register(NotificationCell.self, forCellReuseIdentifier: "cell")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NotificationCell
        let item = items[indexPath.row]
        cell.configure(with: item, iconName: iconName(for: item))
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

private final class NotificationCell: UITableViewCell {
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = BCTheme.Colors.surface
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        iconContainer.bcCornerRadius(20)
        iconContainer.backgroundColor = BCTheme.Colors.primarySoft
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = BCTheme.Colors.primary
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = BCTheme.Typography.bodyBold
        titleLabel.textColor = BCTheme.Colors.textPrimary
        titleLabel.numberOfLines = 1

        subtitleLabel.font = BCTheme.Typography.subheadline
        subtitleLabel.textColor = BCTheme.Colors.textSecondary
        subtitleLabel.numberOfLines = 2

        timeLabel.font = BCTheme.Typography.caption
        timeLabel.textColor = BCTheme.Colors.textTertiary

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, timeLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 40),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with item: AppNotificationItem, iconName: String) {
        iconView.image = UIImage(systemName: iconName)
        titleLabel.text = item.title
        subtitleLabel.text = item.body
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd/MM"
        timeLabel.text = formatter.string(from: item.date)
    }
}
