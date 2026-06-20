import UIKit

final class FeedCommentsViewController: UIViewController {
  private let post: FeedPostModel
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var comments: [FeedCommentModel] = []
  private var isKeyboardVisible = false

  private let inputContainerView = UIView()
  private let messageTextView = UITextView()
  private let sendButton = UIButton(type: .system)
  private var inputBottomConstraint: NSLayoutConstraint!

  init(post: FeedPostModel) {
    self.post = post
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Bình luận"
    view.backgroundColor = BCTheme.Colors.backgroundGrouped
    
    // Swipe to dismiss keyboard
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tapGesture.cancelsTouchesInView = false
    view.addGestureRecognizer(tapGesture)

    setupTableView()
    setupInputArea()
    setupKeyboardObservers()
    
    reloadComments()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    view.endEditing(true)
  }

  private func setupTableView() {
    tableView.dataSource = self
    tableView.delegate = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(FeedCommentCell.self, forCellReuseIdentifier: FeedCommentCell.identifier)
    tableView.separatorStyle = .none
    tableView.backgroundColor = .clear
    tableView.keyboardDismissMode = .interactive
    tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 80, right: 0) // Space for input area
    
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func setupInputArea() {
    view.addSubview(inputContainerView)
    inputContainerView.translatesAutoresizingMaskIntoConstraints = false
    inputContainerView.backgroundColor = BCTheme.Colors.surface

    let pillContainerView = UIView()
    pillContainerView.backgroundColor = BCTheme.Colors.surfaceElevated
    pillContainerView.layer.cornerRadius = 20
    pillContainerView.translatesAutoresizingMaskIntoConstraints = false
    inputContainerView.addSubview(pillContainerView)

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
    messageTextView.isScrollEnabled = false
    messageTextView.delegate = self
    messageTextView.text = "Viết bình luận..."
    messageTextView.textColor = BCTheme.Colors.textTertiary
    messageTextView.translatesAutoresizingMaskIntoConstraints = false
    pillContainerView.addSubview(messageTextView)

    inputBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    
    NSLayoutConstraint.activate([
      inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      inputBottomConstraint,

      pillContainerView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
      pillContainerView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
      pillContainerView.bottomAnchor.constraint(equalTo: inputContainerView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
      pillContainerView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12),

      sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -16),
      sendButton.bottomAnchor.constraint(equalTo: inputContainerView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
      sendButton.widthAnchor.constraint(equalToConstant: 36),
      sendButton.heightAnchor.constraint(equalToConstant: 36),

      messageTextView.topAnchor.constraint(equalTo: pillContainerView.topAnchor, constant: 8),
      messageTextView.bottomAnchor.constraint(equalTo: pillContainerView.bottomAnchor, constant: -8),
      messageTextView.leadingAnchor.constraint(equalTo: pillContainerView.leadingAnchor, constant: 16),
      messageTextView.trailingAnchor.constraint(equalTo: pillContainerView.trailingAnchor, constant: -8),
      messageTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
      messageTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 100)
    ])
  }

  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
  }

  @objc private func keyboardWillShow(notification: NSNotification) {
    guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
          let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
    
    let safeAreaBottom = view.safeAreaInsets.bottom
    inputBottomConstraint.constant = -(keyboardSize.height - safeAreaBottom)
    isKeyboardVisible = true
    
    UIView.animate(withDuration: duration) {
      self.view.layoutIfNeeded()
    }
  }

  @objc private func keyboardWillHide(notification: NSNotification) {
    guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
    
    inputBottomConstraint.constant = 0
    isKeyboardVisible = false
    
    UIView.animate(withDuration: duration) {
      self.view.layoutIfNeeded()
    }
  }

  @objc private func dismissKeyboard() {
    view.endEditing(true)
  }

  private func reloadComments() {
    NetworkManager.shared.fetchFeedComments(postId: post.id) { [weak self] result in
      DispatchQueue.main.async {
        if case .success(let comments) = result {
          self?.comments = comments
          self?.tableView.reloadData()
          self?.scrollToBottom(animated: false)
        }
      }
    }
  }

  private func scrollToBottom(animated: Bool) {
    guard !comments.isEmpty else { return }
    let indexPath = IndexPath(row: comments.count - 1, section: 0)
    tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
  }

  @objc private func didTapSend() {
    let text = messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty, text != "Viết bình luận..." else { return }

    sendButton.isEnabled = false
    NetworkManager.shared.addFeedComment(postId: post.id, content: text) { [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        self.sendButton.isEnabled = true
        if case .success(let comment) = result {
          self.comments.append(comment)
          self.tableView.reloadData()
          self.scrollToBottom(animated: true)
          self.messageTextView.text = ""
          self.textViewDidChange(self.messageTextView)
          self.dismissKeyboard()
        } else if case .failure(let error) = result {
          BCToast.show(error.localizedDescription, style: .error)
        }
      }
    }
  }
}

extension FeedCommentsViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return comments.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: FeedCommentCell.identifier, for: indexPath) as! FeedCommentCell
    cell.configure(with: comments[indexPath.row])
    return cell
  }
}

extension FeedCommentsViewController: UITextViewDelegate {
  func textViewDidBeginEditing(_ textView: UITextView) {
    if textView.text == "Viết bình luận..." {
      textView.text = ""
      textView.textColor = BCTheme.Colors.textPrimary
    }
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      textView.text = "Viết bình luận..."
      textView.textColor = BCTheme.Colors.textTertiary
    }
  }

  func textViewDidChange(_ textView: UITextView) {
    let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    let isEmptyOrPlaceholder = text.isEmpty || text == "Viết bình luận..."
    sendButton.backgroundColor = isEmptyOrPlaceholder ? .systemGray4 : BCTheme.Colors.primary
    
    // Update size automatically
    let size = CGSize(width: textView.frame.width, height: .infinity)
    let estimatedSize = textView.sizeThatFits(size)
    textView.constraints.forEach { constraint in
      if constraint.firstAttribute == .height {
        constraint.constant = min(100, max(24, estimatedSize.height))
      }
    }
  }
}
