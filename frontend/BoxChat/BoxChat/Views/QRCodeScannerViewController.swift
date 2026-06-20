import AVFoundation
import UIKit

final class QRCodeScannerViewController: UIViewController {
  var onScan: ((String) -> Void)?

  private let session = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var didScan = false

  private let overlayView = UIView()
  private let frameView = UIView()
  private let instructionLabel = UILabel()
  private let closeButton = UIButton(type: .system)

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    setupOverlay()
    requestCamera()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    didScan = false
    if previewLayer != nil && !session.isRunning {
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        self?.session.startRunning()
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if session.isRunning {
      let runningSession = session
      DispatchQueue.global(qos: .userInitiated).async {
        runningSession.stopRunning()
      }
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = view.bounds
    updateScanFrame()
  }

  private func requestCamera() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      configureSession()
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        DispatchQueue.main.async {
          granted ? self?.configureSession() : self?.showCameraDenied()
        }
      }
    default:
      showCameraDenied()
    }
  }

  private func configureSession() {
    guard session.inputs.isEmpty, session.outputs.isEmpty else { return }
    session.sessionPreset = .high

    guard let camera = AVCaptureDevice.default(for: .video),
      let input = try? AVCaptureDeviceInput(device: camera),
      session.canAddInput(input)
    else {
      showMessage("Không mở được camera trên thiết bị này.")
      return
    }
    session.addInput(input)

    let output = AVCaptureMetadataOutput()
    guard session.canAddOutput(output) else {
      showMessage("Không thể bật chế độ quét QR.")
      return
    }
    session.addOutput(output)
    output.setMetadataObjectsDelegate(self, queue: .main)
    output.metadataObjectTypes = [.qr]
    output.rectOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)

    let layer = AVCaptureVideoPreviewLayer(session: session)
    layer.videoGravity = .resizeAspectFill
    layer.frame = view.bounds
    view.layer.insertSublayer(layer, at: 0)
    previewLayer = layer

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.session.startRunning()
    }
  }

  private func setupOverlay() {
    overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
    overlayView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(overlayView)

    frameView.layer.borderColor = UIColor.systemGreen.cgColor
    frameView.layer.borderWidth = 3
    frameView.layer.cornerRadius = 24
    frameView.layer.cornerCurve = .continuous
    frameView.backgroundColor = .clear
    frameView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(frameView)

    instructionLabel.text = "Đưa mã QR vào khung để tham gia nhóm hoặc kết bạn"
    instructionLabel.font = .systemFont(ofSize: 15, weight: .bold)
    instructionLabel.textColor = .white
    instructionLabel.textAlignment = .center
    instructionLabel.numberOfLines = 0
    instructionLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(instructionLabel)

    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.tintColor = .white
    closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.45)
    closeButton.layer.cornerRadius = 18
    closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(closeButton)

    NSLayoutConstraint.activate([
      overlayView.topAnchor.constraint(equalTo: view.topAnchor),
      overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      frameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      frameView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -32),
      frameView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.72),
      frameView.heightAnchor.constraint(equalTo: frameView.widthAnchor),

      instructionLabel.topAnchor.constraint(equalTo: frameView.bottomAnchor, constant: 24),
      instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
      instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),

      closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
      closeButton.widthAnchor.constraint(equalToConstant: 36),
      closeButton.heightAnchor.constraint(equalToConstant: 36),
    ])
  }

  private func updateScanFrame() {
    guard let output = session.outputs.compactMap({ $0 as? AVCaptureMetadataOutput }).first,
      let previewLayer
    else { return }
    guard frameView.bounds.width > 20, frameView.bounds.height > 20 else {
      output.rectOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
      return
    }
    let rect = previewLayer.metadataOutputRectConverted(fromLayerRect: frameView.frame)
    output.rectOfInterest = rect.insetBy(dx: -0.08, dy: -0.08).intersection(
      CGRect(x: 0, y: 0, width: 1, height: 1))
  }

  private func showCameraDenied() {
    showMessage("Bạn cần cấp quyền camera để quét QR.")
  }

  private func showMessage(_ message: String) {
    let alert = UIAlertController(title: "Không thể quét QR", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
      self?.dismiss(animated: true)
    })
    present(alert, animated: true)
  }

  @objc private func didTapClose() {
    dismiss(animated: true)
  }
}

extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
  func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    guard !didScan,
      let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
      let value = object.stringValue
    else { return }
    didScan = true
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    let runningSession = session
    DispatchQueue.global(qos: .userInitiated).async {
      runningSession.stopRunning()
    }
    dismiss(animated: true) { [onScan] in
      onScan?(value)
    }
  }
}
