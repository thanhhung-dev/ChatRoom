//
//  ResetPasswordViewController.swift
//  BoxChat
//
//  Created by Dezhun on 7/6/26.
//


import UIKit

class ResetPasswordViewController: UIViewController {

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
        l.text = "Đặt lại mật khẩu"
        l.font = .systemFont(ofSize: 32, weight: .heavy)
        l.textColor = .label
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Tạo mật khẩu mới"
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = .secondaryLabel
        return l
    }()

    private lazy var newPasswordField: UITextField = createTextField(placeholder: "••••••••", title: "Mật khẩu mới", isSecure: true)
    private lazy var confirmPasswordField: UITextField = createTextField(placeholder: "••••••••", title: "Xác nhận mật khẩu", isSecure: true)

    private lazy var updateButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Cập nhật mật khẩu", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 24
        btn.layer.cornerCurve = .continuous
        btn.layer.shadowColor = UIColor.systemBlue.cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowRadius = 12
        btn.layer.shadowOffset = CGSize(width: 0, height: 6)
        btn.addTarget(self, action: #selector(updateTapped), for: .touchUpInside)
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

    // MARK: - Setup UI
    private func setupAmbientBackground() {
        ambientOrb1.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        ambientOrb1.frame = CGRect(x: -50, y: -50, width: 300, height: 300)
        ambientOrb1.layer.cornerRadius = 150
        ambientOrb1.layer.masksToBounds = true
        view.addSubview(ambientOrb1)
        
        ambientOrb2.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.1)
        ambientOrb2.frame = CGRect(x: view.bounds.width - 200, y: 400, width: 250, height: 250)
        ambientOrb2.layer.cornerRadius = 125
        ambientOrb2.layer.masksToBounds = true
        view.addSubview(ambientOrb2)
        
        view.addSubview(blurEffectView)
        
        animateOrbs()
    }

    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        let components = [backButton, titleLabel, subtitleLabel, newPasswordField, confirmPasswordField, updateButton]
        
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

            newPasswordField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            newPasswordField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            newPasswordField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            confirmPasswordField.topAnchor.constraint(equalTo: newPasswordField.bottomAnchor, constant: 24),
            confirmPasswordField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            confirmPasswordField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            updateButton.topAnchor.constraint(equalTo: confirmPasswordField.bottomAnchor, constant: 40),
            updateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            updateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            updateButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    // MARK: - Helpers
    private func createTextField(placeholder: String, title: String, isSecure: Bool) -> UITextField {
        let container = UITextField()
        container.placeholder = placeholder
        container.isSecureTextEntry = isSecure
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

    // MARK: - Actions & Animations
    private func animateOrbs() {
        UIView.animate(withDuration: 9.0, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.ambientOrb1.transform = CGAffineTransform(translationX: -30, y: 40).scaledBy(x: 1.15, y: 1.15)
            self.ambientOrb2.transform = CGAffineTransform(translationX: 40, y: -20).scaledBy(x: 1.1, y: 1.1)
        } completion: { _ in }
    }

    private func setupButtonAnimations() {
        updateButton.addTarget(self, action: #selector(btnDown(_:)), for: .touchDown)
        updateButton.addTarget(self, action: #selector(btnUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
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
        if let tf = sender.superview?.superview as? UITextField {
            tf.isSecureTextEntry = !sender.isSelected
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func updateTapped() {
        dismissKeyboard()
        navigationController?.popToRootViewController(animated: true)
    }
}
