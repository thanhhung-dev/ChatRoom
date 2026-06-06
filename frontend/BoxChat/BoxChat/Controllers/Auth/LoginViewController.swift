import UIKit

class LoginViewController: UIViewController {
    
    // MARK: - Ambient Background
    private let ambientOrb1 = UIView()
    private let ambientOrb2 = UIView()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    
    // MARK: - UI Components
    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        btn.setImage(UIImage(systemName: "arrow.left", withConfiguration: config), for: .normal)
        btn.tintColor = .systemBlue
        btn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return btn
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Đăng nhập"
        l.font = .systemFont(ofSize: 32, weight: .heavy)
        l.textColor = .label
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Chào mừng trở lại!"
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = .secondaryLabel
        return l
    }()
    
    private lazy var usernameField: UITextField = createTextField(
        placeholder: "Tên đăng nhập",
        title: "Tên đăng nhập",
        isSecure: false
    )
    private lazy var passwordField: UITextField = createTextField(placeholder: "••••••••", title: "Mật khẩu", isSecure: true)
    
    private lazy var forgotPasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Quên mật khẩu?", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        btn.contentHorizontalAlignment = .right
        btn.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var loginButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Đăng nhập", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 24
        btn.layer.cornerCurve = .continuous
        btn.layer.shadowColor = UIColor.systemBlue.cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowRadius = 12
        btn.layer.shadowOffset = CGSize(width: 0, height: 6)
        btn.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return btn
    }()
    
    private let dividerLabel: UILabel = {
        let l = UILabel()
        l.text = "Hoặc tiếp tục với"
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()
    
    private lazy var socialStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 20
        sv.alignment = .center
        sv.distribution = .equalSpacing
        
        let googleBtn = createSocialButton(imageName: "G_logo", sfSymbol: nil, tint: UIColor(red: 0.85, green: 0.26, blue: 0.21, alpha: 1))
        let appleBtn  = createSocialButton(imageName: nil, sfSymbol: "apple.logo", tint: .label)
        let emailBtn  = createSocialButton(imageName: nil, sfSymbol: "envelope.fill", tint: .systemBlue)
        
        [googleBtn, appleBtn, emailBtn].forEach { sv.addArrangedSubview($0) }
        return sv
    }()
    
    private lazy var registerPromptButton: UIButton = {
        let btn = UIButton(type: .system)
        let attr = NSMutableAttributedString(string: "Chưa có tài khoản? ", attributes: [.foregroundColor: UIColor.secondaryLabel, .font: UIFont.systemFont(ofSize: 14, weight: .medium)])
        attr.append(NSAttributedString(string: "Đăng ký", attributes: [.foregroundColor: UIColor.systemBlue, .font: UIFont.systemFont(ofSize: 14, weight: .bold)]))
        btn.setAttributedTitle(attr, for: .normal)
        btn.addTarget(self, action: #selector(switchToRegister), for: .touchUpInside)
        return btn
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupAmbientBackground()
        setupLayout()
        setupButtonAnimations()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        blurEffectView.frame = view.bounds
    }
    
    // MARK: - Setup
    private func setupAmbientBackground() {
        ambientOrb1.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        ambientOrb1.frame = CGRect(x: -50, y: -50, width: 300, height: 300)
        ambientOrb1.layer.cornerRadius = 150
        ambientOrb1.layer.masksToBounds = true
        view.addSubview(ambientOrb1)
        
        ambientOrb2.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        ambientOrb2.frame = CGRect(x: view.bounds.width - 200, y: 300, width: 250, height: 250)
        ambientOrb2.layer.cornerRadius = 125
        ambientOrb2.layer.masksToBounds = true
        view.addSubview(ambientOrb2)
        
        view.addSubview(blurEffectView)
        
        animateOrbs()
    }
    
    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        let components = [
            backButton,
            titleLabel,
            subtitleLabel,
            usernameField,
            passwordField,
            forgotPasswordButton,
            loginButton,
            dividerLabel,
            socialStack,
            registerPromptButton
        ]
        
        components.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            
            usernameField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            usernameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            usernameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            passwordField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 24),
            passwordField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            passwordField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            forgotPasswordButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 12),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            loginButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 32),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            loginButton.heightAnchor.constraint(equalToConstant: 54),
            
            dividerLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 40),
            dividerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            socialStack.topAnchor.constraint(equalTo: dividerLabel.bottomAnchor, constant: 24),
            socialStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            socialStack.heightAnchor.constraint(equalToConstant: 54),
            
            registerPromptButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16),
            registerPromptButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - Helpers
    private func createTextField(placeholder: String, title: String, isSecure: Bool) -> UITextField {
        let container = UITextField()
        container.placeholder = placeholder
        container.isSecureTextEntry = isSecure
        
        container.autocapitalizationType = .none
        container.autocorrectionType = .no
        container.font = .systemFont(ofSize: 16)
        container.backgroundColor = UIColor.label.withAlphaComponent(0.04)
        container.layer.cornerRadius = 16
        container.layer.cornerCurve = .continuous
        container.heightAnchor.constraint(equalToConstant: 54).isActive = true
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 54))
        container.leftView = paddingView
        container.leftViewMode = .always
        
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 13, weight: .medium)
        titleLbl.textColor = .secondaryLabel
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLbl)
        
        DispatchQueue.main.async {
            NSLayoutConstraint.activate([
                titleLbl.bottomAnchor.constraint(equalTo: container.topAnchor, constant: -8),
                titleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4)
            ])
        }
        
        if isSecure {
            let rightPadding = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 54))
            let eyeBtn = UIButton(type: .custom)
            eyeBtn.setImage(UIImage(systemName: "eye.slash"), for: .normal)
            eyeBtn.setImage(UIImage(systemName: "eye"), for: .selected)
            eyeBtn.tintColor = .secondaryLabel
            eyeBtn.frame = CGRect(x: 0, y: 0, width: 44, height: 54)
            eyeBtn.addTarget(self, action: #selector(toggleEye(_:)), for: .touchUpInside)
            rightPadding.addSubview(eyeBtn)
            container.rightView = rightPadding
            container.rightViewMode = .always
        }
        return container
    }
    
    private func createSocialButton(imageName: String?, sfSymbol: String?, tint: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .systemBackground
        btn.layer.cornerRadius = 27
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.label.withAlphaComponent(0.1).cgColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        if let symbol = sfSymbol, let img = UIImage(systemName: symbol) {
            btn.setImage(img.withRenderingMode(.alwaysOriginal).withTintColor(tint), for: .normal)
        } else if let _ = imageName {
            let l = UILabel()
            l.text = "G"
            l.font = .systemFont(ofSize: 20, weight: .bold)
            l.textColor = tint
            l.translatesAutoresizingMaskIntoConstraints = false
            btn.addSubview(l)
            NSLayoutConstraint.activate([
                l.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
                l.centerYAnchor.constraint(equalTo: btn.centerYAnchor)
            ])
        }
        
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: 54),
            btn.heightAnchor.constraint(equalToConstant: 54)
        ])
        return btn
    }
    
    // MARK: - Actions
    private func animateOrbs() {
        UIView.animate(withDuration: 8.0, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.ambientOrb1.transform = CGAffineTransform(translationX: 40, y: 30).scaledBy(x: 1.1, y: 1.1)
            self.ambientOrb2.transform = CGAffineTransform(translationX: -30, y: -40).scaledBy(x: 1.2, y: 1.2)
        } completion: { _ in }
    }
    
    private func setupButtonAnimations() {
        let buttons = [loginButton]
        for btn in buttons {
            btn.addTarget(self, action: #selector(btnDown(_:)), for: .touchDown)
            btn.addTarget(self, action: #selector(btnUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        }
    }
    
    @objc private func btnDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn) {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            sender.alpha = 0.9
        } completion: { _ in }
    }
    
    @objc private func btnUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: []) {
            sender.transform = .identity
            sender.alpha = 1
        } completion: { _ in }
    }
    
    @objc private func toggleEye(_ sender: UIButton) {
        sender.isSelected.toggle()
        passwordField.isSecureTextEntry = !sender.isSelected
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func switchToRegister() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func forgotPasswordTapped() {
        let vc = ForgotPasswordViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func loginTapped() {
        
        dismissKeyboard()
        
        guard let username = usernameField.text,
              !username.isEmpty,
              let password = passwordField.text,
              !password.isEmpty
        else {
            showAlert(message: "Vui lòng nhập đầy đủ thông tin")
            return
        }
        
        loginButton.isEnabled = false
        
        NetworkManager.shared.login(
            params: [
                "username": username,
                "password": password
            ]
        ) { [weak self] result in
            
            DispatchQueue.main.async {
                
                self?.loginButton.isEnabled = true
                
                switch result {
                    
                case .success:
                    WebSocketService.shared.connect()
                    
                    guard
                        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        let sceneDelegate = windowScene.delegate as? SceneDelegate,
                        let window = sceneDelegate.window
                    else { return }
                    
                    UIView.transition(
                        with: window,
                        duration: 0.35,
                        options: .transitionCrossDissolve,
                        animations: { window.rootViewController = MainTabBarController() }
                    )
                    
                case .failure(let error):
                    self?.showAlert(message: error.localizedDescription)
                }
            }
        }
    }
    private func showAlert(message: String) {
        
        let alert = UIAlertController(
            title: "Thông báo",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            )
        )
        
        present(alert, animated: true)
    }
}
