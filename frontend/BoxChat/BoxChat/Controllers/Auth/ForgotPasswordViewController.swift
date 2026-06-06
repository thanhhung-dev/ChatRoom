import UIKit

class ForgotPasswordViewController: UIViewController {

    // MARK: - Ambient Background

    private let ambientOrb1 = UIView()
    private let ambientOrb2 = UIView()

    private let blurEffectView = UIVisualEffectView(
        effect: UIBlurEffect(style: .systemUltraThinMaterial)
    )

    // MARK: - UI Components

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)

        let config = UIImage.SymbolConfiguration(
            pointSize: 20,
            weight: .semibold
        )

        button.setImage(
            UIImage(systemName: "arrow.left", withConfiguration: config),
            for: .normal
        )

        button.tintColor = .systemBlue
        button.addTarget(
            self,
            action: #selector(backTapped),
            for: .touchUpInside
        )

        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()

        label.text = "Quên mật khẩu"
        label.font = .systemFont(ofSize: 32, weight: .heavy)
        label.textColor = .label

        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()

        label.text = "Nhập email của bạn"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label

        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()

        label.text = "Chúng tôi sẽ gửi liên kết đặt lại mật khẩu đến email của bạn."
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0

        return label
    }()

    private lazy var emailField = createTextField(
        placeholder: "nguyenvana@gmail.com",
        title: "Email"
    )

    private lazy var sendLinkButton: UIButton = {
        let button = UIButton(type: .system)

        button.setTitle("Gửi liên kết", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue

        button.layer.cornerRadius = 24
        button.layer.cornerCurve = .continuous

        button.layer.shadowColor = UIColor.systemBlue.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 12
        button.layer.shadowOffset = CGSize(width: 0, height: 6)

        button.addTarget(
            self,
            action: #selector(sendLinkTapped),
            for: .touchUpInside
        )

        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupAmbientBackground()
        setupLayout()
        setupButtonAnimations()

        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )

        view.addGestureRecognizer(tap)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        blurEffectView.frame = view.bounds
    }

    // MARK: - Setup UI

    private func setupAmbientBackground() {
        ambientOrb1.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        ambientOrb1.frame = CGRect(x: -50, y: -50, width: 300, height: 300)
        ambientOrb1.layer.cornerRadius = 150
        ambientOrb1.layer.masksToBounds = true

        view.addSubview(ambientOrb1)

        ambientOrb2.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        ambientOrb2.frame = CGRect(
            x: view.bounds.width - 200,
            y: 300,
            width: 250,
            height: 250
        )

        ambientOrb2.layer.cornerRadius = 125
        ambientOrb2.layer.masksToBounds = true

        view.addSubview(ambientOrb2)
        view.addSubview(blurEffectView)

        animateOrbs()
    }

    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide

        let components: [UIView] = [
            backButton,
            titleLabel,
            subtitleLabel,
            descriptionLabel,
            emailField,
            sendLinkButton
        ]

        components.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(
                equalTo: safeArea.topAnchor,
                constant: 16
            ),
            backButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24
            ),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(
                equalTo: backButton.bottomAnchor,
                constant: 24
            ),
            titleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24
            ),

            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 8
            ),
            subtitleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24
            ),

            descriptionLabel.topAnchor.constraint(
                equalTo: subtitleLabel.bottomAnchor,
                constant: 16
            ),
            descriptionLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24
            ),
            descriptionLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24
            ),

            emailField.topAnchor.constraint(
                equalTo: descriptionLabel.bottomAnchor,
                constant: 40
            ),
            emailField.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24
            ),
            emailField.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24
            ),

            sendLinkButton.topAnchor.constraint(
                equalTo: emailField.bottomAnchor,
                constant: 40
            ),
            sendLinkButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24
            ),
            sendLinkButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24
            ),
            sendLinkButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    // MARK: - Helpers

    private func createTextField(
        placeholder: String,
        title: String
    ) -> UITextField {
        let textField = UITextField()

        textField.placeholder = placeholder
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.font = .systemFont(ofSize: 16)
        textField.backgroundColor = UIColor.label.withAlphaComponent(0.04)

        textField.layer.cornerRadius = 16
        textField.layer.cornerCurve = .continuous

        textField.heightAnchor.constraint(equalToConstant: 54).isActive = true

        let paddingView = UIView(
            frame: CGRect(x: 0, y: 0, width: 20, height: 54)
        )

        textField.leftView = paddingView
        textField.leftViewMode = .always

        let titleLabel = UILabel()

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)

        DispatchQueue.main.async {
            NSLayoutConstraint.activate([
                titleLabel.bottomAnchor.constraint(
                    equalTo: textField.topAnchor,
                    constant: -8
                ),
                titleLabel.leadingAnchor.constraint(
                    equalTo: textField.leadingAnchor,
                    constant: 4
                )
            ])
        }

        return textField
    }

    // MARK: - Actions & Animations

    private func animateOrbs() {
        UIView.animate(
            withDuration: 8.0,
            delay: 0,
            options: [.repeat, .autoreverse, .curveEaseInOut]
        ) {
            self.ambientOrb1.transform = CGAffineTransform(
                translationX: 40,
                y: 30
            ).scaledBy(x: 1.1, y: 1.1)

            self.ambientOrb2.transform = CGAffineTransform(
                translationX: -30,
                y: -40
            ).scaledBy(x: 1.2, y: 1.2)
        }
    }

    private func setupButtonAnimations() {
        sendLinkButton.addTarget(
            self,
            action: #selector(btnDown(_:)),
            for: .touchDown
        )

        sendLinkButton.addTarget(
            self,
            action: #selector(btnUp(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )
    }

    @objc
    private func btnDown(_ sender: UIButton) {
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: .curveEaseIn
        ) {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            sender.alpha = 0.9
        }
    }

    @objc
    private func btnUp(_ sender: UIButton) {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8
        ) {
            sender.transform = .identity
            sender.alpha = 1
        }
    }

    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc
    private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func sendLinkTapped() {
        guard let email = emailField.text,
              !email.isEmpty
        else {
            return
        }

        dismissKeyboard()

        let resetVC = ResetPasswordViewController()
        navigationController?.pushViewController(resetVC, animated: true)
    }
}
