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

let isFirstOpenKey = "isFirstOpen"

let isReferralKey = "isUserReferral"

let EnableAdvancedDeferredLinkKey = "EnableAdvancedDeferredLink"

let isConsumedKey = "isConsumed"

let isFirstLaunchKey = "isFirstLaunch"

let firstInstallTimeKey = "firstInstallTime"

let attributionStatusKey = "attributionStatus"

let attributionTtlResponseKey = "attributionTtl"

let applinkClickTimeParam = "applink_click_time"

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
