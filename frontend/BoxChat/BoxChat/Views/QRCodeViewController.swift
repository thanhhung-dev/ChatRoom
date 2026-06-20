import CoreImage.CIFilterBuiltins
import UIKit

final class QRCodeViewController: UIViewController {
  private let payload: String
  private let heading: String
  private let detail: String
  private let context = CIContext()

  private let imageView = UIImageView()
  private let detailLabel = UILabel()
  private let copyButton = UIButton(type: .system)

  init(payload: String, heading: String, detail: String) {
    self.payload = payload
    self.heading = heading
    self.detail = detail
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    title = heading
    setupLayout()
  }

  private func setupLayout() {
    let card = UIView()
    card.backgroundColor = .systemBackground
    card.layer.cornerRadius = 24
    card.layer.cornerCurve = .continuous
    card.translatesAutoresizingMaskIntoConstraints = false

    imageView.image = makeQRCode(from: payload)
    imageView.contentMode = .scaleAspectFit
    imageView.backgroundColor = .white
    imageView.layer.cornerRadius = 18
    imageView.clipsToBounds = true

    detailLabel.text = detail
    detailLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    detailLabel.textColor = .secondaryLabel
    detailLabel.textAlignment = .center
    detailLabel.numberOfLines = 0

    copyButton.setTitle("Sao chép link", for: .normal)
    copyButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
    copyButton.backgroundColor = .systemBlue
    copyButton.setTitleColor(.white, for: .normal)
    copyButton.layer.cornerRadius = 16
    copyButton.addTarget(self, action: #selector(didTapCopy), for: .touchUpInside)

    let stack = UIStackView(arrangedSubviews: [imageView, detailLabel, copyButton])
    stack.axis = .vertical
    stack.spacing = 18
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(stack)
    view.addSubview(card)

    NSLayoutConstraint.activate([
      card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
      card.centerYAnchor.constraint(equalTo: view.centerYAnchor),

      stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
      stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
      stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
      stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),

      imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
      copyButton.heightAnchor.constraint(equalToConstant: 48),
    ])
  }

  private func makeQRCode(from value: String) -> UIImage? {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(value.utf8)
    filter.correctionLevel = "Q"
    guard let output = filter.outputImage else { return nil }
    let scaled = output.transformed(by: CGAffineTransform(scaleX: 14, y: 14))
    guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }

    let qrImage = UIImage(cgImage: cgImage)
    let quietZone: CGFloat = 28
    let size = CGSize(
      width: qrImage.size.width + quietZone * 2,
      height: qrImage.size.height + quietZone * 2)

    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
      UIColor.white.setFill()
      UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
      qrImage.draw(in: CGRect(
        x: quietZone,
        y: quietZone,
        width: qrImage.size.width,
        height: qrImage.size.height))
    }
  }

  @objc private func didTapCopy() {
    UIPasteboard.general.string = payload
    let alert = UIAlertController(title: nil, message: "Đã sao chép link QR", preferredStyle: .alert)
    present(alert, animated: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
      alert.dismiss(animated: true)
    }
  }
}
