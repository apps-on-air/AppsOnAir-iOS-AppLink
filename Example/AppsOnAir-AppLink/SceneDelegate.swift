import UIKit

/// iOS 27 requires the UIScene lifecycle for apps built with its SDK.
/// AppsOnAir AppLink hooks this class automatically to receive Universal Links and custom URL schemes.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // The window and root view controller are created from Main.storyboard (see Info.plist).
        guard scene is UIWindowScene else { return }
    }
}
