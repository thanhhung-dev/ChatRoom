import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // MARK: - Scene Lifecycle

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Khởi tạo window và thiết lập Root View Controller bằng code
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        window.rootViewController = SplashViewController()
        window.makeKeyAndVisible()

        // Lắng nghe sự kiện yêu cầu đăng xuất từ hệ thống
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogout),
            name: .didLogoutRequired,
            object: nil
        )
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Hủy lắng nghe Notification khi scene bị hủy
        NotificationCenter.default.removeObserver(self, name: .didLogoutRequired, object: nil)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        guard TokenManager.shared.accessToken != nil else { return }
        WebSocketService.shared.connect()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
    }

    // MARK: - Logout Logic

    @objc private func handleLogout() {
        TokenManager.shared.clear()
        WebSocketService.shared.disconnect()

        DispatchQueue.main.async {
            guard let window = self.window else { return }
            let splash = SplashViewController()
            UIView.transition(
                with: window,
                duration: 0.35,
                options: .transitionCrossDissolve,
                animations: { window.rootViewController = splash }
            )
        }
    }
}
