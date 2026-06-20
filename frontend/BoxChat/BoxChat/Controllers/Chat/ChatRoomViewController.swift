import AVFoundation
import AVKit
import CoreML
import QuickLook
import UIKit
import UniformTypeIdentifiers

private enum MediaKind {
  case image
  case video
  case audio
}

final class ChatRoomViewController: UIViewController {
  private let room: Room
  private var messages: [Message] = []
  private var reactionsByMessageId: [Int: String] = [:]
  private var localImagesByMessageId: [Int: UIImage] = [:]
  private var localIdSeed = -1
  private var isTyping = false
  private var audioRecorder: AVAudioRecorder?
  private var recordingURL: URL?
  private var previewFileURL: URL?

  private let smartReplyEngine = SmartReplyEngine()

  private let topBarView = UIView()
  private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
  private let backButton = UIButton(type: .system)
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let callButton = UIButton(type: .system)
  private let optionsButton = UIButton(type: .system)

  private let tableView = UITableView(frame: .zero, style: .plain)
  private lazy var emptyStateView = BCEmptyState(
    title: "Chưa có tin nhắn",
    message: "Hãy gửi tin đầu tiên.",
    iconName: "bubble.left.and.bubble.right"
  )
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
    view.backgroundColor = BCTheme.Colors.background

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
    navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    navigationController?.interactivePopGestureRecognizer?.delegate = nil
    joinWebSocketRoom()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sendStopTyping()
    guard isMovingFromParent || isBeingDismissed else { return }
    leaveWebSocketRoom()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    topBarView.layer.shadowColor = BCTheme.Colors.separator.cgColor
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private func setupCustomTopBar() {
    topBarView.backgroundColor = .clear
    topBarView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(topBarView)

    blurEffectView.translatesAutoresizingMaskIntoConstraints = false
    topBarView.addSubview(blurEffectView)

    topBarView.layer.shadowColor = BCTheme.Colors.separator.cgColor
    topBarView.layer.shadowOffset = CGSize(width: 0, height: 0.5)
    topBarView.layer.shadowOpacity = 0.5
    topBarView.layer.shadowRadius = 0

    backButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
    backButton.tintColor = BCTheme.Colors.primary
    backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
    backButton.translatesAutoresizingMaskIntoConstraints = false
    topBarView.addSubview(backButton)

    titleLabel.text = room.displayName
    titleLabel.font = BCTheme.Typography.headline
    titleLabel.textColor = BCTheme.Colors.textPrimary

    subtitleLabel.text = room.isDirect ? "Tin nhắn riêng tư" : "\(max(room.memberCount, 1)) thành viên"
    subtitleLabel.font = BCTheme.Typography.caption
    subtitleLabel.textColor = BCTheme.Colors.textSecondary

    let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    textStack.axis = .vertical
    textStack.alignment = .leading
    textStack.spacing = 2
    textStack.translatesAutoresizingMaskIntoConstraints = false
    topBarView.addSubview(textStack)

    callButton.setImage(UIImage(systemName: "phone"), for: .normal)
    callButton.tintColor = BCTheme.Colors.primary
    callButton.addTarget(self, action: #selector(didTapCall), for: .touchUpInside)
    callButton.translatesAutoresizingMaskIntoConstraints = false
    topBarView.addSubview(callButton)

    optionsButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
    optionsButton.transform = CGAffineTransform(rotationAngle: .pi / 2)
    optionsButton.tintColor = BCTheme.Colors.primary
    optionsButton.addTarget(self, action: #selector(didTapInfo), for: .touchUpInside)
    optionsButton.translatesAutoresizingMaskIntoConstraints = false
    topBarView.addSubview(optionsButton)

    NSLayoutConstraint.activate([
      topBarView.topAnchor.constraint(equalTo: view.topAnchor),
      topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      topBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),

      blurEffectView.topAnchor.constraint(equalTo: topBarView.topAnchor),
      blurEffectView.bottomAnchor.constraint(equalTo: topBarView.bottomAnchor),
      blurEffectView.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor),
      blurEffectView.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor),

      backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: BCTheme.Layout.paddingL),
      backButton.bottomAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: -10),
      backButton.widthAnchor.constraint(equalToConstant: 24),
      backButton.heightAnchor.constraint(equalToConstant: 24),

      textStack.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 14),
      textStack.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
      textStack.trailingAnchor.constraint(equalTo: callButton.leadingAnchor, constant: -10),

      optionsButton.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor, constant: -BCTheme.Layout.paddingL),
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
    view.insertSubview(tableView, belowSubview: topBarView)
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
    inputContainerView.backgroundColor = BCTheme.Colors.surface

    smartReplyStack.axis = .horizontal
    smartReplyStack.spacing = BCTheme.Layout.paddingS
    smartReplyStack.distribution = .fillProportionally
    smartReplyStack.translatesAutoresizingMaskIntoConstraints = false
    inputContainerView.addSubview(smartReplyStack)

    pillContainerView.backgroundColor = BCTheme.Colors.surfaceElevated
    pillContainerView.layer.cornerRadius = 20
    pillContainerView.translatesAutoresizingMaskIntoConstraints = false
    inputContainerView.addSubview(pillContainerView)

    configureIconButton(attachButton, systemName: "plus", action: #selector(didTapAttach))
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
    messageTextView.textColor = BCTheme.Colors.textPrimary
    messageTextView.font = BCTheme.Typography.body
    messageTextView.textContainerInset = UIEdgeInsets(top: 9, left: 4, bottom: 9, right: 4)
    messageTextView.isScrollEnabled = false
    messageTextView.delegate = self
    messageTextView.translatesAutoresizingMaskIntoConstraints = false
    pillContainerView.addSubview(messageTextView)

    placeholderLabel.text = "Nhập tin nhắn..."
    placeholderLabel.font = BCTheme.Typography.body
    placeholderLabel.textColor = BCTheme.Colors.textTertiary
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
      smartReplyStack.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: BCTheme.Layout.paddingM),
      smartReplyStack.trailingAnchor.constraint(lessThanOrEqualTo: inputContainerView.trailingAnchor, constant: -BCTheme.Layout.paddingM),
      smartReplyStack.heightAnchor.constraint(equalToConstant: 32),

      pillContainerView.topAnchor.constraint(equalTo: smartReplyStack.bottomAnchor, constant: 8),
      pillContainerView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: BCTheme.Layout.paddingM),
      pillContainerView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
      pillContainerView.bottomAnchor.constraint(equalTo: inputContainerView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
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

      placeholderLabel.leadingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: 8),
      placeholderLabel.centerYAnchor.constraint(equalTo: messageTextView.centerYAnchor),

      emojiButton.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -4),
      emojiButton.bottomAnchor.constraint(equalTo: pillContainerView.bottomAnchor, constant: -2),
      emojiButton.widthAnchor.constraint(equalToConstant: 32),
      emojiButton.heightAnchor.constraint(equalToConstant: 36),

      micButton.trailingAnchor.constraint(equalTo: pillContainerView.trailingAnchor, constant: -8),
      micButton.bottomAnchor.constraint(equalTo: pillContainerView.bottomAnchor, constant: -2),
      micButton.widthAnchor.constraint(equalToConstant: 32),
      micButton.heightAnchor.constraint(equalToConstant: 36),

      sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -BCTheme.Layout.paddingM),
      sendButton.bottomAnchor.constraint(equalTo: pillContainerView.bottomAnchor, constant: -2),
      sendButton.widthAnchor.constraint(equalToConstant: 36),
      sendButton.heightAnchor.constraint(equalToConstant: 36),
    ])
  }

  private func setupEmptyState() {
    emptyStateView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(emptyStateView)

    typingIndicatorLabel.font = BCTheme.Typography.captionItalic
    typingIndicatorLabel.textColor = BCTheme.Colors.textSecondary
    typingIndicatorLabel.isHidden = true
    typingIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(typingIndicatorLabel)

    NSLayoutConstraint.activate([
      emptyStateView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
      emptyStateView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
      emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: BCTheme.Layout.paddingL),
      emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -BCTheme.Layout.paddingL),

      typingIndicatorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      typingIndicatorLabel.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: -4),
    ])
  }

  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
  }

  private func setupGestures() {
    let viewTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    viewTapGesture.cancelsTouchesInView = false
    viewTapGesture.delegate = self
    view.addGestureRecognizer(viewTapGesture)

    let tableTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tableTapGesture.cancelsTouchesInView = false
    tableTapGesture.delegate = self
    tableView.addGestureRecognizer(tableTapGesture)

    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleMessageLongPress(_:)))
    tableView.addGestureRecognizer(longPress)

    let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleBackEdgePan(_:)))
    edgePan.edges = .left
    view.addGestureRecognizer(edgePan)
  }

  private func configureIconButton(_ button: UIButton, systemName: String, action: Selector) {
    button.setImage(UIImage(systemName: systemName), for: .normal)
    button.tintColor = BCTheme.Colors.textTertiary
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
    WebSocketService.shared.joinRoom(room.id)
  }

  private func leaveWebSocketRoom() {
    WebSocketService.shared.leaveRoom(room.id)
    WebSocketService.shared.removeDelegate(self)
  }

  @objc private func didTapSend() {
    let text = messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }

    let tempId = nextLocalId()
    let localMessage = makeLocalMessage(id: tempId, content: text, type: "text", fileUrl: nil, fileName: nil, status: "sending")
    appendMessage(localMessage)

    NetworkManager.shared.sendMessage(roomId: room.id, content: text) { [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        switch result {
        case .success(let saved):
          self.replaceLocalMessage(tempId, with: saved)
        case .failure(let error):
          self.markLocalMessageFailed(tempId, error: error)
        }
      }
    }

    messageTextView.text = ""
    textViewDidChange(messageTextView)
    sendStopTyping()
    updateSmartReplies(context: text)

  }

  @objc private func didTapAttach() {
    dismissKeyboard()
    let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    sheet.addAction(UIAlertAction(title: "Chụp ảnh", style: .default) { [weak self] _ in self?.openCamera() })
    sheet.addAction(UIAlertAction(title: "Gửi ảnh", style: .default) { [weak self] _ in self?.openPhotoPicker() })
    sheet.addAction(UIAlertAction(title: "Gửi video", style: .default) { [weak self] _ in self?.openVideoPicker() })
    sheet.addAction(UIAlertAction(title: "Gửi file", style: .default) { [weak self] _ in self?.openFilePicker() })
    sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
    present(sheet, animated: true)
  }

  @objc private func didTapEmoji() {
    dismissKeyboard()
    showEmojiSheet { [weak self] emoji in
      guard let self else { return }
      self.messageTextView.text += emoji
      self.textViewDidChange(self.messageTextView)
      self.messageTextView.becomeFirstResponder()
    }
  }

  @objc private func didTapMic() {
    if audioRecorder?.isRecording == true {
      finishVoiceRecording()
    } else {
      startVoiceRecording()
    }
  }

  private func startVoiceRecording() {
    AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
      DispatchQueue.main.async {
        guard let self else { return }
        guard granted else {
          BCToast.show("Bạn cần cấp quyền micro để gửi tin nhắn thoại.", style: .error)
          return
        }
        do {
          try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
          try AVAudioSession.sharedInstance().setActive(true)
          let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice_\(Int(Date().timeIntervalSince1970)).m4a")
          let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
          ]
          self.recordingURL = url
          self.audioRecorder = try AVAudioRecorder(url: url, settings: settings)
          self.audioRecorder?.record()
          self.micButton.tintColor = BCTheme.Colors.error
          BCToast.show("Đang ghi âm. Bấm micro lần nữa để gửi.", style: .success)
        } catch {
          BCToast.show("Không thể bắt đầu ghi âm.", style: .error)
        }
      }
    }
  }

  private func finishVoiceRecording() {
    audioRecorder?.stop()
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    audioRecorder = nil
    micButton.tintColor = BCTheme.Colors.textTertiary
    guard let url = recordingURL else { return }
    guard let data = try? Data(contentsOf: url) else { return }
    let fileName = url.lastPathComponent
    let id = nextLocalId()
    let persistedUrl = ChatLocalStore.shared.persistAttachment(data, fileName: fileName)?.absoluteString ?? url.absoluteString
    let message = makeLocalMessage(id: id, content: "Tin nhắn thoại", type: "file", fileUrl: persistedUrl, fileName: fileName, status: "local")
    appendMessage(message)
    NetworkManager.shared.uploadFile(roomId: room.id, fileData: data, fileName: fileName, mimeType: "audio/mp4") { [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        switch result {
        case .success(let saved):
          self.replaceLocalMessage(id, with: saved)
        case .failure(let error):
          self.markLocalMessageFailed(id, error: error)
        }
      }
    }
  }

  @objc private func didTapInfo() {
    navigationController?.pushViewController(GroupInfoViewController(room: room), animated: true)
  }

  @objc private func didTapCall() {
    let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    sheet.addAction(UIAlertAction(title: "Gọi thoại", style: .default) { [weak self] _ in self?.presentCall(video: false) })
    sheet.addAction(UIAlertAction(title: "Gọi video", style: .default) { [weak self] _ in self?.presentCall(video: true) })
    sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
    if let popover = sheet.popoverPresentationController {
      popover.sourceView = callButton
      popover.sourceRect = callButton.bounds
    }
    present(sheet, animated: true)
  }

  private func presentCall(video: Bool) {
    let callId = UUID().uuidString
    WebSocketService.shared.sendEvent(type: "call_invite", payload: ["room_id": room.id, "call_id": callId, "is_video": video])
    let call = CallViewController(roomName: room.displayName, isVideo: video, callId: callId, roomId: room.id)
    call.modalPresentationStyle = .fullScreen
    present(call, animated: true)
  }

  private func openPhotoPicker() {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = .photoLibrary
    picker.mediaTypes = [UTType.image.identifier]
    picker.allowsEditing = false
    present(picker, animated: true)
  }

  private func openCamera() {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      BCToast.show("Thiết bị này không hỗ trợ camera.", style: .error)
      return
    }
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = .camera
    picker.mediaTypes = [UTType.image.identifier]
    picker.cameraCaptureMode = .photo
    picker.allowsEditing = false
    present(picker, animated: true)
  }

  private func openVideoPicker() {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = .photoLibrary
    picker.mediaTypes = [UTType.movie.identifier]
    picker.videoQuality = .typeMedium
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

  private func makeLocalMessage(id: Int, content: String, type: String, fileUrl: String?, fileName: String?, status: String) -> Message {
    let user = TokenManager.shared.currentUser
    return Message(
      id: id, roomId: room.id, userId: user?.id, username: user?.username, displayName: user?.displayName ?? user?.username,
      content: content, messageType: type, fileUrl: fileUrl, fileName: fileName, status: status
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

  private func markLocalMessageFailed(_ id: Int, error: Error) {
    guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
    messages[index].status = "failed"
    persistLocalChat()
    tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    BCToast.show(error.localizedDescription, style: .error)
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
    if isMessageFromCurrentUser(incoming), let pendingIndex = messages.firstIndex(where: {
      $0.id < 0 && $0.messageType == incoming.messageType && 
      ($0.messageType == "file" ? $0.fileName == incoming.fileName : $0.content == incoming.content)
    }) {
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

      var config = UIButton.Configuration.filled()
      config.title = text
      config.baseBackgroundColor = BCTheme.Colors.surfaceElevated
      config.baseForegroundColor = BCTheme.Colors.primary
      config.cornerStyle = .capsule
      config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
      config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
          var outgoing = incoming
          outgoing.font = BCTheme.Typography.captionBold
          return outgoing
      }

      button.configuration = config
      button.addAction(UIAction { [weak self] _ in
        self?.messageTextView.text = text
        self?.didTapSend()
      }, for: .touchUpInside)

      smartReplyStack.addArrangedSubview(button)
    }
  }

  private func showEmojiSheet(handler: @escaping (String) -> Void) {
    let picker = EmojiPickerViewController()
    picker.onSelect = handler
    let nav = UINavigationController(rootViewController: picker)
    if let sheet = nav.sheetPresentationController {
      sheet.detents = [.medium(), .large()]
      sheet.prefersGrabberVisible = true
    }
    present(nav, animated: true)
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
    WebSocketService.shared.sendEvent(type: "mark_read", payload: ["room_id": room.id, "message_id": last.id])
  }

  private func sendStopTyping() {
    guard isTyping else { return }
    isTyping = false
    WebSocketService.shared.sendEvent(type: "stop_typing", payload: ["room_id": room.id])
  }

  private func updateEmptyState() {
    emptyStateView.isHidden = !messages.isEmpty
  }

  private func scrollToBottom(animated: Bool = true) {
    guard !messages.isEmpty else { return }
    tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: animated)
  }

  private func mediaKind(for message: Message) -> MediaKind? {
    let name = (message.fileName ?? message.fileUrl ?? "").lowercased()
    if ["jpg", "jpeg", "png", "gif", "heic", "heif", "webp"].contains(where: { name.hasSuffix(".\($0)") }) { return .image }
    if ["mp4", "mov", "m4v", "webm"].contains(where: { name.hasSuffix(".\($0)") }) { return .video }
    if ["m4a", "aac", "mp3", "wav"].contains(where: { name.hasSuffix(".\($0)") }) { return .audio }
    return nil
  }

  private func playMedia(from url: URL) {
    guard presentedViewController == nil else { return }
    let player = AVPlayer(url: url)
    let controller = AVPlayerViewController()
    controller.player = player
    present(controller, animated: true) {
      player.play()
    }
  }

  private func presentImagePreview(from url: URL, fallback: UIImage?) {
    guard presentedViewController == nil else { return }
    let controller = UIViewController()
    controller.view.backgroundColor = .black
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = fallback
    controller.view.addSubview(imageView)

    let closeButton = UIButton(type: .system)
    closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
    closeButton.tintColor = .white
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    closeButton.addAction(UIAction { [weak controller] _ in controller?.dismiss(animated: true) }, for: .touchUpInside)
    controller.view.addSubview(closeButton)

    NSLayoutConstraint.activate([
      imageView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
      imageView.topAnchor.constraint(equalTo: controller.view.topAnchor),
      imageView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
      closeButton.topAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.topAnchor, constant: 12),
      closeButton.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -16),
      closeButton.widthAnchor.constraint(equalToConstant: 44),
      closeButton.heightAnchor.constraint(equalToConstant: 44),
    ])

    controller.modalPresentationStyle = .fullScreen
    present(controller, animated: true)

    guard fallback == nil else { return }
    ImageCache.shared.loadInto(imageView, from: url)
  }

  private func previewDocument(from url: URL, fileName: String?) {
    if url.isFileURL { presentQuickLook(url); return }
    URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in
      guard let self else { return }
      if let error { DispatchQueue.main.async { BCToast.show(error.localizedDescription, style: .error) }; return }
      guard let tempURL else { DispatchQueue.main.async { BCToast.show("Không tải được file.", style: .error) }; return }
      let safeName = self.safePreviewFileName(fileName, fallbackURL: url)
      let destination = FileManager.default.temporaryDirectory.appendingPathComponent(safeName)
      try? FileManager.default.removeItem(at: destination)
      do {
        try FileManager.default.copyItem(at: tempURL, to: destination)
        DispatchQueue.main.async { self.presentQuickLook(destination) }
      } catch {
        DispatchQueue.main.async { BCToast.show("Không mở được file.", style: .error) }
      }
    }.resume()
  }

  private func presentQuickLook(_ url: URL) {
    guard presentedViewController == nil else { return }
    previewFileURL = url
    let controller = QLPreviewController()
    controller.dataSource = self
    present(controller, animated: true)
  }

  private func safePreviewFileName(_ fileName: String?, fallbackURL: URL) -> String {
    let rawName = fileName?.isEmpty == false ? fileName! : fallbackURL.lastPathComponent
    let cleaned = rawName.replacingOccurrences(of: "/", with: "_")
    return cleaned.isEmpty ? "attachment" : cleaned
  }

  private func firstURL(in text: String) -> URL? {
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return detector.firstMatch(in: text, options: [], range: range)?.url
  }

  @objc private func dismissKeyboard() {
    messageTextView.resignFirstResponder()
    view.endEditing(true)
  }

  @objc private func handleBackEdgePan(_ recognizer: UIScreenEdgePanGestureRecognizer) {
    guard recognizer.state == .ended || recognizer.state == .recognized else { return }
    guard navigationController?.topViewController === self else { return }
    didTapBack()
  }

  @objc private func keyboardWillShow(_ notification: Notification) {
    guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
          let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
    inputBottomConstraint.constant = -frame.cgRectValue.height
    UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    scrollToBottom(animated: true)
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
    inputBottomConstraint.constant = 0
    UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
  }
}

extension ChatRoomViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.identifier, for: indexPath) as! MessageCell
    let message = messages[indexPath.row]
    cell.configure(with: message, isMe: isMessageFromCurrentUser(message), reaction: reactionsByMessageId[message.id], localImage: localImagesByMessageId[message.id])
    return cell
  }
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let message = messages[indexPath.row]
    if let link = firstURL(in: message.content) { UIApplication.shared.open(link); return }
    guard let url = Constants.mediaURL(from: message.fileUrl) else { return }
    switch mediaKind(for: message) {
    case .video, .audio: playMedia(from: url)
    case .image: presentImagePreview(from: url, fallback: localImagesByMessageId[message.id])
    case nil: previewDocument(from: url, fileName: message.fileName)
    }
  }
}

extension ChatRoomViewController: QLPreviewControllerDataSource {
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int { previewFileURL == nil ? 0 : 1 }
  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { 
    (previewFileURL as NSURL?) ?? NSURL(fileURLWithPath: "") 
  }
}

extension ChatRoomViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard gestureRecognizer is UITapGestureRecognizer else { return true }
    guard let touchedView = touch.view else { return true }
    return !touchedView.isDescendant(of: inputContainerView)
  }
}

extension ChatRoomViewController: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    let hasText = !text.isEmpty

    placeholderLabel.isHidden = !textView.text.isEmpty
    let targetColor = hasText ? BCTheme.Colors.primary : .systemGray4

    if sendButton.backgroundColor != targetColor {
        UIView.transition(with: sendButton, duration: 0.15, options: .transitionCrossDissolve) {
            self.sendButton.backgroundColor = targetColor
        }
    }

    if hasText && !isTyping {
      isTyping = true
      WebSocketService.shared.sendEvent(type: "typing", payload: ["room_id": room.id])
    } else if !hasText {
      sendStopTyping()
    }
  }
}

extension ChatRoomViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    picker.dismiss(animated: true)
    if let videoURL = info[.mediaURL] as? URL { sendPickedVideo(videoURL); return }
    guard let image = info[.originalImage] as? UIImage else { return }
    let fileName = "image_\(Int(Date().timeIntervalSince1970)).jpg"
    let data = image.jpegData(compressionQuality: 0.72)
    let fileUrl = data.flatMap { ChatLocalStore.shared.persistAttachment($0, fileName: fileName)?.absoluteString }
    let id = nextLocalId()
    let message = makeLocalMessage(id: id, content: "", type: "file", fileUrl: fileUrl, fileName: fileName, status: "local")
    if fileUrl == nil { localImagesByMessageId[id] = image }
    appendMessage(message)
    if let data {
      NetworkManager.shared.uploadFile(roomId: room.id, fileData: data, fileName: fileName, mimeType: "image/jpeg") { [weak self] result in
        DispatchQueue.main.async {
          guard let self else { return }
          switch result {
          case .success(let saved):
            self.localImagesByMessageId.removeValue(forKey: id)
            self.replaceLocalMessage(id, with: saved)
          case .failure(let error):
            self.markLocalMessageFailed(id, error: error)
          }
        }
      }
    }
  }

  private func sendPickedVideo(_ url: URL) {
    guard let data = try? Data(contentsOf: url) else { BCToast.show("Không đọc được video đã chọn.", style: .error); return }
    let fileName = "video_\(Int(Date().timeIntervalSince1970)).mov"
    let persistedUrl = ChatLocalStore.shared.persistAttachment(data, fileName: fileName)?.absoluteString ?? url.absoluteString
    let id = nextLocalId()
    let message = makeLocalMessage(id: id, content: "", type: "file", fileUrl: persistedUrl, fileName: fileName, status: "local")
    appendMessage(message)
    NetworkManager.shared.uploadFile(roomId: room.id, fileData: data, fileName: fileName, mimeType: "video/quicktime") { [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        switch result {
        case .success(let saved): self.replaceLocalMessage(id, with: saved)
        case .failure(let error): self.markLocalMessageFailed(id, error: error)
        }
      }
    }
  }
}

extension ChatRoomViewController: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else { return }
    let didStartAccessing = url.startAccessingSecurityScopedResource()
    defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }
    let data = try? Data(contentsOf: url)
    let persistedUrl = data.flatMap { ChatLocalStore.shared.persistAttachment($0, fileName: url.lastPathComponent)?.absoluteString } ?? url.absoluteString
    let id = nextLocalId()
    let message = makeLocalMessage(id: id, content: "Đã gửi file", type: "file", fileUrl: persistedUrl, fileName: url.lastPathComponent, status: "local")
    appendMessage(message)
    if let data {
      NetworkManager.shared.uploadFile(roomId: room.id, fileData: data, fileName: url.lastPathComponent, mimeType: "application/octet-stream") { [weak self] result in
        DispatchQueue.main.async {
          guard let self else { return }
          switch result {
          case .success(let saved): self.replaceLocalMessage(id, with: saved)
          case .failure(let error): self.markLocalMessageFailed(id, error: error)
          }
        }
      }
    }
  }
}

extension ChatRoomViewController: WebSocketServiceDelegate {
  func webSocketDidConnect() {}
  func webSocketDidDisconnect(error: Error?) {}
  func webSocketDidReceiveEvent(type: String, payload: [String: Any]) {
    switch type {
    case "new_message", "message_sent":
      guard let message = decodeMessage(from: payload), message.roomId == room.id else { return }
      upsertIncomingMessage(message)
      WebSocketService.shared.localLastMessageIds[room.id] = message.id
      markMessagesAsRead()
      if !isMessageFromCurrentUser(message) { updateSmartReplies(context: message.content) }
    case "typing_indicator":
      guard let roomId = payload["room_id"] as? Int, roomId == room.id else { return }
      let username = payload["username"] as? String ?? "Ai đó"
      let active = payload["is_typing"] as? Bool ?? false
      typingIndicatorLabel.text = active ? "\(username) đang soạn tin nhắn..." : nil
      typingIndicatorLabel.isHidden = !active
    case "call_event":
      handleCallEvent(payload)
    case "sync_response":
      guard let roomId = payload["room_id"] as? Int, roomId == room.id, let list = payload["messages"] as? [[String: Any]] else { return }
      list.compactMap { Message.fromWebSocketPayload($0, defaultRoomId: room.id) }.forEach { upsertIncomingMessage($0) }
      if let lastId = messages.last?.id { WebSocketService.shared.localLastMessageIds[room.id] = lastId }
    default: break
    }
  }
  private func handleCallEvent(_ payload: [String: Any]) {
    guard let roomId = payload["room_id"] as? Int, roomId == room.id, let callId = payload["call_id"] as? String, let action = payload["action"] as? String else { return }
    let isVideo = payload["is_video"] as? Bool ?? false
    let username = payload["sender_username"] as? String ?? "Ai đó"
    switch action {
    case "call_invite":
      let alert = UIAlertController(title: isVideo ? "Cuộc gọi video" : "Cuộc gọi thoại", message: "\(username) đang gọi bạn", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Từ chối", style: .destructive) { _ in WebSocketService.shared.sendEvent(type: "call_reject", payload: ["room_id": roomId, "call_id": callId, "is_video": isVideo]) })
      alert.addAction(UIAlertAction(title: "Nghe", style: .default) { [weak self] _ in
        WebSocketService.shared.sendEvent(type: "call_accept", payload: ["room_id": roomId, "call_id": callId, "is_video": isVideo])
        let call = CallViewController(roomName: self?.room.displayName ?? username, isVideo: isVideo, callId: callId, roomId: roomId)
        call.modalPresentationStyle = .fullScreen
        self?.present(call, animated: true)
      })
      present(alert, animated: true)
    case "call_reject", "call_end": presentedViewController?.dismiss(animated: true)
    default: break
    }
  }
  private func decodeMessage(from payload: [String: Any]) -> Message? {
    if let dictionary = payload["message"] as? [String: Any] { return Message.fromWebSocketPayload(dictionary, defaultRoomId: room.id) }
    return Message.fromWebSocketPayload(payload, defaultRoomId: room.id)
  }
  private func isMessageFromCurrentUser(_ message: Message) -> Bool {
    if message.id < 0 { return true }
    guard let currentUser = TokenManager.shared.currentUser else { return false }
    if message.userId == currentUser.id { return true }
    if message.username == currentUser.username { return true }
    if let displayName = message.displayName, let currentDisplayName = currentUser.displayName, displayName == currentDisplayName { return true }
    return false
  }
}

private final class SmartReplyEngine {
  private struct Intent { let keywords: [String]; let replies: [String] }
  private let intents: [Intent] = [
    Intent(keywords: ["chao", "hello", "hi ", "hey", "alo"], replies: ["Mình nghe đây", "Chào bạn", "Có mình đây"]),
    Intent(keywords: ["cam on", "thank", "thanks", "tks"], replies: ["Không có gì", "Ok bạn", "Rất vui được giúp"]),
    Intent(keywords: ["xin loi", "sorry", "loi nhe"], replies: ["Không sao đâu", "Ổn mà", "Mình hiểu"]),
    Intent(keywords: ["goi", "call", "video", "dien thoai"], replies: ["Gọi mình nhé", "Mình nghe được", "Để mình gọi lại"]),
    Intent(keywords: ["anh", "hinh", "video", "file", "tep"], replies: ["Gửi mình xem", "Mình xem ngay", "Ok, để mình mở"]),
    Intent(keywords: ["dia chi", "o dau", "vi tri", "location"], replies: ["Gửi vị trí nhé", "Mình tới ngay", "Bạn ở đâu?"]),
    Intent(keywords: ["may gio", "luc nao", "hom nay", "ngay mai", "lich"], replies: ["Mấy giờ được?", "Để mình sắp xếp", "Ok, hẹn bạn lúc đó"]),
    Intent(keywords: ["gia", "tien", "bao nhieu", "chuyen khoan"], replies: ["Bao nhiêu vậy?", "Gửi mình thông tin nhé", "Ok để mình xem"]),
    Intent(keywords: ["gap", "nhanh", "urgent", "can gap"], replies: ["Mình xử lý ngay", "Ok, để mình xem liền", "Đã rõ"]),
    Intent(keywords: ["dep", "tuyet", "hay", "ok", "on", "duoc"], replies: ["Chuẩn đó", "Mình thích ý này", "Quá ổn"]),
    Intent(keywords: ["update", "check", "kiem tra", "xem lai"], replies: ["Để tôi check", "Ok, gửi tôi xem", "Đã rõ"]),
  ]
  func suggestions(for context: String?) -> [String] {
    let original = (context ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let normalized = normalize(original)
    guard !normalized.isEmpty else { return ["Ok luôn", "Mình nghe đây", "Bạn nói tiếp đi"] }
    var scoredReplies: [(score: Int, replies: [String])] = intents.compactMap { intent in
      let score = intent.keywords.reduce(0) { partial, keyword in partial + (normalized.contains(keyword) ? 1 : 0) }
      return score > 0 ? (score, intent.replies) : nil
    }
    if original.contains("?") || normalized.contains("khong") || normalized.contains("ko") { scoredReplies.append((2, ["Được nhé", "Để mình xem", "Bạn nói rõ hơn được không?"])) }
    let replies = scoredReplies.sorted { $0.score > $1.score }.flatMap { $0.replies }
    return unique(replies + ["Ok luôn", "Để tôi check", "Tuyệt vời"]).prefix(3).map { $0 }
  }
  private func normalize(_ value: String) -> String { value.lowercased().folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) }
  private func unique(_ values: [String]) -> [String] {
    var seen = Set<String>(); return values.filter { seen.insert($0).inserted }
  }
}

private final class CallViewController: UIViewController {
  private let roomName: String; private let isVideo: Bool; private let callId: String; private let roomId: Int
  private let titleLabel = UILabel(); private let statusLabel = UILabel(); private let avatarView = BCAvatar(size: 108); private let controlsStack = UIStackView()
  init(roomName: String, isVideo: Bool, callId: String, roomId: Int) {
    self.roomName = roomName; self.isVideo = isVideo; self.callId = callId; self.roomId = roomId
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1)
    setupViews()
  }
  private func setupViews() {
    avatarView.configure(name: roomName)

    titleLabel.text = roomName
    titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
    titleLabel.textColor = .white
    titleLabel.textAlignment = .center

    statusLabel.text = isVideo ? "Đang chuẩn bị gọi video..." : "Đang chuẩn bị gọi thoại..."
    statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
    statusLabel.textColor = .white.withAlphaComponent(0.72)
    statusLabel.textAlignment = .center

    controlsStack.axis = .horizontal
    controlsStack.distribution = .equalSpacing
    controlsStack.alignment = .center

    let controls: [(String, UIColor, Selector)] = [
      ("mic.fill", .white.withAlphaComponent(0.16), #selector(didTapStubControl)),
      (isVideo ? "video.fill" : "video.slash.fill", .white.withAlphaComponent(0.16), #selector(didTapStubControl)),
      ("speaker.wave.2.fill", .white.withAlphaComponent(0.16), #selector(didTapStubControl)),
      ("phone.down.fill", .systemRed, #selector(didTapEnd)),
    ]
    controls.forEach { icon, color, selector in
      let button = UIButton(type: .system)
      button.setImage(UIImage(systemName: icon), for: .normal)
      button.tintColor = .white
      button.backgroundColor = color
      button.layer.cornerRadius = 28
      button.addTarget(self, action: selector, for: .touchUpInside)
      button.widthAnchor.constraint(equalToConstant: 56).isActive = true
      button.heightAnchor.constraint(equalToConstant: 56).isActive = true
      controlsStack.addArrangedSubview(button)
    }

    [avatarView, titleLabel, statusLabel, controlsStack].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview($0)
    }

    NSLayoutConstraint.activate([
      avatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      avatarView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -120),
      avatarView.widthAnchor.constraint(equalToConstant: 108),
      avatarView.heightAnchor.constraint(equalToConstant: 108),

      titleLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 22),
      titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
      titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

      statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      statusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      statusLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

      controlsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 38),
      controlsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -38),
      controlsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -34),
    ])
  }
  @objc private func didTapStubControl() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
  @objc private func didTapEnd() {
    WebSocketService.shared.sendEvent(type: "call_end", payload: ["room_id": roomId, "call_id": callId, "is_video": isVideo])
    dismiss(animated: true)
  }
}
