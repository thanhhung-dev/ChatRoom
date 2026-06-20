import UIKit
import UserNotifications

class UserProfileViewController: UIViewController {

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = BCTheme.Colors.surfaceElevated
        view.layer.cornerRadius = BCTheme.Layout.cornerRadiusL
        BCTheme.Shadow.card(view)
        return view
    }()

    private let avatarView = BCAvatar(size: 120)

    private let displayNameLabel: UILabel = {
        let label = UILabel()
        label.font = BCTheme.Typography.title
        label.textColor = BCTheme.Colors.textPrimary
        label.textAlignment = .center
        return label
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = BCTheme.Typography.body
        label.textColor = BCTheme.Colors.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let actionStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = BCTheme.Layout.paddingM
        return stack
    }()

    private let changePasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Đổi mật khẩu"
        config.baseBackgroundColor = BCTheme.Colors.primarySoft
        config.baseForegroundColor = BCTheme.Colors.primary
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = BCTheme.Typography.subheadlineBold
            return outgoing
        }
        btn.configuration = config
        return btn
    }()

    private let logoutButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Đăng xuất tài khoản"
        config.baseBackgroundColor = BCTheme.Colors.error.withAlphaComponent(0.12)
        config.baseForegroundColor = BCTheme.Colors.error
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = BCTheme.Typography.subheadlineBold
            return outgoing
        }
        btn.configuration = config
        return btn
    }()

    private let notificationButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Bật thông báo tin nhắn"
        config.baseBackgroundColor = BCTheme.Colors.success.withAlphaComponent(0.12)
        config.baseForegroundColor = BCTheme.Colors.success
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = BCTheme.Typography.subheadlineBold
            return outgoing
        }
        btn.configuration = config
        return btn
    }()

    private let qrButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Mã QR kết bạn"
        config.baseBackgroundColor = BCTheme.Colors.primarySoft
        config.baseForegroundColor = BCTheme.Colors.primary
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = BCTheme.Typography.subheadlineBold
            return outgoing
        }
        btn.configuration = config
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hồ Sơ"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = BCTheme.Colors.background

        setupLayout()
        configureProfile()

        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapAvatar)))

        qrButton.addTarget(self, action: #selector(didTapQR), for: .touchUpInside)
        changePasswordButton.addTarget(self, action: #selector(didTapChangePassword), for: .touchUpInside)
        notificationButton.addTarget(self, action: #selector(didTapNotifications), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
    }

    private func setupLayout() {
        view.addSubview(cardView)
        cardView.addSubview(avatarView)
        cardView.addSubview(displayNameLabel)
        cardView.addSubview(usernameLabel)
        view.addSubview(actionStackView)

        actionStackView.addArrangedSubview(qrButton)
        actionStackView.addArrangedSubview(notificationButton)
        actionStackView.addArrangedSubview(changePasswordButton)
        actionStackView.addArrangedSubview(logoutButton)

        [cardView, avatarView, displayNameLabel, usernameLabel, actionStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: BCTheme.Layout.paddingL),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: BCTheme.Layout.paddingL),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -BCTheme.Layout.paddingL),

            avatarView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: BCTheme.Layout.paddingL),
            avatarView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 120),
            avatarView.heightAnchor.constraint(equalToConstant: 120),

            displayNameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: BCTheme.Layout.paddingM),
            displayNameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: BCTheme.Layout.paddingL),
            displayNameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -BCTheme.Layout.paddingL),

            usernameLabel.topAnchor.constraint(equalTo: displayNameLabel.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: BCTheme.Layout.paddingL),
            usernameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -BCTheme.Layout.paddingL),
            usernameLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -BCTheme.Layout.paddingL),

            actionStackView.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: BCTheme.Layout.paddingL),
            actionStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: BCTheme.Layout.paddingL),
            actionStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -BCTheme.Layout.paddingL),

            qrButton.heightAnchor.constraint(equalToConstant: BCTheme.Layout.buttonHeight),
            notificationButton.heightAnchor.constraint(equalToConstant: BCTheme.Layout.buttonHeight),
            changePasswordButton.heightAnchor.constraint(equalToConstant: BCTheme.Layout.buttonHeight),
            logoutButton.heightAnchor.constraint(equalToConstant: BCTheme.Layout.buttonHeight)
        ])
    }

    private func configureProfile() {
        guard let currentUser = TokenManager.shared.currentUser else { return }
        displayNameLabel.text = currentUser.displayName ?? currentUser.username
        usernameLabel.text = "@\(currentUser.username)"
        avatarView.configure(name: currentUser.displayName ?? currentUser.username, url: currentUser.avatarUrl)
    }

    @objc private func didTapLogout() {
        let alert = UIAlertController(title: "Đăng xuất", message: "Bạn có chắc muốn đăng xuất không?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Đăng xuất", style: .destructive) { _ in
            TokenManager.shared.clear()
            WebSocketService.shared.disconnect()
            NotificationCenter.default.post(name: .didLogoutRequired, object: nil)
        })
        present(alert, animated: true)
    }

    @objc private func didTapChangePassword() {
        let reset = ResetPasswordViewController()
        navigationController?.pushViewController(reset, animated: true)
    }

    @objc private func didTapNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            granted, _ in
            DispatchQueue.main.async {
                if granted {
                    BCToast.show("Bạn sẽ nhận thông báo khi có tin nhắn mới.", style: .success)
                } else {
                    BCToast.show("Vui lòng bật quyền thông báo trong Cài đặt.", style: .error)
                }
            }
        }
    }

    @objc private func didTapQR() {
        guard let currentUser = TokenManager.shared.currentUser else { return }
        let displayName = !(currentUser.displayName?.isEmpty ?? true) ? currentUser.displayName! : currentUser.username
        let qr = QRCodeViewController(
            payload: Constants.friendLink(username: currentUser.username),
            heading: "Mã QR kết bạn",
            detail: "Người khác quét mã này để gửi lời mời kết bạn tới \(displayName).")
        navigationController?.pushViewController(qr, animated: true)
    }

    @objc private func didTapAvatar() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }
}

extension UserProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage,
              let data = image.jpegData(compressionQuality: 0.78) else { return }

        BCToast.show("Đang tải ảnh lên...", style: .success)

        NetworkManager.shared.uploadUserAvatar(imageData: data) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let user) = result {
                    TokenManager.shared.currentUser = user
                    if let urlString = user.avatarUrl, let url = URL(string: urlString) {
                        ImageCache.shared.remove(for: url)
                    }
                    self?.configureProfile()
                    BCToast.show("Cập nhật ảnh thành công", style: .success)
                } else {
                    BCToast.show("Tải ảnh thất bại", style: .error)
                }
            }
        }
    }
}
