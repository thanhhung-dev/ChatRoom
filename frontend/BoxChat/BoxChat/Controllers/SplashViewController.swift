import UIKit

class SplashViewController: UIViewController {

    // MARK: - Background
    private let backgroundGradient = CAGradientLayer()
    private let gridLayer = CAShapeLayer()

    // MARK: - Orbs
    private let orb1 = UIView()
    private let orb2 = UIView()
    private let orb3 = UIView()

    // MARK: - Ring
    private let ringView = UIView()
    private let ringLayer = CAShapeLayer()

    // MARK: - Logo
    private let logoContainer = UIView()
    private let logoIconView = UIView()
    private let logoImageView = UIImageView()

    // MARK: - Brand Text
    private let brandStack = UIStackView()
    private let boxLabel: UILabel = {
        let l = UILabel()
        l.text = "Box"
        l.font = .systemFont(ofSize: 40, weight: .bold)
        l.textColor = .white
        return l
    }()
    private let chatLabel: UILabel = {
        let l = UILabel()
        l.text = "Chat"
        l.font = .systemFont(ofSize: 40, weight: .bold)
        l.textColor = UIColor(red: 0.19, green: 0.47, blue: 1.0, alpha: 1)
        return l
    }()
    private let taglineLabel: UILabel = {
        let l = UILabel()
        l.text = "Chat freely, connect easily."
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(white: 1, alpha: 0.38)
        l.textAlignment = .center
        return l
    }()

    // MARK: - Loading Bar
    private let loadingTrack = UIView()
    private let loadingBar = UIView()
    private var loadingBarWidth: NSLayoutConstraint?

    // MARK: - Shimmer
    private let shimmerView = UIView()
    private let shimmerGrad = CAGradientLayer()

    // MARK: - Particles
    private var emitterLayer: CAEmitterLayer?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupGrid()
        setupOrbs()
        setupRing()
        setupLogoIcon()
        setupBrandText()
        setupLoadingBar()
        setupShimmer()
        setupParticles()
        runAnimationSequence()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
        gridLayer.frame = view.bounds
        shimmerGrad.frame = shimmerView.bounds
        updateGridPath()
    }

    // MARK: - Background
    private func setupBackground() {
        backgroundGradient.colors = [
            UIColor(red: 0.04, green: 0.06, blue: 0.12, alpha: 1).cgColor,
            UIColor(red: 0.02, green: 0.03, blue: 0.07, alpha: 1).cgColor
        ]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }

    // MARK: - Grid
    private func setupGrid() {
        gridLayer.strokeColor = UIColor(red: 0.19, green: 0.47, blue: 1.0, alpha: 0.05).cgColor
        gridLayer.fillColor = UIColor.clear.cgColor
        gridLayer.lineWidth = 0.5
        gridLayer.opacity = 0
        view.layer.addSublayer(gridLayer)

        let fadeIn = CABasicAnimation(keyPath: "opacity")
        fadeIn.fromValue = 0
        fadeIn.toValue = 1
        fadeIn.duration = 1.5
        fadeIn.fillMode = .forwards
        fadeIn.isRemovedOnCompletion = false
        gridLayer.add(fadeIn, forKey: "gridFade")
    }

    private func updateGridPath() {
        let spacing: CGFloat = 32
        let path = UIBezierPath()
        var x: CGFloat = 0
        while x <= view.bounds.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: view.bounds.height))
            x += spacing
        }
        var y: CGFloat = 0
        while y <= view.bounds.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: view.bounds.width, y: y))
            y += spacing
        }
        gridLayer.path = path.cgPath
    }

    // MARK: - Orbs
    private func setupOrbs() {
        struct OrbConfig {
            let view: UIView
            let size: CGFloat
            let x: CGFloat
            let y: CGFloat
            let r: CGFloat
            let g: CGFloat
            let b: CGFloat
            let alpha: CGFloat
            let delay: TimeInterval
        }

        let configs = [
            OrbConfig(view: orb1, size: 260, x: -80, y: 60,  r: 0.19, g: 0.47, b: 1.0, alpha: 0.45, delay: 0.0),
            OrbConfig(view: orb2, size: 200, x: 160, y: 220, r: 0.39, g: 0.78, b: 1.0, alpha: 0.35, delay: 1.2),
            OrbConfig(view: orb3, size: 180, x: 30,  y: 460, r: 0.31, g: 0.63, b: 1.0, alpha: 0.30, delay: 2.4)
        ]

        for config in configs {
            config.view.frame = CGRect(x: config.x, y: config.y, width: config.size, height: config.size)
            config.view.layer.cornerRadius = config.size / 2
            config.view.clipsToBounds = true

            let centerColor = UIColor(red: config.r, green: config.g, blue: config.b, alpha: config.alpha)
            let edgeColor   = UIColor(red: config.r, green: config.g, blue: config.b, alpha: 0)

            let grad = makeRadialGradient(size: config.size, center: centerColor, edge: edgeColor)
            config.view.layer.addSublayer(grad)
            config.view.alpha = 0

            view.addSubview(config.view)
            animateOrb(config.view, delay: config.delay)
        }
    }

    private func makeRadialGradient(size: CGFloat, center: UIColor, edge: UIColor) -> CALayer {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [center.cgColor, edge.cgColor] as CFArray
            let locations: [CGFloat] = [0, 1]
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return }
            let center = CGPoint(x: size / 2, y: size / 2)
            ctx.cgContext.drawRadialGradient(gradient,
                startCenter: center, startRadius: 0,
                endCenter: center,   endRadius: size / 2,
                options: [])
        }
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 0, width: size, height: size)
        layer.contents = image.cgImage
        return layer
    }

    private func animateOrb(_ orb: UIView, delay: TimeInterval) {
        UIView.animateKeyframes(
            withDuration: 6.0, delay: delay,
            options: [.repeat, .calculationModeCubic]
        ) {
            UIView.addKeyframe(withRelativeStartTime: 0.0,  relativeDuration: 0.15) { orb.alpha = 1 }
            UIView.addKeyframe(withRelativeStartTime: 0.15, relativeDuration: 0.35) {
                orb.transform = CGAffineTransform(translationX: 12, y: -18).scaledBy(x: 1.05, y: 1.05)
                orb.alpha = 0.85
            }
            UIView.addKeyframe(withRelativeStartTime: 0.50, relativeDuration: 0.35) {
                orb.transform = .identity
                orb.alpha = 0.85
            }
            UIView.addKeyframe(withRelativeStartTime: 0.85, relativeDuration: 0.15) { orb.alpha = 0 }
        }
    }

    // MARK: - Ring
    private func setupRing() {
        let size: CGFloat = 100
        ringView.frame = CGRect(x: 0, y: 0, width: size, height: size)
        ringView.alpha = 0

        ringLayer.path = UIBezierPath(ovalIn: CGRect(x: 2, y: 2, width: size - 4, height: size - 4)).cgPath
        ringLayer.strokeColor = UIColor(red: 0.19, green: 0.47, blue: 1.0, alpha: 0.55).cgColor
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineWidth = 1.2
        ringLayer.lineDashPattern = [6, 6]
        ringLayer.frame = ringView.bounds
        ringView.layer.addSublayer(ringLayer)

        let dotLayer = CALayer()
        dotLayer.frame = CGRect(x: size / 2 - 4, y: -4, width: 8, height: 8)
        dotLayer.cornerRadius = 4
        dotLayer.backgroundColor = UIColor(red: 0.19, green: 0.47, blue: 1.0, alpha: 0.9).cgColor
        ringView.layer.addSublayer(dotLayer)
    }

    private func startRingRotation() {
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = CGFloat.pi * 2
        spin.duration = 8
        spin.repeatCount = .infinity
        spin.timingFunction = CAMediaTimingFunction(name: .linear)
        ringView.layer.add(spin, forKey: "ringRotate")
    }

    // MARK: - Logo Icon
    private func setupLogoIcon() {
        logoContainer.alpha = 0
        logoContainer.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        view.addSubview(logoContainer)

        logoContainer.addSubview(ringView)

        logoIconView.frame = CGRect(x: 16, y: 16, width: 68, height: 68)
        logoIconView.layer.cornerRadius = 20
        logoIconView.layer.cornerCurve = .continuous
        logoIconView.clipsToBounds = true

        let iconGrad = CAGradientLayer()
        iconGrad.frame = logoIconView.bounds
        iconGrad.colors = [
            UIColor(red: 0.10, green: 0.42, blue: 1.0, alpha: 1).cgColor,
            UIColor(red: 0.04, green: 0.31, blue: 0.83, alpha: 1).cgColor
        ]
        iconGrad.startPoint = CGPoint(x: 0, y: 0)
        iconGrad.endPoint = CGPoint(x: 1, y: 1)
        iconGrad.cornerRadius = 20
        logoIconView.layer.addSublayer(iconGrad)

        logoImageView.image = UIImage(named: "IconLoad")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.frame = CGRect(x: 8, y: 8, width: 52, height: 52)
        logoIconView.addSubview(logoImageView)

        logoIconView.layer.shadowColor = UIColor(red: 0.19, green: 0.47, blue: 1.0, alpha: 1).cgColor
        logoIconView.layer.shadowRadius = 20
        logoIconView.layer.shadowOpacity = 0.6
        logoIconView.layer.shadowOffset = CGSize(width: 0, height: 8)

        logoContainer.addSubview(logoIconView)
    }

    // MARK: - Brand Text
    private func setupBrandText() {
        brandStack.axis = .horizontal
        brandStack.spacing = 0
        brandStack.alignment = .center
        brandStack.addArrangedSubview(boxLabel)
        brandStack.addArrangedSubview(chatLabel)
        brandStack.alpha = 0
        taglineLabel.alpha = 0

        view.addSubview(brandStack)
        view.addSubview(taglineLabel)

        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        brandStack.translatesAutoresizingMaskIntoConstraints = false
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            logoContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -72),
            logoContainer.widthAnchor.constraint(equalToConstant: 100),
            logoContainer.heightAnchor.constraint(equalToConstant: 100),

            brandStack.topAnchor.constraint(equalTo: logoContainer.bottomAnchor, constant: 20),
            brandStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            taglineLabel.topAnchor.constraint(equalTo: brandStack.bottomAnchor, constant: 8),
            taglineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Loading Bar
    private func setupLoadingBar() {
        loadingTrack.backgroundColor = UIColor(white: 1, alpha: 0.08)
        loadingTrack.layer.cornerRadius = 2
        loadingTrack.clipsToBounds = true
        loadingTrack.alpha = 0

        let barGrad = CAGradientLayer()
        loadingBar.layer.cornerRadius = 2
        loadingBar.clipsToBounds = true

        barGrad.colors = [
            UIColor(red: 0.19, green: 0.47, blue: 1.0, alpha: 1).cgColor,
            UIColor(red: 0.38, green: 0.67, blue: 1.0, alpha: 1).cgColor
        ]
        barGrad.startPoint = CGPoint(x: 0, y: 0.5)
        barGrad.endPoint = CGPoint(x: 1, y: 0.5)
        loadingBar.layer.addSublayer(barGrad)

        loadingTrack.addSubview(loadingBar)
        view.addSubview(loadingTrack)

        loadingTrack.translatesAutoresizingMaskIntoConstraints = false
        loadingBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loadingTrack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingTrack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44),
            loadingTrack.widthAnchor.constraint(equalToConstant: 120),
            loadingTrack.heightAnchor.constraint(equalToConstant: 2),

            loadingBar.leadingAnchor.constraint(equalTo: loadingTrack.leadingAnchor),
            loadingBar.topAnchor.constraint(equalTo: loadingTrack.topAnchor),
            loadingBar.bottomAnchor.constraint(equalTo: loadingTrack.bottomAnchor)
        ])

        loadingBarWidth = loadingBar.widthAnchor.constraint(equalToConstant: 0)
        loadingBarWidth?.isActive = true

        DispatchQueue.main.async {
            barGrad.frame = self.loadingBar.bounds
        }
    }

    // MARK: - Shimmer
    private func setupShimmer() {
        shimmerView.frame = view.bounds
        shimmerView.isUserInteractionEnabled = false

        shimmerGrad.colors = [
            UIColor.clear.cgColor,
            UIColor(white: 1, alpha: 0.04).cgColor,
            UIColor.clear.cgColor
        ]
        shimmerGrad.locations = [0.0, 0.5, 1.0]
        shimmerGrad.startPoint = CGPoint(x: 0, y: 0)
        shimmerGrad.endPoint = CGPoint(x: 1, y: 1)
        shimmerGrad.frame = view.bounds
        shimmerView.layer.addSublayer(shimmerGrad)
        view.addSubview(shimmerView)
    }

    private func startShimmerLoop() {
        let anim = CABasicAnimation(keyPath: "transform.translation.x")
        anim.fromValue = -view.bounds.width * 2
        anim.toValue = view.bounds.width * 2
        anim.duration = 3.0
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shimmerGrad.add(anim, forKey: "shimmerSlide")
    }

    // MARK: - Particles
    private func setupParticles() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: view.bounds.height + 10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)
        emitter.renderMode = .additive
        emitter.opacity = 0

        let cell = CAEmitterCell()
        cell.birthRate = 4
        cell.lifetime = 9.0
        cell.lifetimeRange = 3.0
        cell.velocity = 60
        cell.velocityRange = 30
        cell.emissionLongitude = -.pi / 2
        cell.emissionRange = .pi / 6
        cell.scale = 0.012
        cell.scaleRange = 0.008
        cell.alphaSpeed = -0.06
        cell.color = UIColor(red: 0.38, green: 0.67, blue: 1.0, alpha: 0.6).cgColor
        cell.contents = makeCircleImage(size: 8).cgImage

        emitter.emitterCells = [cell]
        view.layer.insertSublayer(emitter, above: backgroundGradient)
        self.emitterLayer = emitter
    }

    private func makeCircleImage(size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }

    // MARK: - Animation Sequence
    private func runAnimationSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            CATransaction.begin()
            CATransaction.setAnimationDuration(1.0)
            self.emitterLayer?.opacity = 1
            CATransaction.commit()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            UIView.animate(
                withDuration: 0.9, delay: 0,
                usingSpringWithDamping: 0.58,
                initialSpringVelocity: 0.8,
                options: .curveEaseOut
            ) {
                self.logoContainer.alpha = 1
                self.logoContainer.transform = .identity
                self.ringView.alpha = 1
            } completion: { _ in
                self.startRingRotation()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            guard let self else { return }
            self.brandStack.transform = CGAffineTransform(translationX: 0, y: 14)
            UIView.animate(withDuration: 0.65, delay: 0, options: .curveEaseOut) {
                self.brandStack.alpha = 1
                self.brandStack.transform = .identity
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            guard let self else { return }
            self.taglineLabel.transform = CGAffineTransform(translationX: 0, y: 10)
            UIView.animate(withDuration: 0.55, delay: 0, options: .curveEaseOut) {
                self.taglineLabel.alpha = 1
                self.taglineLabel.transform = .identity
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: 0.4) { self.loadingTrack.alpha = 1 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            guard let self else { return }
            self.loadingBarWidth?.constant = 120
            UIView.animate(withDuration: 1.8, delay: 0, options: .curveEaseInOut) {
                self.loadingTrack.layoutIfNeeded()
            }
            self.startShimmerLoop()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) { [weak self] in
            self?.pulseIconGlow()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) { [weak self] in
            self?.navigateNext()
        }
    }

    // MARK: - Glow Pulse
    private func pulseIconGlow() {
        UIView.animate(withDuration: 0.25, animations: {
            self.logoIconView.layer.shadowOpacity = 1.0
            self.logoIconView.layer.shadowRadius = 36
            self.logoIconView.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
        }) { _ in
            UIView.animate(withDuration: 0.25) {
                self.logoIconView.layer.shadowOpacity = 0.6
                self.logoIconView.layer.shadowRadius = 20
                self.logoIconView.transform = .identity
            }
        }
    }

    // MARK: - Navigate
    private func navigateNext() {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let sceneDelegate = windowScene.delegate as? SceneDelegate,
            let window = sceneDelegate.window
        else { return }

        let rootVC: UIViewController
        if TokenManager.shared.accessToken != nil {
            WebSocketService.shared.connect()
            rootVC = MainTabBarController()
        } else {
            rootVC = UINavigationController(rootViewController: WelcomeViewController())
        }

        UIView.transition(
            with: window, duration: 0.55,
            options: .transitionCrossDissolve,
            animations: { window.rootViewController = rootVC },
            completion: nil
        )
    }

    // MARK: - Trait Collection
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
}
