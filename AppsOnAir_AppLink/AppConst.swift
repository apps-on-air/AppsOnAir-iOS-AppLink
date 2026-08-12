import Foundation

//MARK: - User Info Messages

let appsOnAirLink = "AppsOnAir-Link"

//MARK: - Internal Logs Messages

let referralData = "appsOnAirReferralData"

let errorSomeThingWrong = "Something went wrong please try again!"

let errorStr = "error"

let referralSuccessFully = "Referral SuccessFully"

let clipboardEmpty = "Clipboard is empty"

let invalidBundleIdentifier = "Invalid bundle identifier"

let enableAdvancedDeferredLinkDisabled =
    "EnableAdvancedDeferredLink is disabled/does not exist in Info.plist"

let notFoundBundle = "not found or missing bundle identifier"

let foundAppsOnAirKey = "Found value containing appsonairKey"

let errorUserAgent = "getUserAgentError"

let errorFailedSaveKey = "Failed to save key"

let errorAppIdMissing = "App id missing!"

let errorShortIdMissing = "Short id missing!"

let errorFailedToLoad = "Failed to load:"

let errorNetwork = "Please check internet connection!"

let errorURLInvalid = "Enter a valid URL"

let errorFailedToDecodeKeychain = "Failed to decode JSON from Keychain"

let errorResponse = "Invalid response type"

let contentType = "Content-Type"

let userAgent = "User-Agent"

let updated = "Updated"

let added = "Added"

let responseJson = "Response JSON:"

let url = "URL"

let xApplicationId = "x-application-key"

/// Sent on every API request so the backend can attribute behaviour to an SDK release.
let xSdkVersion = "x-sdk-version"

/// Pod name handed to `SdkManager.getVersion(for:)`, used only as a fallback.
let appLinkSdkName = "AppsOnAir-AppLink"

/// Name of the resource bundle CocoaPods builds from `s.resource_bundles`. Its
/// `CFBundleShortVersionString` is the version reported in `x-sdk-version`, so
/// `Resources/AppsOnAir-AppLinkInfo.plist` must stay in step with `s.version` in the podspec.
/// SwiftPM names its bundle `<Package>_<Target>.bundle` instead, which is why it is reached
/// through `Bundle.module` rather than by name.
let appLinkResourceBundleName = "AppsOnAir_AppLink"

/// The plist shipped inside that bundle. SwiftPM writes its own `Info.plist` without a version, so
/// this file is the only version source under SPM and must track `s.version` in the podspec.
/// Under CocoaPods the bundle's own `Info.plist` is stamped from `s.version` and wins.
let appLinkInfoPlistName = "AppsOnAir-AppLinkInfo"

let shortVersionKey = "CFBundleShortVersionString"

let isFirstOpenKey = "isFirstOpen"

let isReferralKey = "isUserReferral"

let EnableAdvancedDeferredLinkKey = "EnableAdvancedDeferredLink"

let isConsumedKey = "isConsumed"

let isFirstLaunchKey = "isFirstLaunch"

let firstInstallTimeKey = "firstInstallTime"

let attributionStatusKey = "attributionStatus"

/// UserDefaults key for the persisted attribution status. Distinct from `attributionStatusKey`,
/// which names the field inside the response payload; matches the Android SDK's stored key.
let attributionStatusStorageKey = "attribution_status"

let attributionTtlResponseKey = "attributionTtl"

let applinkClickTimeParam = "applink_click_time"

/// UserDefaults key for the persisted clipboard click time. Distinct from `applinkClickTimeParam`,
/// which names both the clipboard query item and the field inside the response payload;
/// matches the Android SDK's stored key.
let clickTimeStorageKey = "click_time"

/// Response field carrying the AppsFlyer attribution object. Exposed only through the newer
/// attribution surface, so it is stripped from the deprecated referral payloads.
let appsFlyerKey = "appsFlyer"

let attributionStatusOrganic = "organic"

let attributionStatusNonOrganic = "non-organic"

let statusCodeKey = "statusCode"

let successStatusCode = 200

let dataKey = "data"

//MARK: - Internal Notifications

extension Notification.Name {
    /// Posted when the app returns to foreground after having been genuinely backgrounded
    /// (not the initial cold-start activation), and `isFirstLaunch` flips from `true` to `false`.
    static let appsOnAirFirstLaunchDidExpire = Notification.Name(
        "AppsOnAirAppLink.firstLaunchDidExpire")
}
