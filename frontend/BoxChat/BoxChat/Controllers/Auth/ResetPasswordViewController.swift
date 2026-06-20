import UIKit

class ResetPasswordViewController: BaseAuthViewController {

    // MARK: - UI Components

    private lazy var newPasswordField: BCTextField = {
        let field = BCTextField(title: "Mật khẩu mới", placeholder: "••••••••", isSecure: true)
        return field
    }()

    private lazy var confirmPasswordField: BCTextField = {
        let field = BCTextField(title: "Xác nhận mật khẩu", placeholder: "••••••••", isSecure: true)
        return field
    }()

    private lazy var updateButton: BCButton = {
        let btn = BCButton(title: "Cập nhật mật khẩu", style: .primary)
        btn.addTarget(self, action: #selector(updateTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "Đặt lại mật khẩu"
        subtitleLabel.text = "Tạo mật khẩu mới"

        setupForm()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    // MARK: - Setup

    private func setupForm() {
        contentStack.addArrangedSubview(newPasswordField)
        addSpacing(24)
        contentStack.addArrangedSubview(confirmPasswordField)
        addSpacing(40)
        contentStack.addArrangedSubview(updateButton)
    }

    // MARK: - Actions

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func updateTapped() {
        dismissKeyboard()

        guard let newPassword = newPasswordField.text, !newPassword.isEmpty,
              let confirmPassword = confirmPasswordField.text, !confirmPassword.isEmpty else {
            showToast("Vui lòng nhập đầy đủ thông tin", style: .error)
            return
        }

        if newPassword.count < 8 {
            showToast("Mật khẩu phải có ít nhất 8 ký tự", style: .error)
            return
        }

        if newPassword != confirmPassword {
            showToast("Mật khẩu xác nhận không khớp", style: .error)
            return
        }

        updateButton.isLoading = true

        // Simulating network request for password update
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updateButton.isLoading = false
            self?.showToast("Cập nhật thành công!", style: .success)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}
