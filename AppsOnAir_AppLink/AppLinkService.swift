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

        //Latest link for Dynamic Link
        @Published var latestLink: URL?

        //Latest link for Referral Link
        @Published var latestReferralURL: URL?

        // Listener for whenever link is Update
        private var linkListener: AnyCancellable?

        private var latestReferralInfo: [String: Any]?

        // Listener for whenever referral link is Update
        private var referralLinkListener: AnyCancellable?

        // Manage for API call
        private let dispatchGroup = DispatchGroup()

        deinit {
            // Cancel the listener when the object is deallocated
            linkListener?.cancel()
            referralLinkListener?.cancel()
        }

        //initialize the common services like AppsOnAir-Core and swizzling method and fetch the latest Link
        ///fetch the latest link for universal link and custom URL schema
        ///fetch the latest link for referral link and
        @objc public func initialize(
            onDeepLinkProcessed: @escaping (URL?, [String: Any]) -> Void,
            onReferralLinkDetected: (([String: Any]) -> Void)? = nil
        ) {

            //initialize the AppsOnAir-core
            appsOnAirCoreServices.initialize()

            // Initialize swizzling
            _ = AppSwizzler.shared

            // handle the internet connectivity abd listen for network status changes
            appsOnAirCoreServices.networkStatusListenerHandler { isConnected in
                guard self.linkListener == nil else { return }
                // Listener for link and link info
                self.linkListener = self.$latestLink.sink { [weak self] _ in
                    self?.onAppLinkHandler(isNetworkConnected: isConnected) { url, linkInfo in
                        onDeepLinkProcessed(url, linkInfo)
                    }
                }
                self.referralLinkListener = self.$latestReferralURL
                    .dropFirst()
                    .sink { _ in
                        self.referralHandler(isCompletionCall: true) { referralInfoFromKeyChain in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                onReferralLinkDetected?(referralInfoFromKeyChain)
                            }
                        }
                    }
            }

            // help to referral handling
            referralHandler(isAPICall: true)
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

                        var appLinkReferralLinkParams: [String: Any] = [:]
                        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                            let hashKey = components.queryItems?.first(where: {
                                $0.name == "hash_key"
                            }
                            )?.value
                        {
                            Logger.logInternal("Hash Key: \(hashKey)")
                            appLinkReferralLinkParams["data"] = ["hashKey": hashKey]
                        }

                        AppLinkApiService.apiReferralInfo(
                            appLinParams: appLinkReferralLinkParams,
                            isEnableAdvancedDeferredLink: true
                        ) { linkInfo in
                            let _ = self.appHelper.removeDataFromKeychain(key: referralData)

                            self.latestReferralInfo = linkInfo

                            self.appHelper.saveToKeychain(key: referralData, value: linkInfo)

                            self.latestReferralInfo = linkInfo
                            self.latestReferralURL = url

                            if let referralStatus = linkInfo["status"] as? String,
                                referralStatus == "SUCCESS"
                            {
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
                                        Logger.logInternal("Referral SuccessFully")
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
                        AppLinkApiService.apiReferralInfo { referralLinkInfo in
                            let _ = self.appHelper.removeDataFromKeychain(key: referralData)

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

        @objc public func getReferralInfo(completion: @escaping ([String: Any]) -> Void) {
            dispatchGroup.notify(queue: .main) {
                if !((self.latestReferralInfo ?? [:]).isEmpty) {
                    completion(self.latestReferralInfo ?? [:])
                    return
                }
                let referralInfoFromKeyChain = self.appHelper.readFromKeychain(key: referralData)
                completion(referralInfoFromKeyChain ?? [:])
            }
        }

        ///help to handle the get link for referral info
        @available(*, deprecated, renamed: "getReferralInfo")
        @objc public func getReferralDetails(completion: @escaping ([String: Any]) -> Void) {
            // Retrieve stored data from the device keychain
            let referralInfoFromKeyChain = appHelper.readFromKeychain(key: referralData)
            completion(referralInfoFromKeyChain ?? [:])
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
            completion: @escaping ([String: Any]) -> Void
        ) {
            // Convert NSNumber? to Bool? for Swift compatibility
            let isOpenInBrowserAppleNumber: Bool? = isOpenInBrowserApple?.boolValue
            let isOpenInIosAppNumber: Bool? = isOpenInIosApp?.boolValue
            let isOpenInAndroidAppNumber: Bool? = isOpenInAndroidApp?.boolValue
            let isOpenInBrowserAndroidNumber: Bool? = isOpenInBrowserAndroid?.boolValue

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
                        androidFallbackUrl: androidFallbackUrl
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
