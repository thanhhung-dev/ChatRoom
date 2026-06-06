import UIKit

class MainTabBarController: UITabBarController {

  override func viewDidLoad() {
    super.viewDidLoad()
    setupTabBarAppearance()
    setupViewControllers()
  }

  private func setupTabBarAppearance() {
    tabBar.tintColor = .systemBlue
    tabBar.unselectedItemTintColor = .systemGray

    let appearance = UITabBarAppearance()
    appearance.configureWithDefaultBackground()
    appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)

    tabBar.standardAppearance = appearance
    if #available(iOS 15.0, *) {
      tabBar.scrollEdgeAppearance = appearance
    }
  }
    
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    private func setupTabBarAppearance() {
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .systemGray
        
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    private func setupViewControllers() {
        let chatListVC = RoomListViewController()
        let chatNav = UINavigationController(rootViewController: chatListVC)
        chatNav.tabBarItem = UITabBarItem(
            title: "Tin nhắn",
            image: UIImage(systemName: "bubble.left.and.bubble.right"),
            selectedImage: UIImage(systemName: "bubble.left.and.bubble.right.fill")
        )
        
        let friendsVC = FriendsViewController()
        let friendsNav = UINavigationController(rootViewController: friendsVC)
        friendsNav.tabBarItem = UITabBarItem(
            title: "Bạn bè",
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2.fill")
        )
        
        let profileVC = UserProfileViewController()
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: "Cá nhân",
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )
        
        viewControllers = [chatNav, friendsNav, profileNav]
    }
=======
=======
>>>>>>> Stashed changes
  private func setupViewControllers() {
    let chatListVC = RoomListViewController()
    let chatNav = UINavigationController(rootViewController: chatListVC)
    chatNav.tabBarItem = UITabBarItem(
      title: "Chats",
      image: UIImage(systemName: "message"),
      selectedImage: UIImage(systemName: "message.fill")
    )

    let friendsVC = FriendsViewController()
    let friendsNav = UINavigationController(rootViewController: friendsVC)
    friendsNav.tabBarItem = UITabBarItem(
      title: "Danh bạ",
      image: UIImage(systemName: "person.2"),
      selectedImage: UIImage(systemName: "person.2.fill")
    )

    let exploreVC = UIViewController()
    let exploreNav = UINavigationController(rootViewController: exploreVC)
    exploreNav.tabBarItem = UITabBarItem(
      title: "Khám phá",
      image: UIImage(systemName: "plus.circle"),
      selectedImage: UIImage(systemName: "plus.circle.fill")
    )

    let notificationVC = UIViewController()
    let notificationNav = UINavigationController(rootViewController: notificationVC)
    notificationNav.tabBarItem = UITabBarItem(
      title: "Thông báo",
      image: UIImage(systemName: "bell"),
      selectedImage: UIImage(systemName: "bell.fill")
    )

    let profileVC = UserProfileViewController()
    let profileNav = UINavigationController(rootViewController: profileVC)
    profileNav.tabBarItem = UITabBarItem(
      title: "Cá nhân",
      image: UIImage(systemName: "person"),
      selectedImage: UIImage(systemName: "person.fill")
    )

    viewControllers = [chatNav, friendsNav, exploreNav, notificationNav, profileNav]
  }
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
}
