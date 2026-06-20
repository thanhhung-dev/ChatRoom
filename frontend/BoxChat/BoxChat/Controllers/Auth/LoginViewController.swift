import UIKit

class LoginViewController: BaseAuthViewController {

    // MARK: - UI Components

    private lazy var usernameField: BCTextField = {
        let field = BCTextField(title: "Tên đăng nhập", placeholder: "Nhập tên đăng nhập", isSecure: false)
        return field
    }()

    private lazy var passwordField: BCTextField = {
        let field = BCTextField(title: "Mật khẩu", placeholder: "••••••••", isSecure: true)
        return field
    }()

    private lazy var forgotPasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Quên mật khẩu?", for: .normal)
        btn.setTitleColor(BCTheme.Colors.primary, for: .normal)
        btn.titleLabel?.font = BCTheme.Typography.calloutBold
        btn.contentHorizontalAlignment = .right
        btn.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var loginButton: BCButton = {
        let btn = BCButton(title: "Đăng nhập", style: .primary)
        btn.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "Đăng nhập"
        subtitleLabel.text = "Chào mừng trở lại!"

        setupForm()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    // MARK: - Setup

    private func setupForm() {
        contentStack.addArrangedSubview(usernameField)
        addSpacing(24)
        contentStack.addArrangedSubview(passwordField)
        addSpacing(12)

        // Forgot password needs to be right-aligned
        let forgotContainer = UIView()
        forgotContainer.translatesAutoresizingMaskIntoConstraints = false
        forgotContainer.addSubview(forgotPasswordButton)
        forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            forgotPasswordButton.topAnchor.constraint(equalTo: forgotContainer.topAnchor),
            forgotPasswordButton.bottomAnchor.constraint(equalTo: forgotContainer.bottomAnchor),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: forgotContainer.trailingAnchor),
            forgotPasswordButton.leadingAnchor.constraint(greaterThanOrEqualTo: forgotContainer.leadingAnchor)
        ])
        contentStack.addArrangedSubview(forgotContainer)

        addSpacing(32)
        contentStack.addArrangedSubview(loginButton)
        addSpacing(40)

        contentStack.addArrangedSubview(makeDividerRow(text: "Hoặc tiếp tục với"))
        addSpacing(24)

        contentStack.addArrangedSubview(makeSocialRow())
        addSpacing(40)

        let footer = makeFooterLink(prefix: "Chưa có tài khoản?", action: "Đăng ký", target: #selector(switchToRegister))
        contentStack.addArrangedSubview(footer)
    }

    // MARK: - Actions

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func switchToRegister() {
        let vc = RegisterViewController()
        if var viewControllers = navigationController?.viewControllers {
            viewControllers[viewControllers.count - 1] = vc
            navigationController?.setViewControllers(viewControllers, animated: true)
        } else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc private func forgotPasswordTapped() {
        let vc = ForgotPasswordViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func loginTapped() {
        dismissKeyboard()

        guard let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showToast("Vui lòng nhập đầy đủ thông tin", style: .error)
            return
        }

        loginButton.isLoading = true

        NetworkManager.shared.login(params: [
            "username": username,
            "password": password
        ]) { [weak self] result in
            DispatchQueue.main.async {
                self?.loginButton.isLoading = false

                switch result {
                case .success:
                    WebSocketService.shared.connect()

                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let sceneDelegate = windowScene.delegate as? SceneDelegate,
                          let window = sceneDelegate.window else { return }

                    UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve, animations: {
                        window.rootViewController = MainTabBarController()
                    })

                case .failure(let error):
                    self?.showToast(error.localizedDescription, style: .error)
                }
            }
        }
    }
}
