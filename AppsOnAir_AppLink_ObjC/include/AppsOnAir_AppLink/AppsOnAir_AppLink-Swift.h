#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppLinkService : NSObject

/// Shared singleton instance.
+ (instancetype)shared;

/// Set up the SDK and start tracking app links and referral events.
/// `onAttributionListener` fires at most twice: when a referral fetch actually
/// runs (first open, or no referral cached yet), then once more on the return to
/// the foreground that follows `isFirstLaunch` turning `NO`, re-delivering the
/// persisted payload without refetching. Later foreground returns are silent.
/// `isFirstLaunch`, `firstInstallTime`, `isConsumed`, and `attributionStatus`
/// are included in its payload.
- (void)initializeOnDeepLinkProcessed:
            (void (^)(NSURL *_Nullable url,
                      NSDictionary *info))onDeepLinkProcessed
                onAttributionListener:
                    (nullable void (^)(NSDictionary *attributionInfo))
                        onAttributionListener;

/// (Deprecated) Use `initializeOnDeepLinkProcessed:onAttributionListener:`
/// instead. Receives just the raw referral dictionary — the deprecated
/// replacement also includes `isFirstLaunch`, `firstInstallTime`,
/// `isConsumed`, and `attributionStatus`.
- (void)initializeOnDeepLinkProcessed:
            (void (^)(NSURL *_Nullable url,
                      NSDictionary *info))onDeepLinkProcessed
               onReferralLinkDetected:
                   (nullable void (^)(NSDictionary *referralInfo))
                       onReferralLinkDetected
    __attribute__((
        deprecated("onReferralLinkDetected is deprecated and will be removed "
                   "in a future release. Use onAttributionListener instead.")));

/// Handle incoming URLs, including custom scheme and universal links.
- (void)handleAppLinkWithIncomingURL:(NSURL *)url;

/// (Deprecated) Get referral info.
- (void)getReferralInfoWithCompletion:(void (^)(NSDictionary *info))completion
    __attribute__((
        deprecated("Use getAttributionInfoWithCompletion: instead")));

/// (Deprecated) Get referral details.
- (void)getReferralDetailsWithCompletion:
    (void (^)(NSDictionary *info))completion __attribute__((
        deprecated("Use getAttributionInfoWithCompletion: instead")));

/// Get referral and attribution info. Same as the deprecated `getReferralInfo`,
/// with `isFirstLaunch`, `firstInstallTime`, `isConsumed`, and
/// `attributionStatus` ("organic"/"non-organic") included in the response —
/// the last resolved status, restored from storage on later launches.
- (void)getAttributionInfoWithCompletion:
    (void (^)(NSDictionary *info))completion;

/// Create a new AppLink.
- (void)createAppLinkWithUrl:(NSString *)url
                        name:(NSString *)name
                   urlPrefix:(NSString *)urlPrefix
                     shortId:(nullable NSString *)shortId
                  socialMeta:(nullable NSDictionary *)socialMeta
        isOpenInBrowserApple:(nullable NSNumber *)isOpenInBrowserApple
              isOpenInIosApp:(nullable NSNumber *)isOpenInIosApp
              iosFallbackUrl:(nullable NSString *)iosFallbackUrl
          isOpenInAndroidApp:(nullable NSNumber *)isOpenInAndroidApp
      isOpenInBrowserAndroid:(nullable NSNumber *)isOpenInBrowserAndroid
          androidFallbackUrl:(nullable NSString *)androidFallbackUrl
                   appsFlyer:(nullable NSDictionary *)appsFlyer
              attributionTtl:(nullable NSNumber *)attributionTtl
                  completion:(void (^)(NSDictionary *result))completion;

/// Handles app launch initiated from a cold start via a custom URL scheme.
- (void)handleLaunchOptions:(NSDictionary *)launchOptions;

/// Continues an NSUserActivity for Universal Links, including from a killed
/// state.
+ (void)continueUserActivity:(NSUserActivity *)userActivity;

@end

NS_ASSUME_NONNULL_END
