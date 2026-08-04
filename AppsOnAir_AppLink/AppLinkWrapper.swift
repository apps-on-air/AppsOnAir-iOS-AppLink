import Foundation

#if canImport(UIKit)
    import UIKit

    @objc(AppLinkWrapper)
    @objcMembers
    public class AppLinkWrapper: NSObject {

        /// Set up the SDK and start tracking app links and referral events.
        /// - Parameters:
        ///   - onDeepLinkProcessed: Callback invoked with the resolved deep link and its info.
        ///   - onAttributionListener: Callback invoked when a referral fetch actually runs (first open,
        ///     or no referral cached yet) — same trigger as `onReferralLinkDetected`. The payload
        ///     includes the referral info plus `isFirstLaunch`, `firstInstallTime`, `isConsumed`, and
        ///     (clipboard/advanced deferred link approach only) `attributionStatus` ("organic"/"nonorganic").
        @objc(initializeWithOnDeepLinkProcessed:onAttributionListener:)
        public class func initialize(
            withOnDeepLinkProcessed onDeepLinkProcessed: @escaping (URL?, NSDictionary) -> Void,
            onAttributionListener: ((NSDictionary) -> Void)? = nil
        ) {
            AppLinkService.shared.initialize(
                onDeepLinkProcessed: { url, info in
                    onDeepLinkProcessed(url, info as NSDictionary)
                },
                onAttributionListener: { attributionInfo in
                    onAttributionListener?(attributionInfo as NSDictionary)
                })
        }

        /// - Parameters:
        ///   - onDeepLinkProcessed: Callback invoked with the resolved deep link and its info.
        ///   - onReferralLinkDetected: *(Deprecated)* Use `onAttributionListener` instead. Only fires
        ///     when a referral fetch actually runs (first open, or no referral cached yet). Receives
        ///     just the raw referral dictionary — use `initialize(withOnDeepLinkProcessed:onAttributionListener:)`
        ///     for the referral info plus `isFirstLaunch`, `firstInstallTime`, `isConsumed`, and
        ///     (clipboard/advanced deferred link approach only) `attributionStatus` ("organic"/"nonorganic").
        @available(
            *,
            deprecated,
            message:
                "`onReferralLinkDetected` is deprecated and will be removed in a future release. Use `onAttributionListener` instead."
        )
        @objc(initializeWithOnDeepLinkProcessed:onReferralLinkDetected:)
        public class func initialize(
            withOnDeepLinkProcessed onDeepLinkProcessed: @escaping (URL?, NSDictionary) -> Void,
            onReferralLinkDetected: ((NSDictionary) -> Void)? = nil
        ) {
            AppLinkService.shared.initialize(
                onDeepLinkProcessed: { url, info in
                    onDeepLinkProcessed(url, info as NSDictionary)
                },
                onReferralLinkDetected: { referralInfo in
                    onReferralLinkDetected?(referralInfo as NSDictionary)
                })
        }

        /// Handle incoming URLs, including custom scheme and universal links.
        @objc(handleAppLinkWithURL:)
        public class func handleAppLink(with incomingURL: URL) {
            AppLinkService.shared.handleAppLink(incomingURL: incomingURL)
        }

        /// (Deprecated) Get referral info
        @available(*, deprecated, renamed: "getAttributionInfo(withCompletion:)")
        @objc(getReferralInfoWithCompletion:)
        public class func getReferralInfo(
            withCompletion completion: @escaping (NSDictionary) -> Void
        ) {
            AppLinkService.shared.getReferralInfo { info in
                completion(info as NSDictionary)
            }
        }

        /// (Deprecated) Get referral details
        @available(*, deprecated, renamed: "getAttributionInfo(withCompletion:)")
        @objc(getReferralDetailsWithCompletion:)
        public class func getReferralDetails(
            withCompletion completion: @escaping (NSDictionary) -> Void
        ) {
            AppLinkService.shared.getReferralDetails { info in
                completion(info as NSDictionary)
            }
        }

        /// Get referral/attribution info. Same as the deprecated `getReferralInfo`, with
        /// `isFirstLaunch`, `firstInstallTime`, and `isConsumed` included in the response, plus
        /// `attributionStatus` ("organic"/"nonorganic") when using the clipboard (advanced
        /// deferred link) approach.
        @objc(getAttributionInfoWithCompletion:)
        public class func getAttributionInfo(
            withCompletion completion: @escaping (NSDictionary) -> Void
        ) {
            AppLinkService.shared.getAttributionInfo { info in
                completion(info as NSDictionary)
            }
        }

        /// Create a new AppLink
        @objc(
            createAppLinkWithUrl:name:urlPrefix:shortId:socialMeta:isOpenInBrowserApple:
            isOpenInIosApp:
            iosFallbackUrl:isOpenInAndroidApp:isOpenInBrowserAndroid:androidFallbackUrl:appsFlyer:attributionTtl:completion:
        )
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
            appsFlyer: [String: Any]? = nil,
            attributionTtl: NSNumber? = nil,
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
                androidFallbackUrl: androidFallbackUrl,
                appsFlyer: appsFlyer,
                attributionTtl: attributionTtl
            ) { result in
                completion(result as NSDictionary)
            }
        }

        /// Handles app launch initiated from a cold start via a custom URL scheme.
        @objc(handleLaunchOptions:)
        public class func handleLaunchOptions(_ launchOptions: NSDictionary) {
            if let options = launchOptions as? [UIApplication.LaunchOptionsKey: Any],
                let url = options[.url] as? URL
            {
                AppLinkService.shared.handleAppLink(incomingURL: url)
            }
        }

        /// Continues an NSUserActivity for Universal Links, including from a killed state.
        @objc(continueUserActivity:)
        public class func continueUserActivity(_ userActivity: NSUserActivity) {
            guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
                let url = userActivity.webpageURL
            else { return }
            AppLinkService.shared.handleAppLink(incomingURL: url)
        }
    }
#endif
