import Foundation
import UIKit

@objcMembers
public class AppLinkWrapper: NSObject {
    
    /// Initialize the SDK and start listening for app links
    /// - Parameter completion: Returns latest URL (if any) and link info payload
    @objc(initializeWithCompletion:)
    public class func initialize(withCompletion completion: @escaping (URL?, NSDictionary) -> Void) {
        AppLinkService.shared.initialize { url, info in
            completion(url, info as NSDictionary)
        }
    }
    
    /// Handle an incoming app link URL (custom scheme or universal link)
    /// - Parameter incomingURL: The URL to handle
    @objc(handleAppLinkWithURL:)
    public class func handleAppLink(with incomingURL: URL) {
        AppLinkService.shared.handleAppLink(incomingURL: incomingURL)
    }
    
    /// Get cached referral details (if available)
    /// - Parameter completion: Returns the referral info dictionary
    @objc(getReferralDetailsWithCompletion:)
    public class func getReferralDetails(withCompletion completion: @escaping (NSDictionary) -> Void) {
        AppLinkService.shared.getReferralDetails { info in
            completion(info as NSDictionary)
        }
    }
    
    /// Create a new dynamic AppLink
    /// - Parameters mirror Swift API but are Objective-C++ friendly (NSString/NSNumber/NSDictionary)
    @objc(createAppLinkWithUrl:name:urlPrefix:shortId:socialMeta:isOpenInBrowserApple:isOpenInIosApp:iosFallbackUrl:isOpenInAndroidApp:isOpenInBrowserAndroid:androidFallbackUrl:completion:)
    public class func createAppLink(
        url: String,
        name: String,
        urlPrefix: String,
        shortId: String? = nil,
        socialMeta: NSDictionary? = nil,
        isOpenInBrowserApple: NSNumber? = nil,
        isOpenInIosApp: NSNumber? = nil,
        iosFallbackUrl: String? = nil,
        isOpenInAndroidApp: NSNumber? = nil,
        isOpenInBrowserAndroid: NSNumber? = nil,
        androidFallbackUrl: String? = nil,
        completion: @escaping (NSDictionary) -> Void
    ) {
        let socialMetaSwift = socialMeta as? [String: Any]
        AppLinkService.shared.createAppLink(
            url: url,
            name: name,
            urlPrefix: urlPrefix,
            shortId: shortId,
            socialMeta: socialMetaSwift,
            isOpenInBrowserApple: isOpenInBrowserApple,
            isOpenInIosApp: isOpenInIosApp,
            iosFallbackUrl: iosFallbackUrl,
            isOpenInAndroidApp: isOpenInAndroidApp,
            isOpenInBrowserAndroid: isOpenInBrowserAndroid,
            androidFallbackUrl: androidFallbackUrl
        ) { result in
            completion(result as NSDictionary)
        }
    }

    /// Handle cold-start launch options (custom URL scheme)
    /// - Parameter launchOptions: UIApplication launch options dictionary
    @objc(handleLaunchOptions:)
    public class func handleLaunchOptions(_ launchOptions: NSDictionary) {
        if let options = launchOptions as? [UIApplication.LaunchOptionsKey: Any],
           let url = options[.url] as? URL {
            AppLinkService.shared.handleAppLink(incomingURL: url)
        }
    }

    /// Continue NSUserActivity for Universal Links (works from killed state)
    /// - Parameter userActivity: NSUserActivity from application:continueUserActivity:
    @objc(continueUserActivity:)
    public class func continueUserActivity(_ userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return }
        AppLinkService.shared.handleAppLink(incomingURL: url)
    }
}
