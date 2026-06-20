//
//  BaseAuthViewController.swift
//  BoxChat
//
//  Shared base class for all authentication screens.
//  Provides: ambient orb background, blur overlay, scroll view
//  for keyboard avoidance, back button, title/subtitle, and helpers.
//

import UIKit

class BaseAuthViewController: UIViewController {

    // MARK: - UI (accessible to subclasses)

    /// Scroll view that provides keyboard avoidance
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .interactive
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    /// Main vertical stack — subclasses add their form fields here
    let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis    = .vertical
        s.spacing = 0
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private(set) lazy var backButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(
            systemName: "arrow.left",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        )
        config.baseForegroundColor = BCTheme.Colors.primary
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        return btn
    }()

    let titleLabel: UILabel = {
        let l = UILabel()
        l.font      = BCTheme.Typography.largeTitle
        l.textColor = BCTheme.Colors.textPrimary
        return l
    }()

    let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font          = BCTheme.Typography.body
        l.textColor     = BCTheme.Colors.textSecondary
        l.numberOfLines = 0
        return l
    }()

    // MARK: - Private

    private let orb1 = UIView()
    private let orb2 = UIView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private var scrollBottomConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .systemBackground

        setupBackground()
        setupScrollView()
        setupHeader()
        registerKeyboard()
        installTapToDismissKeyboard()

        // Dynamic trait change (iOS 17+)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
            (vc: BaseAuthViewController, _: UITraitCollection) in
            vc.updateOrbColors()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Background

    private func setupBackground() {
        orb1.frame           = CGRect(x: -50, y: -50, width: 300, height: 300)
        orb1.backgroundColor = BCTheme.Colors.orbBlue
        orb1.layer.cornerRadius = 150
        view.addSubview(orb1)

        orb2.frame           = CGRect(x: view.bounds.width - 100,
                                      y: view.bounds.height * 0.4,
                                      width: 250, height: 250)
        orb2.backgroundColor = BCTheme.Colors.orbPurple
        orb2.layer.cornerRadius = 125
        view.addSubview(orb2)

        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)

        animateOrbs()
    }

    private func animateOrbs() {
        UIView.animate(withDuration: 8, delay: 0,
                       options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.orb1.transform = CGAffineTransform(translationX: 80, y: 120)
                .scaledBy(x: 1.15, y: 1.15)
        }
        UIView.animate(withDuration: 9, delay: 0.5,
                       options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.orb2.transform = CGAffineTransform(translationX: -60, y: -100)
                .scaledBy(x: 1.1, y: 1.1)
        }
    }

    private func updateOrbColors() {
        orb1.backgroundColor = BCTheme.Colors.orbBlue
        orb2.backgroundColor = BCTheme.Colors.orbPurple
    }

    // MARK: - Scroll View

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        scrollBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollBottomConstraint,

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor,
                                                  constant: BCTheme.Layout.horizontalMargin),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor,
                                                   constant: -BCTheme.Layout.horizontalMargin),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor,
                                                constant: -2 * BCTheme.Layout.horizontalMargin),
        ])
    }

    // MARK: - Header

    private func setupHeader() {
        addSpacing(16)

        backButton.contentHorizontalAlignment = .leading
        contentStack.addArrangedSubview(backButton)

        addSpacing(24)
        contentStack.addArrangedSubview(titleLabel)
        addSpacing(8)
        contentStack.addArrangedSubview(subtitleLabel)
        addSpacing(32)
    }

    // MARK: - Keyboard

    private func registerKeyboard() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
    }

    @objc private func keyboardWillChange(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let dur   = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let kbHeight = view.frame.height - frame.origin.y
        scrollBottomConstraint.constant = -kbHeight

        UIView.animate(withDuration: dur, delay: 0,
                       options: UIView.AnimationOptions(rawValue: curve << 16)) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Helpers

    @objc func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    /// Insert a fixed-height spacer into the content stack
    func addSpacing(_ height: CGFloat) {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        contentStack.addArrangedSubview(spacer)
    }

    /// Show a toast banner (replaces showAlert / UIAlertController)
    func showToast(_ message: String, style: BCToast.Style = .error) {
        BCToast.show(message, style: style, in: view)
    }

    /// Create a divider row: ——— hoặc ———
    func makeDividerRow(text: String = "hoặc") -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let left = UIView()
        left.backgroundColor = BCTheme.Colors.separatorLight
        left.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text      = text
        label.font      = BCTheme.Typography.caption
        label.textColor = BCTheme.Colors.textTertiary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let right = UIView()
        right.backgroundColor = BCTheme.Colors.separatorLight
        right.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(left)
        container.addSubview(label)
        container.addSubview(right)

        NSLayoutConstraint.activate([
            left.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            left.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            left.heightAnchor.constraint(equalToConstant: 1),
            left.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -16),

            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            right.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16),
            right.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            right.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            right.heightAnchor.constraint(equalToConstant: 1),
        ])

        return container
    }

    /// Create the social buttons row (Google, Apple, Email)
    func makeSocialRow() -> UIStackView {
        let google = BCSocialButton(icon: "G", isSystemIcon: false)
        let apple  = BCSocialButton(icon: "apple.logo")
        let email  = BCSocialButton(icon: "envelope.fill")

        let stack = UIStackView(arrangedSubviews: [google, apple, email])
        stack.axis         = .horizontal
        stack.spacing       = 20
        stack.alignment     = .center
        stack.distribution  = .equalCentering
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Center the row
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            stack.topAnchor.constraint(equalTo: wrapper.topAnchor),
            stack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])

        return UIStackView(arrangedSubviews: [wrapper])
    }

    /// Create footer link text ("Chưa có tài khoản? Đăng ký")
    func makeFooterLink(prefix: String, action: String, target: Selector) -> UIView {
        let btn = UIButton(type: .system)
        let full = NSMutableAttributedString(
            string: prefix + " ",
            attributes: [
                .font: BCTheme.Typography.callout,
                .foregroundColor: BCTheme.Colors.textSecondary,
            ]
        )
        full.append(NSAttributedString(
            string: action,
            attributes: [
                .font: BCTheme.Typography.calloutBold,
                .foregroundColor: BCTheme.Colors.primary,
            ]
        ))
        btn.setAttributedTitle(full, for: .normal)
        btn.addTarget(self, action: target, for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }
}
