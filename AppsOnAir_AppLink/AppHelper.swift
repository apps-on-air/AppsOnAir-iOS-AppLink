import UIKit
import Foundation
import WebKit
import ObjectiveC
import AppsOnAir_Core

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
    
    // MARK: - Use Get User Agent
    /// A WKWebView instance used to retrieve the user agent.

    private var webView: WKWebView = WKWebView(frame: .zero)
    
    // MARK: - Initializer
    
    private override init() {
        super.init()
        handleAppLaunch()
    }
    
    // MARK: - App Lifecycle
    
    /// Handles app launch states (first open, reopen, install)
    internal func handleAppLaunch() {
        isUserReferral = userDefaults.bool(forKey: isReferralKey)
        isAppFirstOpen = !userDefaults.bool(forKey: isFirstOpenKey)

        Logger.logInternal("isFirstOpen: \(isAppFirstOpen)")

        if isAppFirstOpen {
            userDefaults.set(true, forKey: isFirstOpenKey)
        }
    }
    
    // MARK: - Keychain Handling
    
    //handle for save data into keychain
    internal func saveToKeychain(key: String, value: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: value) else {
            return
        }

        let query = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: key] as [CFString: Any]
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
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
           let data = item as? Data {
            do {
                if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    return dict
                }
            } catch {
                Logger.logInternal("\(errorFailedToDecodeKeychain) \(error.localizedDescription)")
            }
        }
        
        return nil
    }
    
    //handle for delete data from keychain
    internal func removeDataFromKeychain(key: String) -> Any {
           let query: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: key
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

internal extension String {

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
