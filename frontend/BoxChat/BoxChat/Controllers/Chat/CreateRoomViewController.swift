import UIKit

class CreateRoomViewController: UIViewController {

    var onDataChanged: (() -> Void)?
    private var isCreateMode = true

    private let glassCardView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let v = UIVisualEffectView(effect: blurEffect)
        v.layer.cornerRadius = BCTheme.Layout.radiusXL
        v.layer.masksToBounds = true
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        return v
    }()

    private lazy var segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Tạo Phòng Mới", "Tham Gia Bằng Mã"])
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = BCTheme.Colors.primary
        sc.setTitleTextAttributes([.foregroundColor: BCTheme.Colors.textSecondary], for: .normal)
        sc.setTitleTextAttributes([.foregroundColor: BCTheme.Colors.textOnPrimary], for: .selected)
        sc.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return sc
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Kênh Trò Chuyện"
        l.font = BCTheme.Typography.title1
        l.textColor = BCTheme.Colors.textPrimary
        l.textAlignment = .center
        return l
    }()

    private lazy var mainInputField = BCTextField(title: "Tên phòng chat", placeholder: "Tên phòng chat (bắt buộc)", icon: "bubble.left.and.bubble.right.fill")
    private lazy var subInputField = BCTextField(title: "Mô tả", placeholder: "Mô tả ngắn (không bắt buộc)", icon: "doc.text.fill")

    private lazy var actionButton: BCButton = {
        let b = BCButton(title: "Xác Nhận Tạo", style: .primary)
        b.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupLayout()
        installTapToDismissKeyboard()
    }

    private func setupLayout() {
        view.addSubview(glassCardView)
        glassCardView.translatesAutoresizingMaskIntoConstraints = false
        let inputStack = UIStackView(arrangedSubviews: [mainInputField, subInputField])
        inputStack.axis = .vertical
        inputStack.spacing = 14
        let containerStack = UIStackView(arrangedSubviews: [titleLabel, segmentControl, inputStack, actionButton])
        containerStack.axis = .vertical
        containerStack.spacing = 22
        containerStack.setCustomSpacing(12, after: titleLabel)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        glassCardView.contentView.addSubview(containerStack)
        NSLayoutConstraint.activate([
            glassCardView.topAnchor.constraint(equalTo: view.topAnchor),
            glassCardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            glassCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerStack.topAnchor.constraint(equalTo: glassCardView.topAnchor, constant: 28),
            containerStack.leadingAnchor.constraint(equalTo: glassCardView.leadingAnchor, constant: 24),
            containerStack.trailingAnchor.constraint(equalTo: glassCardView.trailingAnchor, constant: -24),
            segmentControl.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func segmentChanged() {
        isCreateMode = segmentControl.selectedSegmentIndex == 0
        dismissKeyboard()
        UIView.transition(with: view, duration: 0.25, options: .transitionCrossDissolve) {
            if self.isCreateMode {
                self.mainInputField.textField.placeholder = "Tên phòng chat (bắt buộc)"
                self.mainInputField.text = ""
                self.subInputField.isHidden = false
                self.actionButton.setTitle("Xác Nhận Tạo")
            } else {
                self.mainInputField.textField.placeholder = "Nhập mã mời (Ví dụ: DESIGN003)"
                self.mainInputField.text = ""
                self.subInputField.isHidden = true
                self.actionButton.setTitle("Tham Gia Ngay")
            }
        }
    }

    @objc private func didTapActionButton() {
        guard let firstInput = mainInputField.text, !firstInput.isEmpty else {
            showAlert(message: isCreateMode ? "Vui lòng nhập tên phòng chat." : "Vui lòng nhập mã mời.")
            return
        }
        dismissKeyboard()
        setLoading(true)
        if isCreateMode {
            NetworkManager.shared.createRoom(name: firstInput, description: subInputField.text) { [weak self] result in
                DispatchQueue.main.async {
                    self?.setLoading(false)
                    switch result {
                    case .success:
                        self?.onDataChanged?()
                        self?.dismiss(animated: true)
                    case .failure(let error):
                        self?.showAlert(message: "Không thể tạo phòng: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            NetworkManager.shared.joinRoom(inviteCode: firstInput) { [weak self] result in
                DispatchQueue.main.async {
                    self?.setLoading(false)
                    switch result {
                    case .success:
                        self?.onDataChanged?()
                        self?.dismiss(animated: true)
                    case .failure:
                        self?.showAlert(message: "Mã mời không chính xác hoặc phòng không tồn tại.")
                    }
                }
            }
        }
    }

    private func setLoading(_ isLoading: Bool) {
        actionButton.isLoading = isLoading
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Thông báo", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đã hiểu", style: .default))
        present(alert, animated: true)
    }
}
