import UIKit

final class CreateGroupViewController: UIViewController {
  var onDataChanged: (() -> Void)?

  private var selectedAvatar: UIImage?
  private var selectedSuggested = Set<Int>([0, 1])

  private let scrollView = UIScrollView()
  private let contentView = UIView()
  private let avatarButton = UIButton(type: .system)
  private let avatarImageView = UIImageView()
  private let cameraBadge = UIView()
  private let nameField = UITextField()
  private let descriptionField = UITextField()
  private let selectedMembersStack = UIStackView()
  private let suggestionsStack = UIStackView()

  private let selectedMembers = [
    ("Minh Anh", "MA"),
    ("Hoàng Nam", "HN"),
    ("Phương Linh", "PL"),
    ("Quang Huy", "QH"),
    ("Đức Duy", "ĐD"),
  ]

  private let suggestions = [
    ("Mai Phương", "MP"),
    ("Tuấn Anh", "TA"),
    ("Lê Thảo Vy", "TV"),
    ("Khánh Linh", "KL"),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    setupNavigation()
    setupLayout()
  }

  private func setupNavigation() {
    title = "Tạo nhóm"
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "xmark"),
      style: .plain,
      target: self,
      action: #selector(didTapClose)
    )
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Tiếp",
      style: .done,
      target: self,
      action: #selector(didTapNext)
    )
  }

  private func setupLayout() {
    view.addSubview(scrollView)
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
    ])

    setupAvatar()
    let nameSection = makeFieldSection(
      title: "Tên nhóm", field: nameField, placeholder: "Nhóm du lịch Đà Nẵng 🌴")
    let descriptionSection = makeFieldSection(
      title: "Mô tả nhóm (tùy chọn)", field: descriptionField,
      placeholder: "Cùng nhau khám phá những vùng đất mới ✈️")

    selectedMembersStack.axis = .vertical
    selectedMembersStack.spacing = 14
    let memberSection = makeSelectedMembersSection()

    suggestionsStack.axis = .vertical
    suggestionsStack.spacing = 2
    let suggestionSection = makeSuggestionsSection()

    let mainStack = UIStackView(arrangedSubviews: [
      avatarButton, nameSection, descriptionSection, memberSection, suggestionSection,
    ])
    mainStack.axis = .vertical
    mainStack.spacing = 24
    mainStack.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(mainStack)

    NSLayoutConstraint.activate([
      mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
      mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
      mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
      mainStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),
      avatarButton.heightAnchor.constraint(equalToConstant: 112),
    ])
  }

  private func setupAvatar() {
    avatarButton.addTarget(self, action: #selector(didTapAvatar), for: .touchUpInside)

    avatarImageView.image = UIImage(systemName: "person.3.fill")
    avatarImageView.tintColor = .systemGray
    avatarImageView.backgroundColor = .systemGray5
    avatarImageView.contentMode = .scaleAspectFill
    avatarImageView.layer.cornerRadius = 56
    avatarImageView.layer.cornerCurve = .continuous
    avatarImageView.clipsToBounds = true
    avatarImageView.translatesAutoresizingMaskIntoConstraints = false
    avatarButton.addSubview(avatarImageView)

    cameraBadge.backgroundColor = .systemBackground
    cameraBadge.layer.cornerRadius = 15
    cameraBadge.layer.shadowColor = UIColor.black.cgColor
    cameraBadge.layer.shadowOpacity = 0.12
    cameraBadge.layer.shadowRadius = 8
    cameraBadge.layer.shadowOffset = CGSize(width: 0, height: 3)
    cameraBadge.translatesAutoresizingMaskIntoConstraints = false
    avatarButton.addSubview(cameraBadge)

    let camera = UIImageView(image: UIImage(systemName: "camera.fill"))
    camera.tintColor = .systemBlue
    camera.contentMode = .scaleAspectFit
    camera.translatesAutoresizingMaskIntoConstraints = false
    cameraBadge.addSubview(camera)

    NSLayoutConstraint.activate([
      avatarImageView.centerXAnchor.constraint(equalTo: avatarButton.centerXAnchor),
      avatarImageView.topAnchor.constraint(equalTo: avatarButton.topAnchor),
      avatarImageView.widthAnchor.constraint(equalToConstant: 112),
      avatarImageView.heightAnchor.constraint(equalToConstant: 112),

      cameraBadge.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
      cameraBadge.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
      cameraBadge.widthAnchor.constraint(equalToConstant: 34),
      cameraBadge.heightAnchor.constraint(equalToConstant: 34),

      camera.centerXAnchor.constraint(equalTo: cameraBadge.centerXAnchor),
      camera.centerYAnchor.constraint(equalTo: cameraBadge.centerYAnchor),
      camera.widthAnchor.constraint(equalToConstant: 18),
      camera.heightAnchor.constraint(equalToConstant: 18),
    ])
  }

  private func makeFieldSection(title: String, field: UITextField, placeholder: String) -> UIView {
    let titleLabel = sectionTitle(title)
    field.placeholder = placeholder
    field.font = .systemFont(ofSize: 15, weight: .medium)
    field.backgroundColor = .secondarySystemBackground
    field.layer.cornerRadius = 14
    field.layer.borderWidth = 1
    field.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
    field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 48))
    field.leftViewMode = .always

    let stack = UIStackView(arrangedSubviews: [titleLabel, field])
    stack.axis = .vertical
    stack.spacing = 8
    field.heightAnchor.constraint(equalToConstant: 48).isActive = true
    return stack
  }

  private func makeSelectedMembersSection() -> UIView {
    let title = sectionTitle("Thành viên (5/100)")
    let grid = UIStackView()
    grid.axis = .vertical
    grid.spacing = 16

    for row in 0..<2 {
      let rowStack = UIStackView()
      rowStack.axis = .horizontal
      rowStack.spacing = 18
      rowStack.distribution = .fillEqually
      for col in 0..<3 {
        let index = row * 3 + col
        if index < selectedMembers.count {
          rowStack.addArrangedSubview(
            memberBubble(name: selectedMembers[index].0, initials: selectedMembers[index].1))
        } else {
          rowStack.addArrangedSubview(addMemberBubble())
        }
      }
      grid.addArrangedSubview(rowStack)
    }

    let stack = UIStackView(arrangedSubviews: [title, grid])
    stack.axis = .vertical
    stack.spacing = 12
    return stack
  }

  private func makeSuggestionsSection() -> UIView {
    let title = sectionTitle("Gợi ý thêm")
    suggestions.enumerated().forEach { index, item in
      suggestionsStack.addArrangedSubview(
        suggestionRow(index: index, name: item.0, initials: item.1))
    }
    let stack = UIStackView(arrangedSubviews: [title, suggestionsStack])
    stack.axis = .vertical
    stack.spacing = 10
    return stack
  }

  private func memberBubble(name: String, initials: String) -> UIView {
    let avatar = avatarLabel(initials: initials, size: 56)
    let close = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
    close.tintColor = .systemGray
    close.backgroundColor = .systemBackground
    close.layer.cornerRadius = 9
    close.translatesAutoresizingMaskIntoConstraints = false

    let label = UILabel()
    label.text = name
    label.font = .systemFont(ofSize: 12, weight: .bold)
    label.textAlignment = .center
    label.lineBreakMode = .byTruncatingTail

    let container = UIView()
    [avatar, close, label].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview($0)
    }

    NSLayoutConstraint.activate([
      avatar.topAnchor.constraint(equalTo: container.topAnchor),
      avatar.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 56),
      avatar.heightAnchor.constraint(equalToConstant: 56),
      close.trailingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 5),
      close.topAnchor.constraint(equalTo: avatar.topAnchor, constant: -5),
      close.widthAnchor.constraint(equalToConstant: 18),
      close.heightAnchor.constraint(equalToConstant: 18),
      label.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 6),
      label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
    return container
  }

  private func addMemberBubble() -> UIView {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "plus"), for: .normal)
    button.tintColor = .systemBlue
    button.layer.cornerRadius = 28
    button.layer.borderWidth = 1.5
    button.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.18).cgColor
    let container = UIView()
    button.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(button)
    NSLayoutConstraint.activate([
      button.topAnchor.constraint(equalTo: container.topAnchor),
      button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      button.widthAnchor.constraint(equalToConstant: 56),
      button.heightAnchor.constraint(equalToConstant: 56),
      button.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20),
    ])
    return container
  }

  private func suggestionRow(index: Int, name: String, initials: String) -> UIView {
    let row = UIButton(type: .system)
    row.tag = index
    row.addTarget(self, action: #selector(didTapSuggestion(_:)), for: .touchUpInside)
    row.contentHorizontalAlignment = .fill
    row.heightAnchor.constraint(equalToConstant: 54).isActive = true

    let avatar = avatarLabel(initials: initials, size: 34)
    let nameLabel = UILabel()
    nameLabel.text = name
    nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    nameLabel.textColor = .label

    let check = UIImageView(
      image: UIImage(
        systemName: selectedSuggested.contains(index) ? "checkmark.circle.fill" : "circle"))
    check.tintColor = selectedSuggested.contains(index) ? .systemBlue : .systemGray3
    check.tag = 99

    [avatar, nameLabel, check].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      row.addSubview($0)
    }

    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      avatar.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 34),
      avatar.heightAnchor.constraint(equalToConstant: 34),
      nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 14),
      nameLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      check.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      check.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      check.widthAnchor.constraint(equalToConstant: 24),
      check.heightAnchor.constraint(equalToConstant: 24),
    ])
    return row
  }

  private func sectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .systemFont(ofSize: 13, weight: .bold)
    label.textColor = .secondaryLabel
    return label
  }

  private func avatarLabel(initials: String, size: CGFloat) -> UILabel {
    let label = UILabel()
    label.text = initials
    label.font = .systemFont(ofSize: size > 40 ? 18 : 12, weight: .bold)
    label.textColor = .white
    label.textAlignment = .center
    label.backgroundColor = .systemBlue
    label.layer.cornerRadius = size / 2
    label.clipsToBounds = true
    return label
  }

  @objc private func didTapClose() {
    dismiss(animated: true)
  }

  @objc private func didTapAvatar() {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = .photoLibrary
    picker.allowsEditing = true
    present(picker, animated: true)
  }

  @objc private func didTapSuggestion(_ sender: UIButton) {
    if selectedSuggested.contains(sender.tag) {
      selectedSuggested.remove(sender.tag)
    } else {
      selectedSuggested.insert(sender.tag)
    }
    suggestionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    suggestions.enumerated().forEach { index, item in
      suggestionsStack.addArrangedSubview(
        suggestionRow(index: index, name: item.0, initials: item.1))
    }
  }

  @objc private func didTapNext() {
    let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !name.isEmpty else {
      showAlert("Vui lòng nhập tên nhóm.")
      return
    }

    navigationItem.rightBarButtonItem?.isEnabled = false
    NetworkManager.shared.createRoom(name: name, description: descriptionField.text) {
      [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        switch result {
        case .success(let room):
          if let selectedAvatar = self.selectedAvatar {
            RoomAvatarStore.shared.saveImage(selectedAvatar, roomId: room.id)
          }
          self.onDataChanged?()
          self.dismiss(animated: true)
        case .failure(let error):
          self.showAlert(error.localizedDescription)
        }
      }
    }
  }

  private func showAlert(_ message: String) {
    let alert = UIAlertController(title: "Thông báo", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}

extension CreateGroupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)
    let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
    selectedAvatar = image
    avatarImageView.image = image
    avatarImageView.contentMode = .scaleAspectFill
  }
}
