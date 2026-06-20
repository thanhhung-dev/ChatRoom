import UIKit
import UserNotifications

class UserProfileViewController: UIViewController {

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.05
        return view
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.crop.circle.fill")
        iv.tintColor = .systemGray4
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 60
        iv.clipsToBounds = true
        return iv
    }()

    private let displayNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let actionStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private let changePasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Đổi mật khẩu", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.backgroundColor = .systemBlue.withAlphaComponent(0.08)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.layer.cornerRadius = 14
        return btn
    }()

    private let logoutButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Đăng xuất tài khoản", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        btn.backgroundColor = .systemRed.withAlphaComponent(0.08)
        btn.setTitleColor(.systemRed, for: .normal)
        btn.layer.cornerRadius = 14
        return btn
    }()

    private let notificationButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Bật thông báo tin nhắn", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.backgroundColor = .systemGreen.withAlphaComponent(0.08)
        btn.setTitleColor(.systemGreen, for: .normal)
        btn.layer.cornerRadius = 14
        return btn
    }()

    private let qrButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Mã QR kết bạn", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.backgroundColor = .systemBlue.withAlphaComponent(0.08)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.layer.cornerRadius = 14
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hồ Sơ"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        configureProfile()
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapAvatar)))
        qrButton.addTarget(self, action: #selector(didTapQR), for: .touchUpInside)
        changePasswordButton.addTarget(self, action: #selector(didTapChangePassword), for: .touchUpInside)
        notificationButton.addTarget(self, action: #selector(didTapNotifications), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
    }

    private func setupLayout() {
        view.addSubview(cardView)
        cardView.addSubview(avatarImageView)
        cardView.addSubview(displayNameLabel)
        cardView.addSubview(usernameLabel)
        view.addSubview(actionStackView)
        actionStackView.addArrangedSubview(qrButton)
        actionStackView.addArrangedSubview(notificationButton)
        actionStackView.addArrangedSubview(changePasswordButton)
        actionStackView.addArrangedSubview(logoutButton)

        [cardView, avatarImageView, displayNameLabel, usernameLabel, actionStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cardView.heightAnchor.constraint(equalToConstant: 260),

            avatarImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            avatarImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 120),
            avatarImageView.heightAnchor.constraint(equalToConstant: 120),

            displayNameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            displayNameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            displayNameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            usernameLabel.topAnchor.constraint(equalTo: displayNameLabel.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            usernameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            actionStackView.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 24),
            actionStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            qrButton.heightAnchor.constraint(equalToConstant: 48),
            notificationButton.heightAnchor.constraint(equalToConstant: 48),
            changePasswordButton.heightAnchor.constraint(equalToConstant: 48),
            logoutButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func configureProfile() {
        guard let currentUser = TokenManager.shared.currentUser else { return }
        displayNameLabel.text = currentUser.username
        usernameLabel.text = "@\(currentUser.username)"
        if let url = Constants.mediaURL(from: currentUser.avatarUrl) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async { self?.avatarImageView.image = image }
                }
            }.resume()
        }
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
                let alert = UIAlertController(
                    title: granted ? "Đã bật thông báo" : "Chưa bật được thông báo",
                    message: granted ? "Bạn sẽ nhận thông báo khi có tin nhắn mới." : "Bạn có thể bật lại trong Settings của iOS.",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }

    @objc private func didTapQR() {
        guard let currentUser = TokenManager.shared.currentUser else { return }
        let displayName = ((currentUser.displayName?.isEmpty) != nil) ? currentUser.username : currentUser.displayName
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
        avatarImageView.image = image
        NetworkManager.shared.uploadUserAvatar(imageData: data) { result in
            DispatchQueue.main.async {
                if case .success(let user) = result {
                    TokenManager.shared.currentUser = user
                    self.configureProfile()
                }
            }
        }
    }
}
