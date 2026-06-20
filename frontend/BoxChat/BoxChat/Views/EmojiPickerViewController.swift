import UIKit

final class EmojiPickerViewController: UIViewController {
  private struct Section {
    let title: String
    let emojis: [String]
  }

  private let sections: [Section] = [
    Section(title: "Hay dùng", emojis: ["👍", "❤️", "😂", "🤣", "😍", "🥰", "😮", "😢", "🔥", "👏", "🙏", "🎉"]),
    Section(title: "Mặt cười", emojis: ["😀", "😃", "😄", "😁", "😆", "😅", "🙂", "🙃", "😉", "😊", "😇", "🥹", "🥲", "😋", "😛", "😜", "🤪", "😎", "🥳", "🤩", "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "☹️", "😣", "😖", "😫", "😩", "🥺", "😭", "😤", "😠", "😡", "🤬", "🤯", "😳", "🥵", "🥶", "😱", "😨", "😰", "😥", "😓", "🤗", "🤔", "🫡", "🤭", "🫢", "🫣", "🤫", "🤥", "😶", "😐", "😑", "😬", "🙄", "😯", "😦", "😧", "😮‍💨", "😴", "🤤", "😪", "😵", "🤐", "🥴", "🤢", "🤮", "🤧", "😷", "🤒", "🤕"]),
    Section(title: "Tay & người", emojis: ["👋", "🤚", "🖐️", "✋", "🖖", "👌", "🤌", "🤏", "✌️", "🤞", "🫰", "🤟", "🤘", "🤙", "👈", "👉", "👆", "👇", "☝️", "🫵", "👍", "👎", "✊", "👊", "🤛", "🤜", "👏", "🙌", "🫶", "🤲", "🤝", "🙏", "💪", "🧠", "👀", "💃", "🕺", "🏃", "🚶", "🧘"]),
    Section(title: "Trái tim", emojis: ["❤️", "🩷", "🧡", "💛", "💚", "💙", "🩵", "💜", "🖤", "🩶", "🤍", "🤎", "💔", "❤️‍🔥", "❤️‍🩹", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟"]),
    Section(title: "Thiên nhiên", emojis: ["✨", "⭐️", "🌟", "💫", "⚡️", "☄️", "💥", "🔥", "🌈", "☀️", "🌤️", "⛅️", "🌧️", "⛈️", "🌙", "☁️", "❄️", "💧", "🌊", "🍀", "🌱", "🌿", "🌵", "🌴", "🌸", "🌹", "🌻", "🌺", "🌷", "🍁", "🍂", "🌍", "🌎", "🌏"]),
    Section(title: "Ăn uống", emojis: ["🍎", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍒", "🥭", "🍍", "🥥", "🥝", "🍅", "🥑", "🥦", "🌽", "🥕", "🍞", "🥐", "🥨", "🧀", "🍗", "🍔", "🍟", "🍕", "🌭", "🥪", "🌮", "🍜", "🍣", "🍙", "🍰", "🎂", "🍩", "🍪", "☕️", "🧋", "🍻"]),
    Section(title: "Đi lại", emojis: ["🚗", "🚕", "🚙", "🚌", "🏎️", "🚓", "🚑", "🚒", "🚲", "🛵", "🏍️", "✈️", "🚀", "🛸", "🚁", "⛵️", "🚢", "🚉", "🚇", "🏠", "🏢", "🏫", "🏥", "🏝️", "🏔️", "🌋", "🗽", "🗼", "🎡", "🎢"]),
    Section(title: "Đồ vật", emojis: ["🎁", "🎈", "🎉", "🏆", "🥇", "🎧", "🎤", "🎬", "🎮", "🎲", "📱", "💻", "⌚️", "📷", "💡", "🔦", "📌", "📎", "✏️", "📚", "🔒", "🔑", "🧸", "🛒", "💰", "💳", "💎", "🧲", "🧪", "🩺"]),
    Section(title: "Ký hiệu", emojis: ["✅", "☑️", "✔️", "❌", "⭕️", "🚫", "⚠️", "‼️", "⁉️", "❓", "❗️", "💯", "🔴", "🟠", "🟡", "🟢", "🔵", "🟣", "⚫️", "⚪️", "⬆️", "⬇️", "⬅️", "➡️", "🔁", "▶️", "⏸️", "⏹️", "🔔", "🔕"]),
  ]

  var onSelect: ((String) -> Void)?

  private let collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 10
    layout.minimumInteritemSpacing = 8
    layout.headerReferenceSize = CGSize(width: 1, height: 32)
    return UICollectionView(frame: .zero, collectionViewLayout: layout)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    title = "Cảm xúc"
    setupCollection()
  }

  private func setupCollection() {
    collectionView.backgroundColor = .systemBackground
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.identifier)
    collectionView.register(
      EmojiHeaderView.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: EmojiHeaderView.identifier)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

extension EmojiPickerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    sections.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    sections[section].emojis.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCell.identifier, for: indexPath) as! EmojiCell
    cell.configure(sections[indexPath.section].emojis[indexPath.item])
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    onSelect?(sections[indexPath.section].emojis[indexPath.item])
    dismiss(animated: true)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let columns: CGFloat = 7
    let totalSpacing: CGFloat = (columns - 1) * 8
    let width = floor((collectionView.bounds.width - totalSpacing) / columns)
    return CGSize(width: width, height: 44)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath
  ) -> UICollectionReusableView {
    let header = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: EmojiHeaderView.identifier,
      for: indexPath) as! EmojiHeaderView
    header.configure(sections[indexPath.section].title)
    return header
  }
}

private final class EmojiCell: UICollectionViewCell {
  static let identifier = "EmojiCell"
  private let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .secondarySystemGroupedBackground
    contentView.layer.cornerRadius = 12
    label.font = .systemFont(ofSize: 28)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: contentView.topAnchor),
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ emoji: String) {
    label.text = emoji
  }
}

private final class EmojiHeaderView: UICollectionReusableView {
  static let identifier = "EmojiHeaderView"
  private let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    label.font = .systemFont(ofSize: 13, weight: .bold)
    label.textColor = .secondaryLabel
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
      label.trailingAnchor.constraint(equalTo: trailingAnchor),
      label.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ title: String) {
    label.text = title
  }
}
