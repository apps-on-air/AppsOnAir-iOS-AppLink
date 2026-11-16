import AppsOnAir_AppLink
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let appLinkService = AppLinkService.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // One call registers every callback. onReferralLinkDetected is deprecated and kept here
        // only to compare its payload with onAttributionListener: it is detection-only and drops
        // `appsFlyer` and the attribution fields.
        // Initialize the AppLink to track the deeplink and attribution tracking.
        appLinkService.initialize(
            onDeepLinkProcessed: { url, linkInfo in
                // write the code for handling onDeepLinkProcessed flow based on url
                var payload = linkInfo
                payload["url"] = url?.absoluteString
                AppLinkResultStore.shared[.deepLink] = responseText(payload)
            },
            onReferralLinkDetected: { referralInfo in
                // write the code for handling onReferralLinkDetected flow based on referralInfo
                AppLinkResultStore.shared[.deprecatedListener] = responseText(referralInfo)
            },
            onAttributionListener: { attributionInfo in
                // write the code for handling onAttributionListener flow based on attributionInfo
                AppLinkResultStore.shared[.attributionListener] = responseText(attributionInfo)
            })
        
        return true
    }
    
    // Links are delivered to SceneDelegate (UIScene lifecycle, required on iOS 27);
    // AppsOnAir AppLink hooks it automatically.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}
