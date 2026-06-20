import UIKit

class ForgotPasswordViewController: BaseAuthViewController {

    // MARK: - UI Components

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Chúng tôi sẽ gửi liên kết đặt lại mật khẩu đến email của bạn."
        label.font = BCTheme.Typography.body
        label.textColor = BCTheme.Colors.textSecondary
        label.numberOfLines = 0
        return label
    }()

    private lazy var emailField: BCTextField = {
        let field = BCTextField(title: "Email", placeholder: "nguyenvana@gmail.com", isSecure: false)
        field.textField.keyboardType = .emailAddress
        return field
    }()

    private lazy var sendLinkButton: BCButton = {
        let btn = BCButton(title: "Gửi liên kết", style: .primary)
        btn.addTarget(self, action: #selector(sendLinkTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "Quên mật khẩu"
        subtitleLabel.text = "Nhập email của bạn"

        setupForm()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    // MARK: - Setup

    private func setupForm() {
        contentStack.addArrangedSubview(descriptionLabel)
        addSpacing(32)
        contentStack.addArrangedSubview(emailField)
        addSpacing(40)
        contentStack.addArrangedSubview(sendLinkButton)
    }

    // MARK: - Actions

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    @objc private func sendLinkTapped() {
        dismissKeyboard()

        guard let email = emailField.text, !email.isEmpty else {
            showToast("Vui lòng nhập email", style: .error)
            return
        }

        if !isValidEmail(email) {
            showToast("Định dạng email không hợp lệ", style: .error)
            return
        }

        sendLinkButton.isLoading = true

        // Simulating network request for forgot password
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.sendLinkButton.isLoading = false
            let resetVC = ResetPasswordViewController()
            self?.navigationController?.pushViewController(resetVC, animated: true)
        }
    }
}
