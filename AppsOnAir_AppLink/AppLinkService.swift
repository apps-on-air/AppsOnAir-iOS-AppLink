import AppsOnAir_Core
import Combine

#if canImport(UIKit)
    import UIKit

    @objc public class AppLinkService: NSObject {

        @objc public static let shared = AppLinkService()

        //Core Services initialization
        let appsOnAirCoreServices = AppsOnAirCoreServices()

        //App Helper service initialization
        let appHelper = AppHelper.shared

        /// `true` only on the very first app launch
        internal var isFirstLaunch: Bool {
            return appHelper.isAppFirstOpen
        }

        /// Device's first install time, as an epoch String
        internal var firstInstallTime: Int64? {
            return appHelper.firstInstallTime
        }

        /// `false` this session until a successful referral fetch
        internal var isConsumed: Bool {
            return appHelper.isConsumed
        }

        //Latest link for Dynamic Link
        @Published var latestLink: URL?

        //Latest link for Referral Link
        @Published var latestReferralURL: URL?

        // Listener for whenever link is Update
        private var linkListener: AnyCancellable?

        private var latestReferralInfo: [String: Any]?

        /// Attribution status: organic/non-organic. Backed by `AppHelper`, which restores it from
        /// UserDefaults on launch and persists every assignment — so a status resolved on first
        /// launch survives relaunches. Defaults to organic until something is resolved and stored.
        private var latestAttributionStatus: String {
            get { appHelper.attributionStatus }
            set { appHelper.updateAttributionStatus(newValue) }
        }

        /// Clipboard `applink_click_time` in epoch milliseconds, retained so `getAttributionInfo`
        /// can report it alongside the Android SDK's equivalent field. Nil until a deferred link
        /// carrying the param is resolved.
        /// Backed by `AppHelper`, which restores it from UserDefaults on launch and persists every
        /// assignment. The clipboard is only read on first open, so without persistence this would
        /// be nil from launch 2 onward and drop out of the attribution payload.
        /// Assigning nil is ignored — a later launch with no clipboard must not erase it.
        private var latestClickTimestampInMilliseconds: TimeInterval? {
            get { appHelper.clickTime }
            set {
                guard let newValue else { return }
                appHelper.updateClickTime(newValue)
            }
        }

        // Listener for whenever referral link is Update
        private var referralLinkListener: AnyCancellable?

        // Manage for API call
        private let dispatchGroup = DispatchGroup()

        private var attributionListener: (([String: Any]) -> Void)?
        private var firstLaunchExpiredObserver: NSObjectProtocol?

        deinit {
            // Cancel the listener when the object is deallocated
            linkListener?.cancel()
            referralLinkListener?.cancel()
            NotificationCenter.default.removeObserver(self)
        }

        /// Common initialization flow
        private func performInitialization(
            onDeepLinkProcessed: @escaping (URL?, [String: Any]) -> Void,
            onReferralLinkDetected: (([String: Any]) -> Void)? = nil,
            onAttributionListener: (([String: Any]) -> Void)? = nil
        ) {
            // Initialize AppsOnAir Core
            appsOnAirCoreServices.initialize()

            // Initialize swizzling
            _ = AppSwizzler.shared

            attributionListener = onAttributionListener
            if let firstLaunchExpiredObserver {
                NotificationCenter.default.removeObserver(firstLaunchExpiredObserver)
            }
            firstLaunchExpiredObserver = NotificationCenter.default.addObserver(
                forName: .appsOnAirFirstLaunchDidExpire, object: nil, queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                Logger.logInternal(
                    "AppLinkService: appsOnAirFirstLaunchDidExpire received, re-firing onAttributionListener"
                )
                self.getAttributionInfo { attributionInfo in
                    self.attributionListener?(attributionInfo)
                }
            }

            // Listen for network status
            appsOnAirCoreServices.networkStatusListenerHandler { isConnected in
                guard self.linkListener == nil else { return }

                // Deep link listener
                self.linkListener = self.$latestLink.sink { [weak self] _ in
                    self?.onAppLinkHandler(isNetworkConnected: isConnected) { url, linkInfo in
                        onDeepLinkProcessed(url, linkInfo)
                    }
                }

                // Referral listener
                self.referralLinkListener = self.$latestReferralURL
                    .dropFirst()
                    .sink { [weak self] _ in
                        guard let self else { return }

                        self.referralHandler(isCompletionCall: true) { referralInfo in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                onReferralLinkDetected?(self.withoutAppsFlyer(referralInfo))

                                self.getAttributionInfo { attributionInfo in
                                    onAttributionListener?(attributionInfo)
                                }
                            }
                        }
                    }
            }

            // Trigger referral flow
            referralHandler(isAPICall: true)
        }

        /// Initializes the common services like AppsOnAir Core, swizzling,
        /// deep link handling, referral detection, and attribution.
        /// - Parameters:
        ///   - onDeepLinkProcessed: Callback invoked with the resolved deep link and its info.
        ///   - onAttributionListener: Callback invoked when a referral fetch actually runs (first open,
        ///     or no referral cached yet) — same trigger as `onReferralLinkDetected`. Payload includes
        ///     referral info plus `isFirstLaunch`, `firstInstallTime`, `isConsumed`, `attributionStatus`.
        @objc
        public func initialize(
            onDeepLinkProcessed: @escaping (URL?, [String: Any]) -> Void,
            onAttributionListener: (([String: Any]) -> Void)? = nil
        ) {
            performInitialization(
                onDeepLinkProcessed: onDeepLinkProcessed,
                onAttributionListener: onAttributionListener
            )
        }

        /// - Parameters:
        ///   - onDeepLinkProcessed: Callback invoked with the resolved deep link and its info.
        ///   - onReferralLinkDetected: *(Deprecated)* Use `onAttributionListener` instead. Only fires
        ///     when a referral fetch actually runs (first open, or no referral cached yet). Receives
        ///     just the raw referral dictionary — use `initialize(onDeepLinkProcessed:onAttributionListener:)`
        ///     for the referral info plus `isFirstLaunch`, `firstInstallTime`, `isConsumed`, `attributionStatus`.
        @available(
            *,
            deprecated,
            message:
                "`onReferralLinkDetected` is deprecated and will be removed in a future release. Use `onAttributionListener` instead."
        )
        @objc(initializeOnDeepLinkProcessed:onReferralLinkDetected:)
        public func initialize(
            onDeepLinkProcessed: @escaping (URL?, [String: Any]) -> Void,
            onReferralLinkDetected: (([String: Any]) -> Void)? = nil
        ) {
            performInitialization(
                onDeepLinkProcessed: onDeepLinkProcessed,
                onReferralLinkDetected: onReferralLinkDetected
            )
        }

        ///handling when appLink is listen
        private func onAppLinkHandler(
            isNetworkConnected: Bool, completion: @escaping (URL?, [String: Any]) -> Void
        ) {
            DispatchQueue.main.async {
                // Ensure we have a valid link and network connectivity before proceeding
                if let appLink = self.latestLink, !appLink.absoluteString.trimmed.isEmpty {
                    // check internet connectivity
                    if isNetworkConnected {
                        // Resolve final deep link: use Universal Link directly or extract `link` param from custom URI
                        //To identify the incoming URL is URL scheme or Universal Link
                        let isUniversalLink = ["http", "https"].contains(
                            appLink.scheme?.lowercased() ?? "")

                        let appLinkURL =
                            isUniversalLink
                            ? appLink
                            : URLComponents(url: appLink, resolvingAgainstBaseURL: false)?
                                .queryItems?
                                .first(where: { $0.name == "link" })?
                                .value
                                .flatMap { URL(string: $0) }

                        // Ensure URL starts with scheme (default to https)
                        let resolvedAppLink = appLinkURL.flatMap {
                            URL(
                                string: $0.absoluteString.hasPrefix("http")
                                    ? $0.absoluteString : "https://" + $0.absoluteString)
                        }

                        // Extract domain with percent decoding on iOS 16+
                        let domain = {
                            if #available(iOS 16.0, *) {
                                return resolvedAppLink?.host(percentEncoded: false) ?? ""
                            }
                            return resolvedAppLink?.host ?? ""
                        }()

                        // Get last path component as link ID
                        let linkId = resolvedAppLink?.lastPathComponent ?? ""

                        if !self.isValidShortId(linkId) {
                            completion(self.latestLink, [:])
                            return
                        }
                        // Always fetch link info after optional count tracking
                        let fetchLinkInfo = {
                            if isUniversalLink {
                                AppLinkApiService.apiLinkAnalytics(
                                    isClicked: true, urlPrefix: domain, shortId: linkId
                                ) { _ in }
                            }
                            AppLinkApiService.apiFetchLinkInfo(domain: domain, linkId: linkId) {
                                latestLinkData in
                                let linkInfo =
                                    latestLinkData["data"] as? [String: Any] ?? latestLinkData
                                completion(self.latestLink, linkInfo)
                            }
                        }

                        // Fetch link info via API
                        fetchLinkInfo()
                    }
                    // If network is not available, log and return error
                    else {
                        Logger.logInfo(errorNetwork, prefix: appsOnAirLink)
                        completion(nil, [errorStr: errorNetwork])
                    }
                }
            }
        }

        private func getAppLinkDataFromClipboard(completion: @escaping (String?) -> Void) {
            DispatchQueue.main.async {
                // Check feature flag
                guard (Bundle.main.infoDictionary?[EnableAdvancedDeferredLinkKey] as? Bool) == true
                else {
                    Logger.logInternal("⚠️ \(enableAdvancedDeferredLinkDisabled)")
                    completion(nil)
                    return
                }

                // Validate bundle identifier
                guard let bundleId = Bundle.main.bundleIdentifier, !bundleId.isEmpty else {
                    Logger.logInternal("❌ \(invalidBundleIdentifier)")
                    completion(nil)
                    return
                }

                // Build key and read clipboard
                let appsonairKey =
                    "appsonair_\(self.appsOnAirCoreServices.appId)_\(bundleId)_referral="
                guard let clipboard = self.appHelper.readClipBoard() else {
                    Logger.logInternal("❌ \(clipboardEmpty)")
                    completion(nil)
                    return
                }

                // Extract value if key exists
                guard let range = clipboard.range(of: appsonairKey), clipboard.contains(bundleId)
                else {
                    Logger.logInternal("❌ '\(appsonairKey)' \(notFoundBundle)")
                    completion(nil)
                    return
                }

                // Get the value from clipboard
                let clipBoardDataFromKey = String(clipboard[range.upperBound...])
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines)
                UIPasteboard.general.string = ""
                Logger.logInternal("✅ \(foundAppsOnAirKey): \(clipBoardDataFromKey)")
                completion(clipBoardDataFromKey)
            }
        }

        func isValidShortId(_ linkId: String) -> Bool {
            guard !linkId.isEmpty,
                linkId.split(separator: "/")
                    .last != nil
            else {
                Logger.logInternal(errorShortIdMissing)
                return false
            }
            return true
        }

        private func referralHandler(
            isAPICall: Bool = false, isCompletionCall: Bool = false,
            completion: (([String: Any]) -> Void)? = nil
        ) {
            let referralInfoFromKeyChain = appHelper.readFromKeychain(key: referralData)
            // Retrieve stored data from the device keychain
            // If referral data is missing or the app was reinstalled, retrieve it from the server
            if ((referralInfoFromKeyChain?.isEmpty ?? false) || AppHelper.shared.isAppFirstOpen)
                && isAPICall
            {
                dispatchGroup.enter()
                self.getAppLinkDataFromClipboard { appLinkInfo in
                    if let appLinkInfo = appLinkInfo, !appLinkInfo.isEmpty,
                        let url = URL(string: appLinkInfo)
                    {
                        Logger.logInternal("Clipboard called")

                        let domain = url.host ?? ""
                        let shortId = url.pathComponents.dropFirst().first ?? ""

                        Logger.logInternal("Domain: \(domain)")
                        Logger.logInternal("Short ID: \(shortId)")
                        if !self.isValidShortId(shortId) {
                            self.dispatchGroup.leave()
                            return
                        }
                        let clipboardURLComponents = URLComponents(
                            url: url, resolvingAgainstBaseURL: false)

                        var appLinkReferralLinkParams: [String: Any] = [:]
                        if let hashKey = clipboardURLComponents?.queryItems?.first(where: {
                            $0.name == "hash_key"
                        })?.value {
                            Logger.logInternal("Hash Key: \(hashKey)")
                            appLinkReferralLinkParams["data"] = ["hashKey": hashKey]
                        }

                        // fetch the click time from the clipboard, same as the hash key above
                        let clickTimestamp: TimeInterval? = clipboardURLComponents?.queryItems?
                            .first(where: { $0.name == applinkClickTimeParam })?.value
                            .flatMap { Double($0) }

                        // Retain it as soon as it is read, so it reaches the attribution payload
                        // even when the referral call fails or the status is never computed.
                        self.latestClickTimestampInMilliseconds = clickTimestamp

                        AppLinkApiService.apiReferralInfo(
                            appLinParams: appLinkReferralLinkParams,
                            isEnableAdvancedDeferredLink: true
                        ) { rawLinkInfo in
                            _ = self.appHelper.removeDataFromKeychain(key: referralData)

                            var linkInfo = rawLinkInfo

                            if (rawLinkInfo[statusCodeKey] as? Int) == successStatusCode {
                                // isConsumed only takes effect starting the next app launch
                                AppHelper.shared.isConsumed = true
                                AppHelper.shared.userDefaults.set(true, forKey: isConsumedKey)

                                linkInfo.removeValue(forKey: statusCodeKey)
                            }

                            let referralStatus = linkInfo["status"] as? String

                            self.latestReferralInfo = linkInfo
                            self.appHelper.saveToKeychain(key: referralData, value: linkInfo)
                            self.latestReferralURL = url

                            if referralStatus == "SUCCESS" {
                                // clipboard-only: compare click time vs first install time vs attributionTtl.
                                // The resolved status is persisted by `computeAttributionStatus` itself and
                                // read back in `getAttributionInfo`, so it is not copied into `linkInfo` here.
                                self.computeAttributionStatus(
                                    clickTimestamp: clickTimestamp,
                                    linkInfo: linkInfo)
                            }

                            if referralStatus == "SUCCESS" {
                                AppLinkApiService.apiLinkAnalytics(
                                    isClicked: false,
                                    urlPrefix: domain,
                                    shortId: shortId,
                                    isInstalled: true,
                                    isFirstOpen: true
                                ) { analyticsInfo in
                                    if let analyticsStatus = analyticsInfo["status"] as? String,
                                        analyticsStatus == "SUCCESS"
                                    {
                                        AppHelper.shared.userDefaults.set(
                                            true, forKey: isReferralKey)
                                        if let referralLink = self.latestReferralURL,
                                            let linkInfo = self.latestReferralInfo
                                        {
                                            Logger.logInternal(
                                                "Referral: \(referralLink), info: \(linkInfo)")
                                            self.dispatchGroup.leave()
                                        }
                                    } else {
                                        self.errorReferralHandler()
                                    }
                                }
                            } else {
                                self.errorReferralHandler()
                            }
                        }
                    } else {
                        Logger.logInternal("API called")
                        AppLinkApiService.apiReferralInfo { rawReferralLinkInfo in
                            _ = self.appHelper.removeDataFromKeychain(key: referralData)

                            var referralLinkInfo = rawReferralLinkInfo

                            if (rawReferralLinkInfo[statusCodeKey] as? Int) == successStatusCode {

                                AppHelper.shared.isConsumed = true
                                AppHelper.shared.userDefaults.set(true, forKey: isConsumedKey)

                                // strip the internal statusCode before storing/exposing to the host app
                                referralLinkInfo.removeValue(forKey: statusCodeKey)
                            }

                            self.latestReferralInfo = referralLinkInfo

                            self.appHelper.saveToKeychain(
                                key: referralData, value: referralLinkInfo)

                            // Check referral API response
                            if let referralStatus = referralLinkInfo["status"] as? String,
                                referralStatus == "SUCCESS",
                                let referralInfo = referralLinkInfo["data"] as? [String: Any],
                                let referralLink = referralInfo["referralLink"] as? String,
                                let shortId = referralInfo["shortId"] as? String,
                                let referralURL = URL(string: referralLink),
                                let domain = referralURL.host
                            {
                                self.latestAttributionStatus = attributionStatusNonOrganic
                                // Call analytics of referral result
                                AppLinkApiService.apiLinkAnalytics(
                                    isClicked: false,
                                    urlPrefix: domain,
                                    shortId: shortId,
                                    isInstalled: true,
                                    isFirstOpen: true
                                ) { analyticsInfo in
                                    if let analyticsStatus = analyticsInfo["status"] as? String,
                                        analyticsStatus == "SUCCESS"
                                    {
                                        DispatchQueue.main.async {
                                            AppHelper.shared.userDefaults.set(
                                                true, forKey: isReferralKey)
                                            self.latestReferralURL = referralURL
                                            // Only set referralLink and call completion once here
                                            Logger.logInternal(referralSuccessFully)
                                            if let referralLink = self.latestReferralURL,
                                                let linkInfo = self.latestReferralInfo
                                            {
                                                Logger.logInternal(
                                                    "Referral: \(referralLink), info: \(linkInfo)")
                                                self.dispatchGroup.leave()
                                            }
                                        }
                                    } else {
                                        self.errorReferralHandler()
                                    }
                                }
                            } else {
                                self.errorReferralHandler()
                            }
                        }
                    }
                }
            }
            dispatchGroup.notify(queue: .main) {
                if isCompletionCall {
                    completion?(self.latestReferralInfo ?? [:])
                }
            }
        }

        /// handle for handling error
        private func errorReferralHandler() {
            self.latestReferralURL = URL(string: "")
            self.dispatchGroup.leave()
        }

        private func computeAttributionStatus(
            clickTimestamp: TimeInterval?, linkInfo: [String: Any]?
        ) {
            // Referral found; default to non-organic and refine with click-time data.
            latestAttributionStatus = attributionStatusNonOrganic

            // Clipboard `applink_click_time` is in milliseconds. Already retained where it was read
            // from the clipboard, so it is only consumed here.
            guard let clickTimestampInMilliseconds = clickTimestamp else {
                Logger.logInternal(
                    "attributionStatus: no applink_click_time in clipboard — defaulting to non-organic (referral found)"
                )
                return
            }

            // Read TTL from response data when available; default to empty.
            let data: [String: Any] = linkInfo?[dataKey] as? [String: Any] ?? [:]

            let rawAttributionTtl =
                linkInfo?[attributionTtlResponseKey] ?? data[attributionTtlResponseKey]

            let attributionTtl: Double?
            switch rawAttributionTtl {
            case let value as Int: attributionTtl = Double(value)
            case let value as Double: attributionTtl = value
            case let value as NSNumber: attributionTtl = value.doubleValue
            case let value as String: attributionTtl = Double(value)
            default: attributionTtl = nil
            }

            guard let attributionTtl = attributionTtl else {
                Logger.logInternal(
                    "attributionStatus: no attributionTtl in referral response (raw: \(String(describing: rawAttributionTtl))) — defaulting to non-organic (referral found)"
                )
                return
            }

            guard let firstInstallMilliseconds = appHelper.firstInstallTime else {
                Logger.logInternal(
                    "attributionStatus: could not read firstInstallTime — defaulting to non-organic (referral found)"
                )
                return
            }

            // firstInstallTime is epoch milliseconds; the comparison below works in seconds.
            let firstInstallEpoch = Measurement(
                value: Double(firstInstallMilliseconds), unit: UnitDuration.milliseconds
            ).converted(to: .seconds).value

            // scale the click time to epoch seconds so both sides use the same unit
            let clickTimestampInSeconds: Double

            let clickTimestampMeasurement = Measurement(
                value: clickTimestampInMilliseconds, unit: UnitDuration.milliseconds)
            clickTimestampInSeconds = clickTimestampMeasurement.converted(to: .seconds).value

            let diffInSeconds = firstInstallEpoch - clickTimestampInSeconds

            latestAttributionStatus =
                diffInSeconds > attributionTtl
                ? attributionStatusOrganic : attributionStatusNonOrganic

            Logger.logInternal(
                "attributionStatus = \(latestAttributionStatus) (diff: \(diffInSeconds)s, ttl: \(attributionTtl)s)"
            )
        }

        /// Returns a copy of `info` without the `appsFlyer` object. The API returns it on the
        /// dynamic-link and referral/details endpoints, but it belongs to the newer attribution
        /// surface: only `getAttributionInfo` / `onAttributionListener` expose it, so the
        /// deprecated referral APIs and `onReferralLinkDetected` keep their original payload.
        /// Removed at both levels because the key may sit at the root or inside `data`.
        private func withoutAppsFlyer(_ info: [String: Any]) -> [String: Any] {
            var info = info
            info.removeValue(forKey: appsFlyerKey)
            if var data = info[dataKey] as? [String: Any] {
                data.removeValue(forKey: appsFlyerKey)
                info[dataKey] = data
            }
            return info
        }

        /// (Deprecated) Get referral info
        @available(*, deprecated, renamed: "getAttributionInfo")
        @objc public func getReferralInfo(completion: @escaping ([String: Any]) -> Void) {
            dispatchGroup.notify(queue: .main) {
                if !((self.latestReferralInfo ?? [:]).isEmpty) {
                    completion(self.withoutAppsFlyer(self.latestReferralInfo ?? [:]))
                    return
                }
                let referralInfoFromKeyChain = self.appHelper.readFromKeychain(key: referralData)
                completion(self.withoutAppsFlyer(referralInfoFromKeyChain ?? [:]))
            }
        }

        /// Get referral and attribution info. Same as the deprecated `getReferralInfo`, with attribution info
        /// nested inside `data`: `isFirstLaunch`, `firstInstallTime`, `isConsumed`, and
        /// `attributionStatus` — the last resolved status, restored from storage on later launches.
        @objc public func getAttributionInfo(completion: @escaping ([String: Any]) -> Void) {
            var attributionInfo =
                !((self.latestReferralInfo ?? [:]).isEmpty)
                ? (self.latestReferralInfo ?? [:])
                : (self.appHelper.readFromKeychain(key: referralData) ?? [:])

            // Append attribution fields to response data.
            var data: [String: Any] = attributionInfo[dataKey] as? [String: Any] ?? [:]
            data[isFirstLaunchKey] = self.isFirstLaunch
            if let firstInstallTime = self.firstInstallTime {
                data[firstInstallTimeKey] = firstInstallTime
            }
            data[isConsumedKey] = self.isConsumed
            data[attributionStatusKey] = self.latestAttributionStatus
            if let clickTimestamp = self.latestClickTimestampInMilliseconds {
                data[applinkClickTimeParam] = Int64(clickTimestamp.rounded())
            }
            attributionInfo[dataKey] = data

            completion(attributionInfo)
        }

        ///help to handle the get link for referral info
        @available(*, deprecated, renamed: "getAttributionInfo")
        @objc public func getReferralDetails(completion: @escaping ([String: Any]) -> Void) {
            // Retrieve stored data from the device keychain
            let referralInfoFromKeyChain = appHelper.readFromKeychain(key: referralData)
            completion(withoutAppsFlyer(referralInfoFromKeyChain ?? [:]))
        }

        ///help to handle the latest link for universal link and custom URL schema
        @objc public func handleAppLink(incomingURL: URL) {
            self.appLinkHandler(inComingURL: incomingURL)
        }

        /// Helps create a dynamic AppLink compatible with iOS, Android, and web browsers.
        /// - Parameters:
        ///   - url: The deep link URL that the user should be direct.
        ///   - name: A human-readable name for the link, useful for display or analytics.
        ///   - urlPrefix: The domain prefix for the AppLink. **Do not include** `https://` or `http://`. Example: `example.page.link`.
        ///   - shortId: *(Optional)* A custom short ID to uniquely identify the link. If not provided, one will be generated automatically.
        ///   - socialMeta: *(Optional)* Dictionary containing metadata for social sharing (e.g., title, image URL, description).
        ///   - isOpenInBrowserApple: `NSNumber` (e.g., `1` or `0`) indicating whether the link should open in a browser on iOS.
        ///   - isOpenInIosApp: `NSNumber` (e.g., `1` or `0`) indicating whether the link should open directly in the iOS app.
        ///   - iosFallbackUrl: *(Optional)* Fallback URL used if the app is not installed on iOS.
        ///   - isOpenInAndroidApp: `NSNumber` (e.g., `1` or `0`) indicating whether the link should open directly in the Android app.
        ///   - isOpenInBrowserAndroid: `NSNumber` (e.g., `1` or `0`) indicating whether the link should open in a browser on Android.
        ///   - androidFallbackUrl: *(Optional)* Fallback URL used if the app is not installed on Android.
        ///   - appsFlyer: *(Optional)* Dictionary containing AppsFlyer attribution params (e.g., channel, campaignId, campaign, subs, metaTitle, metaDescription).
        ///   - attributionTtl: *(Optional)* `NSNumber` — time-to-live, in seconds, for attribution of this link.
        ///   - completion: A closure that returns a dictionary containing the result of the link creation.
        @objc public func createAppLink(
            url: String,
            name: String,
            urlPrefix: String,
            shortId: String? = nil,
            socialMeta: [String: Any]? = nil,
            isOpenInBrowserApple: NSNumber?,
            isOpenInIosApp: NSNumber?,
            iosFallbackUrl: String? = nil,
            isOpenInAndroidApp: NSNumber?,
            isOpenInBrowserAndroid: NSNumber?,
            androidFallbackUrl: String? = nil,
            appsFlyer: [String: Any]? = nil,
            attributionTtl: NSNumber? = nil,
            completion: @escaping ([String: Any]) -> Void
        ) {
            // Convert NSNumber? to Bool? for Swift compatibility
            let isOpenInBrowserAppleNumber: Bool? = isOpenInBrowserApple?.boolValue
            let isOpenInIosAppNumber: Bool? = isOpenInIosApp?.boolValue
            let isOpenInAndroidAppNumber: Bool? = isOpenInAndroidApp?.boolValue
            let isOpenInBrowserAndroidNumber: Bool? = isOpenInBrowserAndroid?.boolValue
            let attributionTtlNumber: Int? = attributionTtl?.intValue

            // Call the Swift-native function
            self.createAppLink(
                url: url,
                name: name,
                urlPrefix: urlPrefix,
                shortId: shortId,
                socialMeta: socialMeta,
                isOpenInBrowserApple: isOpenInBrowserAppleNumber,
                isOpenInIosApp: isOpenInIosAppNumber,
                iosFallbackUrl: iosFallbackUrl,
                isOpenInAndroidApp: isOpenInAndroidAppNumber,
                isOpenInBrowserAndroid: isOpenInBrowserAndroidNumber,
                androidFallbackUrl: androidFallbackUrl,
                appsFlyer: appsFlyer,
                attributionTtl: attributionTtlNumber,
                completion: completion
            )
        }

        /// Internal helper to create a dynamic AppLink. Used by both Swift and Objective-C wrappers.
        ///   - url: The deep link URL that the user should be direct.
        ///   - name: A human-readable name for the link, useful for display or analytics.
        ///   - urlPrefix: The domain prefix for the AppLink. **Do not include** `https://` or `http://`. Example: `example.page.link`.
        ///   - shortId: *(Optional)* A custom short ID to uniquely identify the link. If not provided, one will be generated automatically.
        ///   - socialMeta: *(Optional)* Dictionary containing metadata for social sharing (e.g., title, image URL, description).
        ///   - isOpenInBrowserApple: `Bool` indicating whether the link should open in a browser on iOS.
        ///   - isOpenInIosApp: `Bool` indicating whether the link should open directly in the iOS app.
        ///   - iosFallbackUrl: *(Optional)* Fallback URL used if the app is not installed on iOS.
        ///   - isOpenInAndroidApp: `Bool` indicating whether the link should open directly in the Android app.
        ///   - isOpenInBrowserAndroid: `Bool` indicating whether the link should open in a browser on Android.
        ///   - androidFallbackUrl: *(Optional)* Fallback URL used if the app is not installed on Android.
        ///   - appsFlyer: *(Optional)* Dictionary containing AppsFlyer attribution params (e.g., channel, campaignId, campaign, subs, metaTitle, metaDescription).
        ///   - attributionTtl: *(Optional)* Time-to-live, in seconds, for attribution of this link.
        ///   - completion: A closure that returns a dictionary containing the result of the link creation.
        public func createAppLink(
            url: String,
            name: String,
            urlPrefix: String,
            shortId: String? = nil,
            socialMeta: [String: Any]? = nil,
            isOpenInBrowserApple: Bool? = nil,
            isOpenInIosApp: Bool? = nil,
            iosFallbackUrl: String? = nil,
            isOpenInAndroidApp: Bool? = nil,
            isOpenInBrowserAndroid: Bool? = nil,
            androidFallbackUrl: String? = nil,
            appsFlyer: [String: Any]? = nil,
            attributionTtl: Int? = nil,
            completion: @escaping ([String: Any]) -> Void
        ) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if self.appsOnAirCoreServices.isNetworkConnected ?? false {

                    // Prepare URLs to validate
                    let urls = [
                        "url": url,
                        "iosFallbackUrl": iosFallbackUrl ?? "",
                        "androidFallbackUrl": androidFallbackUrl ?? "",
                        "imageUrl": (socialMeta?["imageUrl"] as? String) ?? "",
                    ]

                    // Validate URLs
                    if let invalidField = urls.first(where: {
                        !$0.value.trimmed.isEmpty && !$0.value.isValidHttpUrl
                    }) {
                        completion([errorStr: "\(errorURLInvalid) in \(invalidField.key) field!"])
                        return
                    }

                    // Construct cleaned social meta dictionary
                    let socialMetaData: [String: Any] =
                        (socialMeta ?? [:]).isEmpty
                        ? [:]
                        : [
                            "title": socialMeta?["title"] ?? NSNull(),
                            "description": socialMeta?["description"] ?? NSNull(),
                            "imageUrl": socialMeta?["imageUrl"] ?? NSNull(),
                        ]

                    AppLinkApiService.apiGenerateShortLink(
                        url: url, name: name, urlPrefix: urlPrefix, shortId: shortId,
                        socialMeta: socialMetaData, isOpenInBrowserApple: isOpenInBrowserApple,
                        isOpenInIosApp: isOpenInIosApp, iosFallbackUrl: iosFallbackUrl,
                        isOpenInAndroidApp: isOpenInAndroidApp,
                        isOpenInBrowserAndroid: isOpenInBrowserAndroid,
                        androidFallbackUrl: androidFallbackUrl,
                        appsFlyer: appsFlyer,
                        attributionTtl: attributionTtl
                    ) { shortLinkData in
                        completion(shortLinkData)
                    }
                } else {
                    Logger.logInfo(errorNetwork, prefix: appsOnAirLink)
                    completion([errorStr: errorNetwork])
                }
            }
        }

        //manage links form override methods
        internal func appLinkHandler(
            inComingURL: URL, completion: @escaping ([String: Any]) -> Void = { _ in }
        ) {
            self.latestLink = inComingURL
        }
    }
#endif
