#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppLinkService : NSObject

/// Shared singleton instance.
+ (instancetype)shared;

/// Set up the SDK and start tracking app links and referral events.
- (void)initializeOnDeepLinkProcessed:
            (void (^)(NSURL *_Nullable url,
                      NSDictionary *info))onDeepLinkProcessed
                onReferralLinkDetected:
                    (nullable void (^)(NSDictionary *referralInfo))
                        onReferralLinkDetected;

/// Handle incoming URLs, including custom scheme and universal links.
- (void)handleAppLinkWithIncomingURL:(NSURL *)url;

/// Get referral details.
- (void)getReferralInfoWithCompletion:(void (^)(NSDictionary *info))completion;

/// (Deprecated) Get referral details.
- (void)getReferralDetailsWithCompletion:(void (^)(NSDictionary *info))completion
    __attribute__((deprecated("Use getReferralInfoWithCompletion: instead")));

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
                  completion:(void (^)(NSDictionary *result))completion;

/// Handles app launch initiated from a cold start via a custom URL scheme.
- (void)handleLaunchOptions:(NSDictionary *)launchOptions;

/// Continues an NSUserActivity for Universal Links, including from a killed
/// state.
+ (void)continueUserActivity:(NSUserActivity *)userActivity;

@end

NS_ASSUME_NONNULL_END
