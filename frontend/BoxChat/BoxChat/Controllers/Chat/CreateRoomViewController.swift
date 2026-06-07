import UIKit

class CreateRoomViewController: UIViewController {

    var onDataChanged: (() -> Void)?
    private var isCreateMode = true

    private let glassCardView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let v = UIVisualEffectView(effect: blurEffect)
        v.layer.cornerRadius = 30
        v.layer.masksToBounds = true
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        return v
    }()

    private let segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Tạo Phòng Mới", "Tham Gia Bằng Mã"])
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = .systemBlue
        sc.setTitleTextAttributes([.foregroundColor: UIColor.secondaryLabel], for: .normal)
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sc.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return sc
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Kênh Trò Chuyện"
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()

    private lazy var mainInputField: UITextField = createCustomTextField(placeholder: "Tên phòng chat (bắt buộc)", iconName: "bubble.left.and.bubble.right.fill")
    private lazy var subInputField: UITextField = createCustomTextField(placeholder: "Mô tả ngắn (không bắt buộc)", iconName: "doc.text.fill")

    private let actionButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Xác Nhận", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        b.backgroundColor = .systemBlue
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 22
        b.layer.shadowColor = UIColor.systemBlue.cgColor
        b.layer.shadowOpacity = 0.3
        b.layer.shadowRadius = 8
        b.layer.shadowOffset = CGSize(width: 0, height: 4)
        b.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        return b
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = .white
        ai.hidesWhenStopped = true
        return ai
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupLayout()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
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
        actionButton.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            glassCardView.topAnchor.constraint(equalTo: view.topAnchor),
            glassCardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            glassCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerStack.topAnchor.constraint(equalTo: glassCardView.topAnchor, constant: 28),
            containerStack.leadingAnchor.constraint(equalTo: glassCardView.leadingAnchor, constant: 24),
            containerStack.trailingAnchor.constraint(equalTo: glassCardView.trailingAnchor, constant: -24),
            segmentControl.heightAnchor.constraint(equalToConstant: 36),
            mainInputField.heightAnchor.constraint(equalToConstant: 52),
            subInputField.heightAnchor.constraint(equalToConstant: 52),
            actionButton.heightAnchor.constraint(equalToConstant: 48),
            activityIndicator.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor)
        ])
    }

    private func createCustomTextField(placeholder: String, iconName: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = .systemFont(ofSize: 15)
        tf.backgroundColor = UIColor.label.withAlphaComponent(0.04)
        tf.layer.cornerRadius = 14
        tf.clipsToBounds = true
        tf.clearButtonMode = .whileEditing
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        let iconContainer = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 52))
        iconView.frame = CGRect(x: 14, y: 17, width: 18, height: 18)
        iconContainer.addSubview(iconView)
        tf.leftView = iconContainer
        tf.leftViewMode = .always
        return tf
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func segmentChanged() {
        isCreateMode = segmentControl.selectedSegmentIndex == 0
        dismissKeyboard()
        UIView.transition(with: view, duration: 0.25, options: .transitionCrossDissolve) {
            if self.isCreateMode {
                self.mainInputField.placeholder = "Tên phòng chat (bắt buộc)"
                self.mainInputField.text = ""
                self.subInputField.isHidden = false
                self.actionButton.setTitle("Xác Nhận Tạo", for: .normal)
            } else {
                self.mainInputField.placeholder = "Nhập mã mời (Ví dụ: DESIGN003)"
                self.mainInputField.text = ""
                self.subInputField.isHidden = true
                self.actionButton.setTitle("Tham Gia Ngay", for: .normal)
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
        if isLoading {
            activityIndicator.startAnimating()
            actionButton.setTitle("", for: .normal)
            actionButton.isEnabled = false
        } else {
            activityIndicator.stopAnimating()
            actionButton.setTitle(isCreateMode ? "Xác Nhận Tạo" : "Tham Gia Ngay", for: .normal)
            actionButton.isEnabled = true
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Thông báo", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đã hiểu", style: .default))
        present(alert, animated: true)
    }
}
