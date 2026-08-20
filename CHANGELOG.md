## 2.0.0

* `getReferralInfo()` is now deprecated, use `getAttributionInfo()` instead.

* Introduced `getAttributionInfo()` method.
    * Returns the same data as `getReferralInfo()` with additional `isFirstLaunch`, `firstInstallTime`, `isConsumed` and `attributionStatus` fields included in the response.

* Introduced `onAttributionListener()` listener.
    * When an attribution is detected, and again every time the app returns to the foreground so the payload stays current.

* Added `appsFlyer` and `attributionTtl` params to `AppLinkParams` for AppsFlyer attribution support in `createAppLink` method.

**Deprecated:**

* `onReferralLinkDetected()` — use `onAttributionListener()`.
* `getReferralInfo()` and `getReferralDetails()` — use `getAttributionInfo()`.

## 1.4.1

* Minor fixes and improvements

## 1.4.0

* Added support for Swift Package Manager (SPM).

## 1.3.2

* Referral tracking enhancement.

## 1.3.1

* Upgrade dependency

## 1.3.0

* Upgrade dependency

## 1.2.0

* `getReferralDetails()` method is now deprecated use `getReferralInfo()` instead.
* Introduced `onReferralLinkDetected()` in `initialize` method.
    * This callback is optional.
    * It is triggered only when the app is installed and launched for the first time with a referral details.
    
## 1.1.2

* Add Objective-C++ support
* Minor fixes and improvements

## 1.1.1

* Upgrade dependency
* Minor fixes and improvements

## 1.1.0

**Breaking Changes:**

* Changed parameter `iOSFallbackUrl` to `iosFallbackUrl` in the `createAppLink` method.
* Bugs fixes and improvements

## 1.0.0

* Initial stable release.

## 0.0.6 (Beta)

* Updated AppLink link creation data validation

## 0.0.5 (Beta)

* Minor fixes and improvements

## 0.0.4 (Beta)

* Minor fixes and improvements

## 0.0.3 (Beta)

* Add URL validation and error handling for short link generation

## 0.0.2 (Beta)

* Added referral link support

## 0.0.1 (Beta)

* Initial Release