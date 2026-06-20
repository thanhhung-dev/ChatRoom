import UIKit

class RegisterViewController: BaseAuthViewController {

    // MARK: - UI Components

    private lazy var nameField: BCTextField = {
        let field = BCTextField(title: "Tên đăng nhập", placeholder: "nguyenvana", isSecure: false)
        return field
    }()

    private lazy var emailField: BCTextField = {
        let field = BCTextField(title: "Email", placeholder: "nguyenvana@gmail.com", isSecure: false)
        field.textField.keyboardType = .emailAddress
        return field
    }()

    private lazy var passwordField: BCTextField = {
        let field = BCTextField(title: "Mật khẩu", placeholder: "••••••••", isSecure: true)
        return field
    }()

    private lazy var confirmPasswordField: BCTextField = {
        let field = BCTextField(title: "Xác nhận mật khẩu", placeholder: "••••••••", isSecure: true)
        return field
    }()

    private lazy var termsButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        btn.setImage(UIImage(systemName: "square"), for: .normal)
        btn.tintColor = BCTheme.Colors.primary
        btn.isSelected = true
        btn.addTarget(self, action: #selector(termsTapped(_:)), for: .touchUpInside)
        return btn
    }()

    private let termsLabel: UILabel = {
        let l = UILabel()
        let attr = NSMutableAttributedString(
            string: "Tôi đồng ý với ",
            attributes: [
                .foregroundColor: BCTheme.Colors.textSecondary,
                .font: BCTheme.Typography.caption,
            ])
        attr.append(
            NSAttributedString(
                string: "Điều khoản sử dụng",
                attributes: [
                    .foregroundColor: BCTheme.Colors.primary,
                    .font: BCTheme.Typography.captionBold,
                ]))
        attr.append(
            NSAttributedString(
                string: " và ",
                attributes: [
                    .foregroundColor: BCTheme.Colors.textSecondary,
                    .font: BCTheme.Typography.caption,
                ]))
        attr.append(
            NSAttributedString(
                string: "Chính sách bảo mật",
                attributes: [
                    .foregroundColor: BCTheme.Colors.primary,
                    .font: BCTheme.Typography.captionBold,
                ]))
        l.attributedText = attr
        l.numberOfLines = 2
        return l
    }()

    private lazy var registerButton: BCButton = {
        let btn = BCButton(title: "Đăng ký", style: .primary)
        btn.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "Đăng ký"
        subtitleLabel.text = "Tạo tài khoản mới"

        setupForm()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    // MARK: - Setup

    private func setupForm() {
        contentStack.addArrangedSubview(nameField)
        addSpacing(24)
        contentStack.addArrangedSubview(emailField)
        addSpacing(24)
        contentStack.addArrangedSubview(passwordField)
        addSpacing(24)
        contentStack.addArrangedSubview(confirmPasswordField)
        addSpacing(24)

        // Terms
        let termsStack = UIStackView(arrangedSubviews: [termsButton, termsLabel])
        termsStack.axis = .horizontal
        termsStack.spacing = 12
        termsStack.alignment = .center
        termsStack.translatesAutoresizingMaskIntoConstraints = false

        let termsContainer = UIView()
        termsContainer.translatesAutoresizingMaskIntoConstraints = false
        termsContainer.addSubview(termsStack)

        NSLayoutConstraint.activate([
            termsButton.widthAnchor.constraint(equalToConstant: 24),
            termsButton.heightAnchor.constraint(equalToConstant: 24),

            termsStack.topAnchor.constraint(equalTo: termsContainer.topAnchor),
            termsStack.bottomAnchor.constraint(equalTo: termsContainer.bottomAnchor),
            termsStack.leadingAnchor.constraint(equalTo: termsContainer.leadingAnchor),
            termsStack.trailingAnchor.constraint(lessThanOrEqualTo: termsContainer.trailingAnchor)
        ])

        contentStack.addArrangedSubview(termsContainer)
        addSpacing(32)

        contentStack.addArrangedSubview(registerButton)
        addSpacing(40)

        let footer = makeFooterLink(prefix: "Đã có tài khoản?", action: "Đăng nhập", target: #selector(switchToLogin))
        contentStack.addArrangedSubview(footer)
    }

    // MARK: - Actions

    @objc private func termsTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func switchToLogin() {
        let vc = LoginViewController()
        if var viewControllers = navigationController?.viewControllers {
            viewControllers[viewControllers.count - 1] = vc
            navigationController?.setViewControllers(viewControllers, animated: true)
        } else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    @objc private func registerTapped() {
        dismissKeyboard()

        guard termsButton.isSelected else {
            showToast("Bạn cần đồng ý điều khoản sử dụng", style: .error)
            return
        }

        guard let username = nameField.text,
              let email = emailField.text,
              let password = passwordField.text,
              let confirmPassword = confirmPasswordField.text else {
            return
        }

        if username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            showToast("Vui lòng nhập đầy đủ thông tin", style: .error)
            return
        }

        if !isValidEmail(email) {
            showToast("Định dạng email không hợp lệ", style: .error)
            return
        }

        if username.count < 3 {
            showToast("Tên đăng nhập phải có ít nhất 3 ký tự", style: .error)
            return
        }

        if password.count < 8 {
            showToast("Mật khẩu phải có ít nhất 8 ký tự", style: .error)
            return
        }

        if password != confirmPassword {
            showToast("Mật khẩu xác nhận không khớp", style: .error)
            return
        }

        registerButton.isLoading = true

        NetworkManager.shared.register(params: [
            "username": username,
            "email": email,
            "password": password
        ]) { [weak self] result in
            DispatchQueue.main.async {
                self?.registerButton.isLoading = false

                switch result {
                case .success:
                    NetworkManager.shared.fetchMe { meResult in
                        DispatchQueue.main.async {
                            if case .success(let user) = meResult {
                                TokenManager.shared.currentUser = user
                            }
                            WebSocketService.shared.connect()
                            self?.navigateToMainApp()
                        }
                    }

                case .failure(let error):
                    self?.showToast(error.localizedDescription, style: .error)
                }
            }
        }
    }

    private func navigateToMainApp() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let window = sceneDelegate.window else { return }

        UIView.transition(with: window,
                          duration: 0.35,
                          options: .transitionCrossDissolve,
                          animations: { window.rootViewController = MainTabBarController() })
    }
}
