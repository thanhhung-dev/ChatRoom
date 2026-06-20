//
//  BCComponents.swift
//  BoxChat
//
//  Reusable UI components built on BCTheme.
//  Provides consistent styling across the entire app.
//

import UIKit

// MARK: - BCTextField

/// Styled text field with title label, optional icon, and password toggle.
///
/// Layout:
/// ```
///  [Title Label]              ← 13pt semibold, secondary
///  ┌─────────────────────┐
///  │ [Icon?] [TextField] [Eye?] │  ← 50pt height, surface bg
///  └─────────────────────┘
/// ```
final class BCTextField: UIView {

    // MARK: Public

    let textField = UITextField()

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    var onReturn: (() -> Void)?

    // MARK: Private

    private let titleLabel = UILabel()
    private let container  = UIView()
    private var eyeButton: UIButton?

    // MARK: Init

    /// - Parameters:
    ///   - title: Label shown above the field ("Email", "Mật khẩu", …)
    ///   - placeholder: Inline placeholder text
    ///   - icon: Optional SF Symbol name for left icon
    ///   - isSecure: If `true`, adds a password visibility toggle
    init(title: String, placeholder: String, icon: String? = nil, isSecure: Bool = false) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupTitle(title)
        setupContainer()
        setupTextField(placeholder: placeholder, icon: icon, isSecure: isSecure)
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    // MARK: Setup

    private func setupTitle(_ text: String) {
        titleLabel.text      = text
        titleLabel.font      = BCTheme.Typography.subheadline
        titleLabel.textColor = BCTheme.Colors.textSecondary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
        ])
    }

    private func setupContainer() {
        container.backgroundColor = BCTheme.Colors.surface
        container.bcCornerRadius(BCTheme.Layout.radiusM)
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: BCTheme.Layout.fieldHeight),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupTextField(placeholder: String, icon: String?, isSecure: Bool) {
        textField.placeholder             = placeholder
        textField.font                    = BCTheme.Typography.body
        textField.textColor               = BCTheme.Colors.textPrimary
        textField.tintColor               = BCTheme.Colors.primary
        textField.autocapitalizationType  = .none
        textField.autocorrectionType      = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate                = self
        container.addSubview(textField)

        var leadingOffset: CGFloat = 20
        var trailingOffset: CGFloat = -20

        // Icon
        if let iconName = icon {
            let iv = UIImageView(image: UIImage(systemName: iconName))
            iv.tintColor   = BCTheme.Colors.textTertiary
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(iv)
            NSLayoutConstraint.activate([
                iv.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                iv.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                iv.widthAnchor.constraint(equalToConstant: 20),
                iv.heightAnchor.constraint(equalToConstant: 20),
            ])
            leadingOffset = 46
        }

        // Secure + eye toggle
        if isSecure {
            textField.isSecureTextEntry = true
            textField.textContentType   = .oneTimeCode // avoid strong-password autofill

            var config = UIButton.Configuration.plain()
            config.image = UIImage(systemName: "eye.slash.fill")
            config.baseForegroundColor = BCTheme.Colors.textTertiary
            let btn = UIButton(configuration: config)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.addTarget(self, action: #selector(toggleSecure), for: .touchUpInside)
            container.addSubview(btn)
            NSLayoutConstraint.activate([
                btn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
                btn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                btn.widthAnchor.constraint(equalToConstant: 44),
                btn.heightAnchor.constraint(equalToConstant: 44),
            ])
            eyeButton = btn
            trailingOffset = -48
        }

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leadingOffset),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: trailingOffset),
            textField.topAnchor.constraint(equalTo: container.topAnchor),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    // MARK: Actions

    @objc private func toggleSecure() {
        textField.isSecureTextEntry.toggle()
        let name = textField.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
        eyeButton?.setImage(UIImage(systemName: name), for: .normal)
    }

    // MARK: Focus styling

    func setFocused(_ focused: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.container.layer.borderWidth = focused ? 1.5 : 0
            self.container.layer.borderColor = focused
                ? BCTheme.Colors.primary.cgColor
                : UIColor.clear.cgColor
        }
    }

    // MARK: Responder

    @discardableResult
    override func becomeFirstResponder() -> Bool { textField.becomeFirstResponder() }

    @discardableResult
    override func resignFirstResponder() -> Bool { textField.resignFirstResponder() }

    override var isFirstResponder: Bool { textField.isFirstResponder }
}

extension BCTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) { setFocused(true) }
    func textFieldDidEndEditing(_ textField: UITextField)   { setFocused(false) }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        return true
    }
}

// MARK: - BCButton

/// Styled button with press animation, loading state, and consistent theming.
final class BCButton: UIButton {

    enum Style { case primary, secondary, destructive, ghost }

    private let style: Style
    private var originalTitle: String?

    var isLoading: Bool = false {
        didSet { updateLoadingState() }
    }

    init(title: String, style: Style = .primary) {
        self.style = style
        self.originalTitle = title
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        var config: UIButton.Configuration
        switch style {
        case .primary:
            config = .filled()
            config.baseBackgroundColor = BCTheme.Colors.primary
            config.baseForegroundColor = BCTheme.Colors.textOnPrimary
        case .secondary:
            config = .tinted()
            config.baseBackgroundColor = BCTheme.Colors.primarySoft
            config.baseForegroundColor = BCTheme.Colors.primary
        case .destructive:
            config = .filled()
            config.baseBackgroundColor = BCTheme.Colors.destructive
            config.baseForegroundColor = .white
        case .ghost:
            config = .plain()
            config.baseForegroundColor = BCTheme.Colors.primary
        }

        config.title       = title
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = BCTheme.Typography.bodyBold
            return out
        }
        configuration = config

        heightAnchor.constraint(equalToConstant: BCTheme.Layout.buttonHeight).isActive = true
        layer.cornerCurve = .continuous

        if style == .primary { BCTheme.Shadow.button(self) }

        addTarget(self, action: #selector(down), for: .touchDown)
        addTarget(self, action: #selector(up),   for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    @objc private func down() { BCTheme.Animation.pressDown(self) }
    @objc private func up()   { BCTheme.Animation.pressUp(self) }

    private func updateLoadingState() {
        configuration?.showsActivityIndicator = isLoading
        configuration?.title = isLoading ? "" : originalTitle
        isUserInteractionEnabled = !isLoading
        if style == .primary {
            layer.shadowOpacity = isLoading ? 0 : 0.25
        }
    }

    /// Update the button title
    func setTitle(_ title: String) {
        originalTitle = title
        configuration?.title = isLoading ? "" : title
    }
}

// MARK: - BCAvatar

/// Circular avatar with image loading, initials fallback, and online indicator.
final class BCAvatar: UIView {

    private let imageView    = UIImageView()
    private let initialsLbl  = UILabel()
    private let onlineDot    = UIView()
    private var loadTask: URLSessionDataTask?
    private let avatarSize: CGFloat

    init(size: CGFloat = BCTheme.Layout.avatarM) {
        self.avatarSize = size
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: avatarSize),
            heightAnchor.constraint(equalToConstant: avatarSize),
        ])

        // Image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = avatarSize / 2
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // Initials
        initialsLbl.textAlignment = .center
        initialsLbl.textColor = .white
        initialsLbl.font = .systemFont(ofSize: avatarSize * 0.38, weight: .bold)
        initialsLbl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(initialsLbl)
        NSLayoutConstraint.activate([
            initialsLbl.centerXAnchor.constraint(equalTo: centerXAnchor),
            initialsLbl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        // Online dot
        let dotSize: CGFloat = avatarSize >= 50 ? 14 : 10
        onlineDot.backgroundColor    = BCTheme.Colors.online
        onlineDot.layer.cornerRadius = dotSize / 2
        onlineDot.layer.borderWidth  = 2.5
        onlineDot.layer.borderColor  = UIColor.systemBackground.cgColor
        onlineDot.isHidden           = true
        onlineDot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(onlineDot)
        NSLayoutConstraint.activate([
            onlineDot.widthAnchor.constraint(equalToConstant: dotSize),
            onlineDot.heightAnchor.constraint(equalToConstant: dotSize),
            onlineDot.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 1),
            onlineDot.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 1),
        ])
    }

    /// Configure the avatar with a name and optional image URL.
    func configure(name: String, imageURL: URL? = nil, showOnline: Bool = false) {
        let initial = String(name.prefix(1)).uppercased()
        initialsLbl.text = initial
        imageView.backgroundColor = BCTheme.Colors.avatarColor(for: name)
        imageView.image = nil
        initialsLbl.isHidden = false
        onlineDot.isHidden = !showOnline

        loadTask?.cancel()
        if let url = imageURL {
            loadTask = ImageCache.shared.load(from: url) { [weak self] image in
                guard let self, let image else { return }
                self.imageView.image = image
                self.initialsLbl.isHidden = true
            }
        }
    }

    func configure(name: String, url: String?, showOnline: Bool = false) {
        configure(name: name, imageURL: Constants.mediaURL(from: url), showOnline: showOnline)
    }

    /// Reset for cell reuse
    func prepareForReuse() {
        loadTask?.cancel()
        loadTask = nil
        imageView.image = nil
        initialsLbl.text = nil
        onlineDot.isHidden = true
    }

    /// Update border colors after trait change
    func updateTraitColors() {
        onlineDot.layer.borderColor = UIColor.systemBackground.cgColor
    }
}

// MARK: - BCToast

/// Drop-in replacement for auto-dismissing UIAlertController.
/// Shows a slim banner at the top with icon + message.
enum BCToast {

    enum Style {
        case success, error, info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error:   return "exclamationmark.triangle.fill"
            case .info:    return "info.circle.fill"
            }
        }

        var tint: UIColor {
            switch self {
            case .success: return BCTheme.Colors.success
            case .error:   return BCTheme.Colors.destructive
            case .info:    return BCTheme.Colors.primary
            }
        }
    }

    static func show(_ message: String, style: Style = .info,
                     in view: UIView, duration: TimeInterval = 2.5) {
        let toast = UIView()
        toast.backgroundColor = BCTheme.Colors.surface
        toast.bcCornerRadius(BCTheme.Layout.radiusM)
        BCTheme.Shadow.elevated(toast)
        toast.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: style.icon))
        icon.tintColor   = style.tint
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 22).isActive = true

        let label = UILabel()
        label.text          = message
        label.font          = BCTheme.Typography.callout
        label.textColor     = BCTheme.Colors.textPrimary
        label.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis      = .horizontal
        stack.spacing    = 12
        stack.alignment  = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        toast.addSubview(stack)
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: toast.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: toast.bottomAnchor, constant: -14),
            stack.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -18),

            toast.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        // Entrance
        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: -30)
        UIView.animate(withDuration: 0.45, delay: 0,
                       usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5) {
            toast.alpha = 1
            toast.transform = .identity
        }

        // Exit
        UIView.animate(withDuration: 0.25, delay: duration, options: .curveEaseIn) {
            toast.alpha = 0
            toast.transform = CGAffineTransform(translationX: 0, y: -30)
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }

    static func show(_ message: String, style: Style = .info, duration: TimeInterval = 2.5) {
        guard let view = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return
        }
        show(message, style: style, in: view, duration: duration)
    }
}

// MARK: - BCEmptyState

/// Centered placeholder view for empty lists / zero states.
final class BCEmptyState: UIView {
    private let iconView = UIImageView()
    private let titleLbl = UILabel()
    private let subLbl = UILabel()

    convenience init(title: String, message: String? = nil, iconName: String) {
        self.init(icon: iconName, title: title, subtitle: message)
    }

    init(icon: String, title: String, subtitle: String? = nil) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = BCTheme.Colors.textTertiary
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 48, weight: .light
        )

        titleLbl.text      = title
        titleLbl.font      = BCTheme.Typography.headline
        titleLbl.textColor = BCTheme.Colors.textSecondary
        titleLbl.textAlignment = .center

        subLbl.text      = subtitle
        subLbl.font      = BCTheme.Typography.body
        subLbl.textColor = BCTheme.Colors.textTertiary
        subLbl.textAlignment = .center
        subLbl.numberOfLines = 0
        subLbl.isHidden = subtitle == nil

        let stack = UIStackView(arrangedSubviews: [iconView, titleLbl, subLbl])
        stack.axis      = .vertical
        stack.spacing    = 16
        stack.alignment  = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40),
        ])
    }

    func configure(title: String, message: String? = nil, iconName: String) {
        iconView.image = UIImage(systemName: iconName)
        titleLbl.text = title
        subLbl.text = message
        subLbl.isHidden = message == nil
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
}

// MARK: - BCSocialButton

/// Circular social login button (Google, Apple, Email, etc.)
final class BCSocialButton: UIButton {

    init(icon: String, isSystemIcon: Bool = true) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.plain()
        if isSystemIcon {
            config.image = UIImage(systemName: icon,
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
        } else {
            // For custom text-based icons like Google "G"
            config.title = icon
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var out = incoming
                out.font = UIFont.systemFont(ofSize: 20, weight: .bold)
                return out
            }
        }
        config.baseForegroundColor = BCTheme.Colors.textPrimary
        configuration = config

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 54),
            heightAnchor.constraint(equalToConstant: 54),
        ])
        bcCornerRadius(27)
        layer.borderWidth = 1
        layer.borderColor = BCTheme.Colors.textPrimary.withAlphaComponent(0.10).cgColor

        addTarget(self, action: #selector(down), for: .touchDown)
        addTarget(self, action: #selector(up),   for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    @objc private func down() { BCTheme.Animation.pressDown(self) }
    @objc private func up()   { BCTheme.Animation.pressUp(self) }

    func updateTraitBorder() {
        layer.borderColor = BCTheme.Colors.textPrimary.withAlphaComponent(0.10).cgColor
    }
}

// MARK: - Keyboard Dismiss

final class BCDismissKeyboardTapGesture: UITapGestureRecognizer, UIGestureRecognizerDelegate {

    init(targetView: UIView) {
        super.init(target: targetView, action: #selector(UIView.bcEndEditingFromGesture(_:)))
        cancelsTouchesInView = false
        delegate = self
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }
        if touchedView is UIControl { return false }
        if touchedView is UITextField || touchedView is UITextView { return false }
        if touchedView.bcIsDescendant(of: UITextField.self) { return false }
        if touchedView.bcIsDescendant(of: UITextView.self) { return false }
        if touchedView.bcIsDescendant(of: UISearchBar.self) { return false }
        return true
    }
}

extension UIView {
    @objc fileprivate func bcEndEditingFromGesture(_ gesture: UITapGestureRecognizer) {
        endEditing(true)
    }

    fileprivate func bcIsDescendant<T: UIView>(of type: T.Type) -> Bool {
        var candidate: UIView? = self
        while let view = candidate {
            if view is T { return true }
            candidate = view.superview
        }
        return false
    }
}

extension UIViewController {
    func installTapToDismissKeyboard() {
        view.addGestureRecognizer(BCDismissKeyboardTapGesture(targetView: view))
    }
}
