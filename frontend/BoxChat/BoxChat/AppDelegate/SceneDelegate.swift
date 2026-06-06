import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // Luôn bắt đầu từ Splash — Splash tự navigate sau khi xong
        window.rootViewController = SplashViewController()
        window.makeKeyAndVisible()

        // Lắng nghe logout từ bất kỳ đâu trong app
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogout),
            name: .didLogoutRequired,
            object: nil
        )
    }

    // MARK: - Logout

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

    // MARK: - Scene Lifecycle

    func sceneDidDisconnect(_ scene: UIScene) {
        NotificationCenter.default.removeObserver(self, name: .didLogoutRequired, object: nil)
    }
}
