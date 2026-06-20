import UIKit



class WelcomeViewController: UIViewController {

  // MARK: - Properties
  private let backgroundGradient = CAGradientLayer()
  private var floatingBoxes: [UIImageView] = []
  private var didLayoutOnce = false

  // MARK: - UI Components
  private let logoImageView: UIImageView = {
    let iv = UIImageView(image: UIImage(named: "IconLoad"))
    iv.contentMode = .scaleAspectFit
    return iv
  }()

  private let titleLabel: UILabel = {
    let label = UILabel()
    let attributedString = NSMutableAttributedString(
      string: "Box",
      attributes: [
        .foregroundColor: BCTheme.Colors.textPrimary,
        .font: BCTheme.Typography.displayMedium,
      ]
    )
    attributedString.append(
      NSAttributedString(
        string: "Chat",
        attributes: [
          .foregroundColor: BCTheme.Colors.primary,
          .font: BCTheme.Typography.displayMedium,
        ]
      ))
    label.attributedText = attributedString
    return label
  }()

  private let taglineLabel: UILabel = {
    let l = UILabel()
    l.text = "Chat freely, connect easily."
    l.font = BCTheme.Typography.bodyBold
    l.textColor = BCTheme.Colors.textSecondary
    l.textAlignment = .center
    return l
  }()

  private lazy var loginButton: BCButton = {
    let b = BCButton(title: "Đăng nhập", style: .primary)
    b.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
    return b
  }()

  private lazy var registerButton: BCButton = {
    let b = BCButton(title: "Đăng ký", style: .secondary)
    b.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
    return b
  }()

  private lazy var actionButtonStack: UIStackView = {
    let sv = UIStackView(arrangedSubviews: [loginButton, registerButton])
    sv.axis = .vertical
    sv.spacing = 16
    sv.distribution = .fillEqually
    return sv
  }()

  private let dividerLabel: UILabel = {
    let l = UILabel()
    l.text = "Hoặc tiếp tục với"
    l.font = BCTheme.Typography.subheadline
    l.textColor = BCTheme.Colors.textSecondary
    l.textAlignment = .center
    return l
  }()

  private lazy var socialStack: UIStackView = {
    let sv = UIStackView()
    sv.axis = .horizontal
    sv.spacing = 24
    sv.alignment = .center
    sv.distribution = .equalSpacing
    let googleBtn = BCSocialButton(icon: "G", isSystemIcon: false)
    let appleBtn = BCSocialButton(icon: "apple.logo")
    let emailBtn = BCSocialButton(icon: "envelope.fill")
    [googleBtn, appleBtn, emailBtn].forEach { sv.addArrangedSubview($0) }
    return sv
  }()

  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.setNavigationBarHidden(true, animated: false)
    setupBackground()
    setupLayout()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    backgroundGradient.frame = view.bounds
    if !didLayoutOnce {
      didLayoutOnce = true
      setupFloatingBoxes()
      runEntranceAnimation()
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    updateDynamicColors()
  }

  // MARK: - Setup Background
  private func setupBackground() {
    updateDynamicColors()
    backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
    backgroundGradient.endPoint = CGPoint(x: 1, y: 1)
    view.layer.insertSublayer(backgroundGradient, at: 0)
  }

  // MARK: - Setup UI & Auto Layout
  private func setupLayout() {
    let components: [UIView] = [
      logoImageView, titleLabel, taglineLabel,
      actionButtonStack, dividerLabel, socialStack,
    ]
    components.forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.alpha = 0
      view.addSubview($0)
    }

    NSLayoutConstraint.activate([
      logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -160),
      logoImageView.widthAnchor.constraint(equalToConstant: 85),
      logoImageView.heightAnchor.constraint(equalToConstant: 85),

      titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
      titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

      taglineLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      taglineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

      actionButtonStack.topAnchor.constraint(equalTo: taglineLabel.bottomAnchor, constant: 50),
      actionButtonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      actionButtonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
      actionButtonStack.heightAnchor.constraint(equalToConstant: 124),

      dividerLabel.topAnchor.constraint(equalTo: actionButtonStack.bottomAnchor, constant: 32),
      dividerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

      socialStack.topAnchor.constraint(equalTo: dividerLabel.bottomAnchor, constant: 20),
      socialStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      socialStack.heightAnchor.constraint(equalToConstant: 54),
    ])
  }

  // MARK: - Floating Boxes Logic
  private func setupFloatingBoxes() {
    struct BoxConfig {
      let x: CGFloat
      let y: CGFloat
      let size: CGFloat
      let alpha: CGFloat
      let rotation: CGFloat
      let duration: Double
      let delay: Double
      let moveX: CGFloat
      let moveY: CGFloat
    }

    let w = view.bounds.width
    let h = view.bounds.height
    let configs: [BoxConfig] = [
      BoxConfig(
        x: w - 80, y: h * 0.08, size: 70, alpha: 0.13, rotation: 20, duration: 5.0, delay: 0.0,
        moveX: -8, moveY: 12),
      BoxConfig(
        x: -20, y: h * 0.14, size: 55, alpha: 0.10, rotation: -15, duration: 6.0, delay: 0.3,
        moveX: 10, moveY: -8),
      BoxConfig(
        x: w - 60, y: h * 0.30, size: 45, alpha: 0.08, rotation: 30, duration: 7.0, delay: 0.6,
        moveX: -6, moveY: 14),
      BoxConfig(
        x: 10, y: h * 0.44, size: 40, alpha: 0.09, rotation: -25, duration: 5.5, delay: 0.4,
        moveX: 8, moveY: -10),
      BoxConfig(
        x: w - 50, y: h * 0.58, size: 35, alpha: 0.07, rotation: 15, duration: 6.5, delay: 1.0,
        moveX: -10, moveY: 10),
    ]

    for config in configs {
      let iv = UIImageView(image: UIImage(named: "IconLoad"))
      iv.contentMode = .scaleAspectFit
      iv.frame = CGRect(x: config.x, y: config.y, width: config.size, height: config.size)
      iv.alpha = 0
      iv.transform = CGAffineTransform(rotationAngle: config.rotation * .pi / 180)
      view.insertSubview(iv, at: 1)
      floatingBoxes.append(iv)

      UIView.animate(withDuration: 0.9, delay: config.delay, options: .curveEaseOut) {
        iv.alpha = config.alpha
      } completion: { _ in
        self.startFloatingAnimation(
          iv,
          moveX: config.moveX,
          moveY: config.moveY,
          duration: config.duration,
          baseRotation: config.rotation
        )
      }
    }
  }

  private func startFloatingAnimation(
    _ iv: UIImageView, moveX: CGFloat, moveY: CGFloat, duration: Double, baseRotation: CGFloat
  ) {
    let base = CGAffineTransform(rotationAngle: baseRotation * .pi / 180)
    UIView.animate(
      withDuration: duration, delay: 0,
      options: [.repeat, .autoreverse, .curveEaseInOut]
    ) {
      iv.transform = base.translatedBy(x: moveX, y: moveY)
    }
  }

  private func updateDynamicColors() {
    backgroundGradient.colors = [
      BCTheme.Colors.primarySoft.cgColor,
      BCTheme.Colors.background.cgColor,
    ]
    if let stack = socialStack.arrangedSubviews as? [BCSocialButton] {
      stack.forEach { $0.updateTraitBorder() }
    }
  }

  // MARK: - Navigation Actions
  @objc private func loginTapped() {
    let vc = LoginViewController()
    navigationController?.pushViewController(vc, animated: true)
  }

  @objc private func registerTapped() {
    let vc = RegisterViewController()
    navigationController?.pushViewController(vc, animated: true)
  }

  // MARK: - Entrance Animations
  private func runEntranceAnimation() {
    let sequence: [(UIView, TimeInterval)] = [
      (logoImageView, 0.05),
      (titleLabel, 0.15),
      (taglineLabel, 0.25),
      (actionButtonStack, 0.36),
      (dividerLabel, 0.48),
      (socialStack, 0.58),
    ]

    for (v, delay) in sequence {
      v.transform = CGAffineTransform(translationX: 0, y: 22)
      UIView.animate(
        withDuration: 0.65, delay: delay,
        usingSpringWithDamping: 0.78, initialSpringVelocity: 0.4,
        options: .curveEaseOut
      ) {
        v.alpha = 1
        v.transform = .identity
      }
    }

    startLogoPulse()
  }

  private func startLogoPulse() {
    UIView.animate(
      withDuration: 2.5, delay: 1.0,
      options: [.repeat, .autoreverse, .curveEaseInOut]
    ) {
      self.logoImageView.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
    }
  }
}
