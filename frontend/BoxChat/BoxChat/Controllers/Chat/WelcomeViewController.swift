import UIKit

// MARK: - Color Theme Extension
extension UIColor {
  static let appBlue = UIColor(red: 0.19, green: 0.47, blue: 1.0, alpha: 1)
  static let textDark = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
  static let textGray = UIColor(red: 0.55, green: 0.57, blue: 0.62, alpha: 1)
  static let borderGray = UIColor(red: 0.88, green: 0.89, blue: 0.92, alpha: 1)
  static let bgLightStart = UIColor(red: 0.94, green: 0.96, blue: 1.00, alpha: 1)
  static let bgLightEnd = UIColor(red: 0.97, green: 0.98, blue: 1.00, alpha: 1)
}

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
        .foregroundColor: UIColor.textDark,
        .font: UIFont.systemFont(ofSize: 34, weight: .heavy),
      ]
    )
    attributedString.append(
      NSAttributedString(
        string: "Chat",
        attributes: [
          .foregroundColor: UIColor.appBlue,
          .font: UIFont.systemFont(ofSize: 34, weight: .heavy),
        ]
      ))
    label.attributedText = attributedString
    return label
  }()

  private let taglineLabel: UILabel = {
    let l = UILabel()
    l.text = "Chat freely, connect easily."
    l.font = .systemFont(ofSize: 15, weight: .medium)
    l.textColor = .textGray
    l.textAlignment = .center
    return l
  }()

  private lazy var loginButton: UIButton = {
    let b = UIButton(type: .system)
    b.setTitle("Đăng nhập", for: .normal)
    b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    b.setTitleColor(.white, for: .normal)
    b.backgroundColor = .appBlue
    b.layer.cornerRadius = 16
    b.layer.cornerCurve = .continuous
    b.layer.shadowColor = UIColor.appBlue.cgColor
    b.layer.shadowRadius = 12
    b.layer.shadowOpacity = 0.35
    b.layer.shadowOffset = CGSize(width: 0, height: 4)
    b.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
    return b
  }()

  private lazy var registerButton: UIButton = {
    let b = UIButton(type: .system)
    b.setTitle("Đăng ký", for: .normal)
    b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    b.setTitleColor(.textDark, for: .normal)
    b.backgroundColor = .white
    b.layer.cornerRadius = 16
    b.layer.cornerCurve = .continuous
    b.layer.borderWidth = 1
    b.layer.borderColor = UIColor.borderGray.cgColor
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
    l.font = .systemFont(ofSize: 13, weight: .medium)
    l.textColor = .textGray
    l.textAlignment = .center
    return l
  }()

  private lazy var socialStack: UIStackView = {
    let sv = UIStackView()
    sv.axis = .horizontal
    sv.spacing = 24
    sv.alignment = .center
    sv.distribution = .equalSpacing
    let googleBtn = makeSocialButton(
      imageName: "G_logo", sfSymbol: nil,
      tint: UIColor(red: 0.85, green: 0.26, blue: 0.21, alpha: 1))
    let appleBtn = makeSocialButton(imageName: nil, sfSymbol: "apple.logo", tint: .black)
    let emailBtn = makeSocialButton(imageName: nil, sfSymbol: "envelope.fill", tint: .appBlue)
    [googleBtn, appleBtn, emailBtn].forEach { sv.addArrangedSubview($0) }
    return sv
  }()

  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.setNavigationBarHidden(true, animated: false)
    setupBackground()
    setupLayout()
    setupButtonAnimations()
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

  // MARK: - Setup Background
  private func setupBackground() {
    backgroundGradient.colors = [UIColor.bgLightStart.cgColor, UIColor.bgLightEnd.cgColor]
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

  // MARK: - Helpers
  private func makeSocialButton(imageName: String?, sfSymbol: String?, tint: UIColor) -> UIButton {
    let btn = UIButton(type: .system)
    btn.backgroundColor = .white
    btn.layer.cornerRadius = 27
    btn.layer.borderWidth = 1
    btn.layer.borderColor = UIColor.borderGray.cgColor
    btn.layer.shadowColor = UIColor.black.cgColor
    btn.layer.shadowOpacity = 0.06
    btn.layer.shadowRadius = 8
    btn.layer.shadowOffset = CGSize(width: 0, height: 2)
    btn.translatesAutoresizingMaskIntoConstraints = false

    if let symbol = sfSymbol, let img = UIImage(systemName: symbol) {
      btn.setImage(img.withRenderingMode(.alwaysOriginal).withTintColor(tint), for: .normal)
    } else if imageName != nil {
      let l = UILabel()
      l.text = "G"
      l.font = .systemFont(ofSize: 20, weight: .bold)
      l.textColor = tint
      l.translatesAutoresizingMaskIntoConstraints = false
      btn.addSubview(l)
      NSLayoutConstraint.activate([
        l.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
        l.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
      ])
    }

    NSLayoutConstraint.activate([
      btn.widthAnchor.constraint(equalToConstant: 54),
      btn.heightAnchor.constraint(equalToConstant: 54),
    ])
    return btn
  }

  // MARK: - Interactive Button Animations
  private func setupButtonAnimations() {
    let buttons = [loginButton, registerButton]
    for btn in buttons {
      btn.addTarget(self, action: #selector(btnDown(_:)), for: .touchDown)
      btn.addTarget(
        self, action: #selector(btnUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
  }

  @objc private func btnDown(_ sender: UIButton) {
    UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn) {
      sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
      sender.alpha = 0.9
    }
  }

  @objc private func btnUp(_ sender: UIButton) {
    UIView.animate(
      withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8,
      options: []
    ) {
      sender.transform = .identity
      sender.alpha = 1
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
