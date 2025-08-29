import Foundation
import UIKit

@objcMembers
public class AppLinkWrapper: NSObject {
    
    /// Set up the SDK and start tracking app links and referral events.
    @objc(initializeWithOnDeepLinkProcessed:onReferralLinkDetected:)
    public class func initialize(
        withOnDeepLinkProcessed onDeepLinkProcessed: @escaping (URL?, NSDictionary) -> Void,
        onReferralLinkDetected: ((NSDictionary) -> Void)? = nil
    ) {
        AppLinkService.shared.initialize(onDeepLinkProcessed: { url, info in
            onDeepLinkProcessed(url, info as NSDictionary)
        }, onReferralLinkDetected: { referralInfo in
            onReferralLinkDetected?(referralInfo as NSDictionary)
        })
    }
    
    /// Handle incoming URLs, including custom scheme and universal links.
    @objc(handleAppLinkWithURL:)
    public class func handleAppLink(with incomingURL: URL) {
        AppLinkService.shared.handleAppLink(incomingURL: incomingURL)
    }
    
    /// Get referral details
    @objc(getReferralInfoWithCompletion:)
    public class func getReferralInfo(withCompletion completion: @escaping (NSDictionary) -> Void) {
        AppLinkService.shared.getReferralInfo { info in
            completion(info as NSDictionary)
        }
    }
    
    /// (Deprecated) Get referral details
    @available(*, deprecated, renamed: "getReferralInfo(withCompletion:)")
    @objc(getReferralDetailsWithCompletion:)
    public class func getReferralDetails(withCompletion completion: @escaping (NSDictionary) -> Void) {
        AppLinkService.shared.getReferralDetails{ info in
            completion(info as NSDictionary)
        }
    }
    
    /// Create a new AppLink
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

    /// Handles app launch initiated from a cold start via a custom URL scheme.
    @objc(handleLaunchOptions:)
    public class func handleLaunchOptions(_ launchOptions: NSDictionary) {
        if let options = launchOptions as? [UIApplication.LaunchOptionsKey: Any],
           let url = options[.url] as? URL {
            AppLinkService.shared.handleAppLink(incomingURL: url)
        }
    }

    /// Continues an NSUserActivity for Universal Links, including from a killed state.
    @objc(continueUserActivity:)
    public class func continueUserActivity(_ userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return }
        AppLinkService.shared.handleAppLink(incomingURL: url)
    }
}
