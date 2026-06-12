import CoreML
import UIKit
import UniformTypeIdentifiers

final class ChatRoomViewController: UIViewController {
  private let room: Room
  private var messages: [Message] = []
  private var reactionsByMessageId: [Int: String] = [:]
  private var localImagesByMessageId: [Int: UIImage] = [:]
  private var localIdSeed = -1
  private var isTyping = false

  private let smartReplyEngine = SmartReplyEngine()

  private let topBarView = UIView()
  private let backButton = UIButton(type: .system)
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let callButton = UIButton(type: .system)
  private let optionsButton = UIButton(type: .system)

  private let tableView = UITableView(frame: .zero, style: .plain)
  private let emptyStateLabel = UILabel()
  private let typingIndicatorLabel = UILabel()

  private let inputContainerView = UIView()
  private let smartReplyStack = UIStackView()

  private let pillContainerView = UIView()
  private let messageTextView = UITextView()
  private let placeholderLabel = UILabel()

  private let attachButton = UIButton(type: .system)
  private let emojiButton = UIButton(type: .system)
  private let micButton = UIButton(type: .system)
  private let sendButton = UIButton(type: .system)

  private var inputBottomConstraint: NSLayoutConstraint!

  init(room: Room) {
    self.room = room
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1.0)

    navigationController?.setNavigationBarHidden(true, animated: false)

    setupCustomTopBar()
    setupTableView()
    setupInputArea()
    setupEmptyState()
    setupKeyboardObservers()
    setupGestures()
    ensureCurrentUserLoaded()

    loadLocalMessages()
    loadMessageHistory()
    joinWebSocketRoom()
    updateSmartReplies(context: nil)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    scrollToBottom(animated: false)
    markMessagesAsRead()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: animated)
    joinWebSocketRoom()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sendStopTyping()
    guard isMovingFromParent || isBeingDismissed else { return }
    leaveWebSocketRoom()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private func setupCustomTopBar() {
    topBarView.backgroundColor = .white
    topBarView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(topBarView)

    topBarView.layer.shadowColor = UIColor.black.cgColor
    topBarView.layer.shadowOffset = CGSize(width: 0, height: 0.5)
    topBarView.layer.shadowOpacity = 0.08
    topBarView.layer.shadowRadius = 0

    backButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
    backButton.tintColor = .systemBlue
    backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
    backButton.translatesAutoresizingMaskIntoConstraints = false
    topBarView.addSubview(backButton)

    titleLabel.text = room.name
    titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
    titleLabel.textColor = .black

    subtitleLabel.text = "\(max(room.memberCount, 1)) thành viên"
    subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
    subtitleLabel.textColor = .systemGray

    let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    textStack.axis = .vertical
    textStack.alignment = .leading
    textStack.spacing = 2
    textStack.translatesAutoresizingMaskIntoConstraints = false
    topBarView.addSubview(textStack)

    callButton.setImage(UIImage(systemName: "phone"), for: .normal)
    callButton.tintColor = .systemBlue
    callButton.translatesAutoresizingMaskIntoConstraints = false
    topBarView.addSubview(callButton)

    optionsButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
    optionsButton.transform = CGAffineTransform(rotationAngle: .pi / 2)
    optionsButton.tintColor = .systemBlue
    optionsButton.addTarget(self, action: #selector(didTapInfo), for: .touchUpInside)
    optionsButton.translatesAutoresizingMaskIntoConstraints = false
    topBarView.addSubview(optionsButton)

    NSLayoutConstraint.activate([
      topBarView.topAnchor.constraint(equalTo: view.topAnchor),
      topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      topBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),

      backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 16),
      backButton.bottomAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: -10),
      backButton.widthAnchor.constraint(equalToConstant: 24),
      backButton.heightAnchor.constraint(equalToConstant: 24),

      textStack.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 14),
      textStack.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
      textStack.trailingAnchor.constraint(equalTo: callButton.leadingAnchor, constant: -10),

      optionsButton.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor, constant: -16),
      optionsButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
      optionsButton.widthAnchor.constraint(equalToConstant: 24),
      optionsButton.heightAnchor.constraint(equalToConstant: 24),

      callButton.trailingAnchor.constraint(equalTo: optionsButton.leadingAnchor, constant: -20),
      callButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
      callButton.widthAnchor.constraint(equalToConstant: 24),
      callButton.heightAnchor.constraint(equalToConstant: 24),
    ])
  }

  @objc private func didTapBack() {
    if let nav = navigationController, nav.viewControllers.first != self {
      nav.popViewController(animated: true)
    } else {
      dismiss(animated: true, completion: nil)
    }
  }

  private func setupTableView() {
    view.addSubview(tableView)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.identifier)
    tableView.separatorStyle = .none
    tableView.backgroundColor = .clear
    tableView.keyboardDismissMode = .interactive
    tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: topBarView.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }

  private func setupInputArea() {
    view.addSubview(inputContainerView)
    inputContainerView.translatesAutoresizingMaskIntoConstraints = false
    inputContainerView.backgroundColor = .white

    smartReplyStack.axis = .horizontal
    smartReplyStack.spacing = 8
    smartReplyStack.distribution = .fillProportionally
    smartReplyStack.translatesAutoresizingMaskIntoConstraints = false
    inputContainerView.addSubview(smartReplyStack)

    pillContainerView.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1.0)
    pillContainerView.layer.cornerRadius = 20
    pillContainerView.translatesAutoresizingMaskIntoConstraints = false
    inputContainerView.addSubview(pillContainerView)

    configureIconButton(attachButton, systemName: "face.dashed", action: #selector(didTapAttach))
    configureIconButton(emojiButton, systemName: "face.smiling", action: #selector(didTapEmoji))
    configureIconButton(micButton, systemName: "mic", action: #selector(didTapMic))

    sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
    sendButton.tintColor = .white
    sendButton.backgroundColor = .systemGray4
    sendButton.layer.cornerRadius = 18
    sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)
    sendButton.translatesAutoresizingMaskIntoConstraints = false
    inputContainerView.addSubview(sendButton)

    messageTextView.backgroundColor = .clear
    messageTextView.font = .systemFont(ofSize: 15)
    messageTextView.textContainerInset = UIEdgeInsets(top: 9, left: 4, bottom: 9, right: 4)
    messageTextView.isScrollEnabled = false
    messageTextView.delegate = self
    messageTextView.translatesAutoresizingMaskIntoConstraints = false
    pillContainerView.addSubview(messageTextView)

    placeholderLabel.text = "Nhập tin nhắn..."
    placeholderLabel.font = .systemFont(ofSize: 15)
    placeholderLabel.textColor = .systemGray3
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
    messageTextView.addSubview(placeholderLabel)

    pillContainerView.addSubview(attachButton)
    pillContainerView.addSubview(emojiButton)
    pillContainerView.addSubview(micButton)

    inputBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

    NSLayoutConstraint.activate([
      tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),

      inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      inputBottomConstraint,

      smartReplyStack.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
      smartReplyStack.leadingAnchor.constraint(
        equalTo: inputContainerView.leadingAnchor, constant: 16),
      smartReplyStack.trailingAnchor.constraint(
        lessThanOrEqualTo: inputContainerView.trailingAnchor, constant: -16),
      smartReplyStack.heightAnchor.constraint(equalToConstant: 32),

      pillContainerView.topAnchor.constraint(equalTo: smartReplyStack.bottomAnchor, constant: 8),
      pillContainerView.leadingAnchor.constraint(
        equalTo: inputContainerView.leadingAnchor, constant: 16),
      pillContainerView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
      pillContainerView.bottomAnchor.constraint(
        equalTo: inputContainerView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
      pillContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

      attachButton.leadingAnchor.constraint(equalTo: pillContainerView.leadingAnchor, constant: 6),
      attachButton.bottomAnchor.constraint(equalTo: pillContainerView.bottomAnchor, constant: -2),
      attachButton.widthAnchor.constraint(equalToConstant: 36),
      attachButton.heightAnchor.constraint(equalToConstant: 36),

      messageTextView.leadingAnchor.constraint(equalTo: attachButton.trailingAnchor, constant: 4),
      messageTextView.trailingAnchor.constraint(equalTo: emojiButton.leadingAnchor, constant: -4),
      messageTextView.topAnchor.constraint(equalTo: pillContainerView.topAnchor),
      messageTextView.bottomAnchor.constraint(equalTo: pillContainerView.bottomAnchor),
      messageTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 100),

      placeholderLabel.leadingAnchor.constraint(
        equalTo: messageTextView.leadingAnchor, constant: 8),
      placeholderLabel.centerYAnchor.constraint(equalTo: messageTextView.centerYAnchor),

      emojiButton.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -4),
      emojiButton.bottomAnchor.constraint(equalTo: pillContainerView.bottomAnchor, constant: -2),
      emojiButton.widthAnchor.constraint(equalToConstant: 32),
      emojiButton.heightAnchor.constraint(equalToConstant: 36),

      micButton.trailingAnchor.constraint(equalTo: pillContainerView.trailingAnchor, constant: -8),
      micButton.bottomAnchor.constraint(equalTo: pillContainerView.bottomAnchor, constant: -2),
      micButton.widthAnchor.constraint(equalToConstant: 32),
      micButton.heightAnchor.constraint(equalToConstant: 36),

      sendButton.trailingAnchor.constraint(
        equalTo: inputContainerView.trailingAnchor, constant: -16),
      sendButton.bottomAnchor.constraint(equalTo: pillContainerView.bottomAnchor, constant: -2),
      sendButton.widthAnchor.constraint(equalToConstant: 36),
      sendButton.heightAnchor.constraint(equalToConstant: 36),
    ])
  }

  private func setupEmptyState() {
    emptyStateLabel.text = "Chưa có tin nhắn. Hãy gửi tin đầu tiên."
    emptyStateLabel.font = .systemFont(ofSize: 14, weight: .medium)
    emptyStateLabel.textColor = .secondaryLabel
    emptyStateLabel.textAlignment = .center
    emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(emptyStateLabel)

    typingIndicatorLabel.font = .italicSystemFont(ofSize: 12)
    typingIndicatorLabel.textColor = .secondaryLabel
    typingIndicatorLabel.isHidden = true
    typingIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(typingIndicatorLabel)

    NSLayoutConstraint.activate([
      emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
      emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
      emptyStateLabel.leadingAnchor.constraint(
        greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
      emptyStateLabel.trailingAnchor.constraint(
        lessThanOrEqualTo: view.trailingAnchor, constant: -20),

      typingIndicatorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      typingIndicatorLabel.bottomAnchor.constraint(
        equalTo: inputContainerView.topAnchor, constant: -4),
    ])
  }

  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification,
      object: nil)
  }

  private func setupGestures() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tapGesture.cancelsTouchesInView = false
    tableView.addGestureRecognizer(tapGesture)

    let longPress = UILongPressGestureRecognizer(
      target: self, action: #selector(handleMessageLongPress(_:)))
    tableView.addGestureRecognizer(longPress)
  }

  private func configureIconButton(_ button: UIButton, systemName: String, action: Selector) {
    button.setImage(UIImage(systemName: systemName), for: .normal)
    button.tintColor = .systemGray2
    button.addTarget(self, action: action, for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
  }

  private func loadMessageHistory() {
    NetworkManager.shared.fetchMessages(roomId: room.id) { [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        if case .success(let response) = result {
          response.items.reversed().forEach { self.upsertIncomingMessage($0) }
          if let last = self.messages.last {
            WebSocketService.shared.localLastMessageIds[self.room.id] = last.id
          }
        }
        self.updateEmptyState()
      }
    }
  }

  private func loadLocalMessages() {
    messages = ChatLocalStore.shared.loadMessages(roomId: room.id)
    reactionsByMessageId = ChatLocalStore.shared.loadReactions(roomId: room.id)
    tableView.reloadData()
    updateEmptyState()
    scrollToBottom(animated: false)
  }

  private func ensureCurrentUserLoaded() {
    guard TokenManager.shared.currentUser == nil else { return }
    NetworkManager.shared.fetchMe { [weak self] result in
      if case .success(let user) = result {
        TokenManager.shared.currentUser = user
        DispatchQueue.main.async {
          self?.tableView.reloadData()
        }
      }
    }
  }

  private func joinWebSocketRoom() {
    WebSocketService.shared.addDelegate(self)
    WebSocketService.shared.connect()
    WebSocketService.shared.sendEvent(type: "join_room", payload: ["room_id": room.id])
  }

  private func leaveWebSocketRoom() {
    WebSocketService.shared.sendEvent(type: "leave_room", payload: ["room_id": room.id])
    WebSocketService.shared.removeDelegate(self)
  }

  @objc private func didTapSend() {
    let text = messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }

    let tempId = nextLocalId()
    let localMessage = makeLocalMessage(
      id: tempId, content: text, type: "text", fileUrl: nil, fileName: nil, status: "sending")
    appendMessage(localMessage)

    NetworkManager.shared.sendMessage(roomId: room.id, content: text) { [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        switch result {
        case .success(let saved):
          self.replaceLocalMessage(tempId, with: saved)
        case .failure:
          self.markLocalMessageSent(tempId)
        }
      }
    }

    messageTextView.text = ""
    textViewDidChange(messageTextView)
    sendStopTyping()
    updateSmartReplies(context: text)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
      self?.markLocalMessageSent(tempId)
    }
  }

  @objc private func didTapAttach() {
    let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    sheet.addAction(
      UIAlertAction(title: "Gửi ảnh", style: .default) { [weak self] _ in self?.openPhotoPicker() })
    sheet.addAction(
      UIAlertAction(title: "Gửi file", style: .default) { [weak self] _ in self?.openFilePicker() })
    sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
    present(sheet, animated: true)
  }

  @objc private func didTapEmoji() {
    showEmojiSheet { [weak self] emoji in
      guard let self else { return }
      self.messageTextView.text += emoji
      self.textViewDidChange(self.messageTextView)
      self.messageTextView.becomeFirstResponder()
    }
  }

  @objc private func didTapMic() {
    showNotice("Ghi âm sẽ cần backend lưu media. Hiện FE chỉ hỗ trợ chọn ảnh/file local.")
  }

  @objc private func didTapInfo() {
    navigationController?.pushViewController(GroupInfoViewController(room: room), animated: true)
  }

  private func openPhotoPicker() {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = .photoLibrary
    picker.allowsEditing = false
    present(picker, animated: true)
  }

  private func openFilePicker() {
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
    picker.delegate = self
    picker.allowsMultipleSelection = false
    present(picker, animated: true)
  }

  private func appendMessage(_ message: Message) {
    messages.append(message)
    persistLocalChat()
    updateEmptyState()
    tableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .automatic)
    scrollToBottom(animated: true)
  }

  private func makeLocalMessage(
    id: Int, content: String, type: String, fileUrl: String?, fileName: String?, status: String
  ) -> Message {
    let user = TokenManager.shared.currentUser
    return Message(
      id: id,
      roomId: room.id,
      userId: user?.id,
      username: user?.username,
      displayName: user?.displayName ?? user?.username,
      content: content,
      messageType: type,
      fileUrl: fileUrl,
      fileName: fileName,
      status: status
    )
  }

  private func nextLocalId() -> Int {
    defer { localIdSeed -= 1 }
    return localIdSeed
  }

  private func markLocalMessageSent(_ id: Int) {
    guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
    messages[index].status = "local"
    persistLocalChat()
    tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
  }

  private func replaceLocalMessage(_ id: Int, with saved: Message) {
    if let index = messages.firstIndex(where: { $0.id == id }) {
      messages[index] = saved
      persistLocalChat()
      tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    } else {
      upsertIncomingMessage(saved)
    }
  }

  private func upsertIncomingMessage(_ incoming: Message) {
    if let index = messages.firstIndex(where: { $0.id == incoming.id }) {
      messages[index] = incoming
      persistLocalChat()
      tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
      return
    }

    if isMessageFromCurrentUser(incoming),
      let pendingIndex = messages.firstIndex(where: {
        $0.id < 0 && $0.content == incoming.content && $0.messageType == incoming.messageType
      })
    {
      messages[pendingIndex] = incoming
      persistLocalChat()
      tableView.reloadRows(at: [IndexPath(row: pendingIndex, section: 0)], with: .automatic)
      return
    }

    appendMessage(incoming)
  }

  private func updateSmartReplies(context: String?) {
    smartReplyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    let replies = smartReplyEngine.suggestions(for: context)
    replies.forEach { text in
      let button = UIButton(type: .system)
      button.setTitle(text, for: .normal)
      button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
      button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
      button.backgroundColor = UIColor(red: 0.92, green: 0.94, blue: 0.97, alpha: 1.0)
      button.setTitleColor(.systemBlue, for: .normal)
      button.layer.cornerRadius = 14
      button.addAction(
        UIAction { [weak self] _ in
          self?.messageTextView.text = text
          self?.didTapSend()
        }, for: .touchUpInside)
      smartReplyStack.addArrangedSubview(button)
    }
  }

  private func showEmojiSheet(handler: @escaping (String) -> Void) {
    let sheet = UIAlertController(title: "Cảm xúc", message: nil, preferredStyle: .actionSheet)
    ["👍", "❤️", "😂", "🔥", "👏", "😮"].forEach { emoji in
      sheet.addAction(UIAlertAction(title: emoji, style: .default) { _ in handler(emoji) })
    }
    sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
    present(sheet, animated: true)
  }

  @objc private func handleMessageLongPress(_ recognizer: UILongPressGestureRecognizer) {
    guard recognizer.state == .began else { return }
    let point = recognizer.location(in: tableView)
    guard let indexPath = tableView.indexPathForRow(at: point) else { return }
    let message = messages[indexPath.row]

    showEmojiSheet { [weak self] emoji in
      guard let self else { return }
      self.reactionsByMessageId[message.id] = emoji
      self.persistLocalChat()
      self.tableView.reloadRows(at: [indexPath], with: .none)
    }
  }

  private func persistLocalChat() {
    ChatLocalStore.shared.saveMessages(messages, roomId: room.id)
    ChatLocalStore.shared.saveReactions(reactionsByMessageId, roomId: room.id)
  }

  private func markMessagesAsRead() {
    guard let last = messages.last else { return }
    WebSocketService.shared.sendEvent(
      type: "mark_read", payload: ["room_id": room.id, "message_id": last.id])
  }

  private func sendStopTyping() {
    guard isTyping else { return }
    isTyping = false
    WebSocketService.shared.sendEvent(type: "stop_typing", payload: ["room_id": room.id])
  }

  private func updateEmptyState() {
    emptyStateLabel.isHidden = !messages.isEmpty
  }

  private func scrollToBottom(animated: Bool = true) {
    guard !messages.isEmpty else { return }
    tableView.scrollToRow(
      at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: animated)
  }

  private func showNotice(_ message: String) {
    let alert = UIAlertController(title: "Thông báo", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }

  @objc private func dismissKeyboard() {
    view.endEditing(true)
  }

  @objc private func keyboardWillShow(_ notification: Notification) {
    guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
      let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
        as? Double
    else { return }
    inputBottomConstraint.constant = -frame.cgRectValue.height
    UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    scrollToBottom(animated: true)
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    let duration =
      notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
    inputBottomConstraint.constant = 0
    UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
  }
}

extension ChatRoomViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    messages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell =
      tableView.dequeueReusableCell(withIdentifier: MessageCell.identifier, for: indexPath)
      as! MessageCell
    let message = messages[indexPath.row]
    cell.configure(
      with: message,
      isMe: isMessageFromCurrentUser(message),
      reaction: reactionsByMessageId[message.id],
      localImage: localImagesByMessageId[message.id]
    )
    return cell
  }
}

extension ChatRoomViewController: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    let hasText = !text.isEmpty

    placeholderLabel.isHidden = !textView.text.isEmpty
    sendButton.backgroundColor = hasText ? .systemBlue : .systemGray4

    if hasText && !isTyping {
      isTyping = true
      WebSocketService.shared.sendEvent(type: "typing", payload: ["room_id": room.id])
    } else if !hasText {
      sendStopTyping()
    }
  }
}

extension ChatRoomViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)
    guard let image = info[.originalImage] as? UIImage else { return }

    let fileName = "image_\(Int(Date().timeIntervalSince1970)).jpg"
    let data = image.jpegData(compressionQuality: 0.72)
    let fileUrl = data.flatMap {
      ChatLocalStore.shared.persistAttachment($0, fileName: fileName)?.absoluteString
    }
    let id = nextLocalId()
    let message = makeLocalMessage(
      id: id, content: "", type: "file", fileUrl: fileUrl, fileName: fileName, status: "local")
    if fileUrl == nil {
      localImagesByMessageId[id] = image
    }
    appendMessage(message)

    if let data {
      NetworkManager.shared.uploadFile(
        roomId: room.id, fileData: data, fileName: fileName, mimeType: "image/jpeg"
      ) { [weak self] result in
        DispatchQueue.main.async {
          guard let self else { return }
          switch result {
          case .success(let saved):
            self.localImagesByMessageId.removeValue(forKey: id)
            self.replaceLocalMessage(id, with: saved)
          case .failure:
            self.markLocalMessageSent(id)
          }
        }
      }
    }
  }
}

extension ChatRoomViewController: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
  {
    guard let url = urls.first else { return }
    let didStartAccessing = url.startAccessingSecurityScopedResource()
    defer {
      if didStartAccessing { url.stopAccessingSecurityScopedResource() }
    }

    let data = try? Data(contentsOf: url)
    let persistedUrl =
      data.flatMap {
        ChatLocalStore.shared.persistAttachment($0, fileName: url.lastPathComponent)?.absoluteString
      } ?? url.absoluteString
    let id = nextLocalId()
    let message = makeLocalMessage(
      id: id,
      content: "Đã gửi file",
      type: "file",
      fileUrl: persistedUrl,
      fileName: url.lastPathComponent,
      status: "local"
    )
    appendMessage(message)

    if let data {
      NetworkManager.shared.uploadFile(
        roomId: room.id, fileData: data, fileName: url.lastPathComponent,
        mimeType: "application/octet-stream"
      ) { [weak self] result in
        DispatchQueue.main.async {
          guard let self else { return }
          switch result {
          case .success(let saved):
            self.replaceLocalMessage(id, with: saved)
          case .failure:
            self.markLocalMessageSent(id)
          }
        }
      }
    }
  }
}

extension ChatRoomViewController: WebSocketServiceDelegate {
  func webSocketDidConnect() {
    // Chỉ gửi join_room khi reconnect — KHÔNG gọi joinWebSocketRoom()
    // vì addDelegate đã được gọi từ trước, gọi lại sẽ gây nhận event trùng lặp
    WebSocketService.shared.sendEvent(type: "join_room", payload: ["room_id": room.id])
  }

  func webSocketDidDisconnect(error: Error?) {}

  func webSocketDidReceiveEvent(type: String, payload: [String: Any]) {
    switch type {
    case "new_message", "message_sent":
      guard let message = decodeMessage(from: payload) else { return }
      guard message.roomId == room.id else { return }
      upsertIncomingMessage(message)
      WebSocketService.shared.localLastMessageIds[room.id] = message.id
      markMessagesAsRead()
      if !isMessageFromCurrentUser(message) {
        updateSmartReplies(context: message.content)
      }

    case "typing_indicator":
      guard let roomId = payload["room_id"] as? Int, roomId == room.id else { return }
      let username = payload["username"] as? String ?? "Ai đó"
      let active = payload["is_typing"] as? Bool ?? false
      typingIndicatorLabel.text = active ? "\(username) đang soạn tin nhắn..." : nil
      typingIndicatorLabel.isHidden = !active

    // FIX: server gửi "sync_response", không phải "sync_messages"
    case "sync_response":
      guard let roomId = payload["room_id"] as? Int, roomId == room.id,
        let list = payload["messages"] as? [[String: Any]]
      else { return }
      list.compactMap { decodeMessageObject($0) }.forEach { upsertIncomingMessage($0) }
      if let lastId = messages.last?.id {
        WebSocketService.shared.localLastMessageIds[room.id] = lastId
      }

    default:
      break
    }
  }

  private func decodeMessage(from payload: [String: Any]) -> Message? {
    if let dictionary = payload["message"] as? [String: Any] {
      return Message.fromWebSocketPayload(dictionary, defaultRoomId: room.id)
    }
    return Message.fromWebSocketPayload(payload, defaultRoomId: room.id)
  }

  private func isMessageFromCurrentUser(_ message: Message) -> Bool {
    if message.id < 0 { return true }
    guard let currentUser = TokenManager.shared.currentUser else { return false }
    if message.userId == currentUser.id { return true }
    if message.username == currentUser.username { return true }
    if let displayName = message.displayName,
      let currentDisplayName = currentUser.displayName,
      displayName == currentDisplayName
    {
      return true
    }
    return false
  }

  private func isMessageFromCurrentUser(_ message: Message) -> Bool {
    if message.id < 0 { return true }
    guard let currentUser = TokenManager.shared.currentUser else { return false }
    if message.userId == currentUser.id { return true }
    if message.username == currentUser.username { return true }
    if let displayName = message.displayName,
      let currentDisplayName = currentUser.displayName,
      displayName == currentDisplayName
    {
      return true
    }
    return false
  }
}

private final class SmartReplyEngine {
  func suggestions(for context: String?) -> [String] {
    let lower = (context ?? "").lowercased()
    if lower.contains("update") || lower.contains("check") {
      return ["Để tôi check", "Ok, gửi tôi xem", "Đã rõ"]
    }
    if lower.contains("đẹp") || lower.contains("tuyệt") || lower.contains("hay") {
      return ["Chuẩn đó", "Mình thích ý này", "Quá ổn"]
    }
    if lower.contains("?") {
      return ["Ok để tôi xem", "Tôi trả lời sau", "Được nhé"]
    }
    return ["Ok luôn", "Để tôi check", "Tuyệt vời"]
  }
}
