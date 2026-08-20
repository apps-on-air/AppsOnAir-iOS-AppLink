import Foundation

#if canImport(UIKit)
    import UIKit
    import WebKit
    import AppsOnAir_Core
    import ObjectiveC

    /// A unified helper class for managing app lifecycle events,
    /// referral handling, secure storage (Keychain), and user agent retrieval.
    internal class AppHelper: NSObject {

        // MARK: - Singleton Instance

        static let shared = AppHelper()

        // MARK: - UserDefaults Keys

        internal let userDefaults = UserDefaults.standard

        // MARK: - Cached Launch State Flags

        internal var isAppFirstOpen: Bool = false
        internal var isUserReferral: Bool = false

        /// `false` this session by default; flips to `true` only starting the next launch after a successful referral fetch.
        internal var isConsumed: Bool = false

        /// Resolved attribution status (organic/non-organic). Restored from UserDefaults on launch
        /// and re-persisted through `updateAttributionStatus(_:)` on every resolution, so launch 2+
        /// reports the value resolved on first launch without needing a referral fetch.
        internal private(set) var attributionStatus: String = attributionStatusOrganic

        /// Clipboard `applink_click_time`, in epoch milliseconds. Restored from UserDefaults on
        /// launch and re-persisted through `updateClickTime(_:)`, so it keeps reaching the
        /// attribution payload on later launches — the clipboard is only read once, on first open.
        /// `nil` until a deferred link carrying the param has been read.
        internal private(set) var clickTime: TimeInterval?

        /// SDK version reported in the `x-sdk-version` header.
        ///
        /// Read from this SDK's own resource bundle rather than relying on `SdkManager`'s bundle
        /// heuristics, which only recognise the CocoaPods bundle name — SwiftPM names its bundle
        /// `<Package>_<Target>.bundle`, so `Bundle.module` is the only dependable handle there.
        /// Note `Bundle(for:)` alone is not enough under CocoaPods: with static linking this class
        /// lives in the app binary, so that returns the *host app's* version.
        /// Falls back to `SdkManager` (which covers framework-based installs), then to "-".
        internal var sdkVersion: String {
            #if SWIFT_PACKAGE
                let resourceBundle: Bundle? = .module
            #else
                let hostBundle = Bundle(for: AppHelper.self)
                let resourceBundle =
                    hostBundle.url(forResource: appLinkResourceBundleName, withExtension: "bundle")
                    .flatMap { Bundle(url: $0) }
                    ?? Bundle.main.url(
                        forResource: appLinkResourceBundleName, withExtension: "bundle"
                    ).flatMap { Bundle(url: $0) }
            #endif

            // CocoaPods stamps the bundle's own Info.plist from s.version, so it cannot drift.
            if let version = resourceBundle?
                .object(forInfoDictionaryKey: shortVersionKey) as? String,
                !version.isEmpty
            {
                return version
            }

            // SwiftPM writes its own Info.plist with no version, so read the plist we ship inside
            // the bundle — the only version source on that path.
            if let plistURL = resourceBundle?.url(
                forResource: appLinkInfoPlistName, withExtension: "plist"),
                let data = try? Data(contentsOf: plistURL),
                let plist = try? PropertyListSerialization.propertyList(
                    from: data, options: [], format: nil) as? [String: Any],
                let version = plist[shortVersionKey] as? String,
                !version.isEmpty
            {
                return version
            }

            return SdkManager.shared.getVersion(for: appLinkSdkName)
        }

        /// Device's first install time, as epoch milliseconds.
        internal var firstInstallTime: Int64? {
            return getAppInstallationDateEpochMilliseconds()
        }

        // MARK: - Use Get User Agent
        /// A WKWebView instance used to retrieve the user agent.

        private var webView: WKWebView = WKWebView(frame: .zero)

        /// Set when backgrounding ends the first launch, and cleared by the `didBecomeActive` that
        /// follows. One-shot, so the attribution payload is re-delivered exactly once.
        private var firstLaunchExpired: Bool = false

        // MARK: - Initializer

        private override init() {
            super.init()
            handleAppLaunch()
            observeAppLifecycleNotifications()
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        // MARK: - App Lifecycle

        private func observeAppLifecycleNotifications() {
            // handleAppDidEnterBackground() -> Called when the app enters the background.
            // handleAppDidBecomeActive() -> Called on launch and when returning to the foreground.
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleAppDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleAppDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification, object: nil)
        }

        @objc private func handleAppDidEnterBackground() {
            Logger.logInternal(
                "AppHelper: didEnterBackground — isAppFirstOpen=\(isAppFirstOpen)")

            // Leaving the foreground ends the first launch, so `isFirstLaunch` turns false
            // without waiting for the process to restart.
            guard isAppFirstOpen else { return }
            isAppFirstOpen = false
            firstLaunchExpired = true
            Logger.logInternal(
                "AppHelper: isAppFirstOpen flipped to false, will notify on next didBecomeActive")
        }

        @objc private func handleAppDidBecomeActive() {
            Logger.logInternal(
                "AppHelper: didBecomeActive — firstLaunchExpired=\(firstLaunchExpired)"
            )
            // One-shot: only the activation that follows `isFirstLaunch` expiring posts. Later
            // returns to the foreground read the same persisted state, so they carry nothing new.
            guard firstLaunchExpired else { return }
            firstLaunchExpired = false
            Logger.logInternal(
                "AppHelper: posting appsOnAirFirstLaunchDidExpire")
            NotificationCenter.default.post(name: .appsOnAirFirstLaunchDidExpire, object: nil)
        }

        /// handle to get String from clipboard
        internal func readClipBoard() -> String? {
            if let string = UIPasteboard.general.string {
                Logger.logInternal("📋 Last clipboard string: \(string)")
                return string
            } else {
                Logger.logInternal("📋 Clipboard is empty or has no string")
                return nil
            }
        }

        /// Handles app launch states (first open, reopen, install)
        internal func handleAppLaunch() {
            isUserReferral = userDefaults.bool(forKey: isReferralKey)
            isAppFirstOpen = !userDefaults.bool(forKey: isFirstOpenKey)

            Logger.logInternal("isFirstOpen: \(isAppFirstOpen)")

            if isAppFirstOpen {
                userDefaults.set(true, forKey: isFirstOpenKey)
            }

            // isConsumed: use the cached value if it exists, otherwise create it with the default (false)
            if userDefaults.object(forKey: isConsumedKey) != nil {
                isConsumed = userDefaults.bool(forKey: isConsumedKey)
            } else {
                isConsumed = false
                userDefaults.set(false, forKey: isConsumedKey)
            }

            // attributionStatus: restore the last resolved value; organic only when nothing stored yet
            attributionStatus =
                userDefaults.string(forKey: attributionStatusStorageKey) ?? attributionStatusOrganic

            Logger.logInternal("attributionStatus restored: \(attributionStatus)")

            // clickTime: restore the stored value; 0 means nothing has been stored yet
            let storedClickTime = userDefaults.double(forKey: clickTimeStorageKey)
            clickTime = storedClickTime > 0 ? storedClickTime : nil

            Logger.logInternal("clickTime restored: \(String(describing: clickTime))")
        }

        /// Caches and persists a newly resolved attribution status so later launches report it.
        internal func updateAttributionStatus(_ status: String) {
            attributionStatus = status
            userDefaults.set(status, forKey: attributionStatusStorageKey)
        }

        /// Caches and persists the clipboard click time so later launches keep reporting it.
        internal func updateClickTime(_ value: TimeInterval) {
            clickTime = value
            userDefaults.set(value, forKey: clickTimeStorageKey)
        }

        // MARK: - Server Time Correction

        /// Parses the RFC 1123 form HTTP requires for `Date`. Static so the formatter is built once;
        /// `DateFormatter` is expensive and this runs on every API response.
        private static let httpDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "GMT")
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            return formatter
        }()

        /// `serverTime - deviceTime` at the last capture, in seconds. Zero until a response has
        /// been seen, which makes `correctedNow` fall back to the plain device clock.
        private var serverTimeOffset: TimeInterval {
            get { userDefaults.double(forKey: serverTimeOffsetStorageKey) }
            set { userDefaults.set(newValue, forKey: serverTimeOffsetStorageKey) }
        }

        /// The newest corrected time ever observed. Real time only moves forward, so a corrected
        /// now behind this mark means the clock was wound back between two observations.
        private var serverTimeHighWater: TimeInterval {
            get { userDefaults.double(forKey: serverTimeHighWaterStorageKey) }
            set { userDefaults.set(newValue, forKey: serverTimeHighWaterStorageKey) }
        }

        /// The device clock corrected by the last known server offset.
        internal var correctedNow: TimeInterval {
            Date().timeIntervalSince1970 + serverTimeOffset
        }

        /// True when corrected time has moved behind the newest time already observed.
        internal var hasClockRewound: Bool {
            let highWater = serverTimeHighWater
            return highWater > 0 && correctedNow < highWater
        }

        /// Advances the high-water mark. Never moves it backwards.
        internal func observeCorrectedTime(_ corrected: TimeInterval) {
            if corrected > serverTimeHighWater {
                serverTimeHighWater = corrected
            }
        }

        /// Records the server clock from a response `Date` header. Called for every API response,
        /// so an absent or malformed header is ignored rather than logged loudly.
        internal func recordServerDate(_ header: String?) {
            guard let header,
                let serverDate = AppHelper.httpDateFormatter.date(from: header)
            else { return }

            let serverSeconds = serverDate.timeIntervalSince1970
            serverTimeOffset = serverSeconds - Date().timeIntervalSince1970
            observeCorrectedTime(serverSeconds)
        }

        /// Fetches the app's first install date from the Documents directory's creation date,
        internal func getAppInstallationDateValue() -> Date? {
            guard
                let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                    .first?.path
            else {
                return nil
            }

            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: docPath)
                return attributes[.creationDate] as? Date
            } catch {
                return nil
            }
        }

        /// App install date in epoch milliseconds, matching the Android SDK's unit.
        internal func getAppInstallationDateEpochMilliseconds() -> Int64? {
            guard let installDate = getAppInstallationDateValue() else { return nil }

            let milliseconds = Measurement(
                value: installDate.timeIntervalSince1970, unit: UnitDuration.seconds
            ).converted(to: .milliseconds).value

            return Int64(milliseconds.rounded())
        }

        // MARK: - Keychain Handling

        //handle for save data into keychain
        internal func saveToKeychain(key: String, value: [String: Any]) {
            guard let data = try? JSONSerialization.data(withJSONObject: value) else {
                return
            }

            let query =
                [kSecClass: kSecClassGenericPassword, kSecAttrAccount: key] as [CFString: Any]
            let attrs = [kSecValueData: data]

            switch SecItemUpdate(query as CFDictionary, attrs as CFDictionary) {
            case errSecSuccess:
                Logger.logInternal("\(updated): \(key)")
            case errSecItemNotFound:
                SecItemAdd(query.merging(attrs) { $1 } as CFDictionary, nil)
                Logger.logInternal("\(added): \(key)")
            default:
                Logger.logInternal("\(errorFailedSaveKey): \(key)")
            }
        }

        //handle for read data into keychain
        internal func readFromKeychain(key: String) -> [String: Any]? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecReturnData as String: kCFBooleanTrue!,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]

            var item: CFTypeRef?
            if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
                let data = item as? Data
            {
                do {
                    if let dict = try JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any]
                    {
                        return dict
                    }
                } catch {
                    Logger.logInternal(
                        "\(errorFailedToDecodeKeychain) \(error.localizedDescription)")
                }
            }

            return nil
        }

        //handle for delete data from keychain
        internal func removeDataFromKeychain(key: String) -> Any {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
            ]
            let status = SecItemDelete(query as CFDictionary)
            if status == errSecSuccess {
                return true
            } else {
                return false
            }
        }

        // MARK: - User Agent Handling

        internal func getUserAgent(completion: @escaping (String?) -> Void) {
            DispatchQueue.main.async {
                self.webView.evaluateJavaScript("window.navigator.userAgent;") { result, error in
                    if let error = error {
                        completion("\(errorUserAgent): \(error.localizedDescription)")
                    } else if let userAgent = result as? String {
                        self.webView.customUserAgent = userAgent
                        completion(userAgent)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }

    extension String {

        /// Checks if the string is a valid http/https URL
        var isValidHttpUrl: Bool {
            guard self.hasPrefix("http://") || self.hasPrefix("https://") else {
                return false
            }
            return true
        }

        /// Returns trimmed version of string
        var trimmed: String {
            return trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
#endif
