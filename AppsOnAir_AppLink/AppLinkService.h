#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppLinkServices : NSObject

/// Shared singleton instance
+ (instancetype)shared;

/// Initialize AppLinkServices with deep link and referral link callbacks
- (void)initializeWithOnDeepLinkProcessed:(void (^)(NSURL * _Nullable url, NSDictionary *info))onDeepLinkProcessed
                 onReferralLinkDetected:(void (^)(NSDictionary *info))onReferralLinkDetected;

+ (void)initializeWithOnDeepLinkProcessed:(void (^)(NSURL * _Nullable url, NSDictionary *info))onDeepLinkProcessed
                  onReferralLinkDetected:(void (^)(NSDictionary *info))onReferralLinkDetected;

/// Handle an incoming App Link URL
+ (void)handleAppLinkWithURL:(NSURL *)incomingURL;
- (void)handleAppLinkWithURL:(NSURL *)incomingURL; // instance convenience

/// Get referral info
+ (void)getReferralInfoWithCompletion:(void (^)(NSDictionary *info))completion;
- (void)getReferralInfoWithCompletion:(void (^)(NSDictionary *info))completion;

/// Deprecated: Use `getReferralInfoWithCompletion:` instead
+ (void)getReferralDetailsWithCompletion:(void (^)(NSDictionary *info))completion
    __attribute__((deprecated("Use getReferralInfoWithCompletion instead")))
    __attribute__((swift_name("getReferralInfo(completion:)")));


/// Deprecated: Use `getReferralInfoWithCompletion:` instead
- (void)getReferralDetailsWithCompletion:(void (^)(NSDictionary *info))completion
    __attribute__((deprecated("Use getReferralInfoWithCompletion instead")))
    __attribute__((swift_name("getReferralInfo(completion:)")));


/// Create AppLink
+ (void)createAppLinkWithUrl:(NSString *)url
                        name:(NSString *)name
                   urlPrefix:(NSString *)urlPrefix
                     shortId:(nullable NSString *)shortId
                  socialMeta:(nullable NSDictionary<NSString *, id> *)socialMeta
        isOpenInBrowserApple:(nullable NSNumber *)isOpenInBrowserApple
              isOpenInIosApp:(nullable NSNumber *)isOpenInIosApp
              iosFallbackUrl:(nullable NSString *)iosFallbackUrl
          isOpenInAndroidApp:(nullable NSNumber *)isOpenInAndroidApp
      isOpenInBrowserAndroid:(nullable NSNumber *)isOpenInBrowserAndroid
          androidFallbackUrl:(nullable NSString *)androidFallbackUrl
                  completion:(void (^)(NSDictionary *result))completion;

- (void)createAppLinkWithUrl:(NSString *)url
                        name:(NSString *)name
                   urlPrefix:(NSString *)urlPrefix
                     shortId:(nullable NSString *)shortId
                  socialMeta:(nullable NSDictionary<NSString *, id> *)socialMeta
        isOpenInBrowserApple:(nullable NSNumber *)isOpenInBrowserApple
              isOpenInIosApp:(nullable NSNumber *)isOpenInIosApp
              iosFallbackUrl:(nullable NSString *)iosFallbackUrl
          isOpenInAndroidApp:(nullable NSNumber *)isOpenInAndroidApp
      isOpenInBrowserAndroid:(nullable NSNumber *)isOpenInBrowserAndroid
          androidFallbackUrl:(nullable NSString *)androidFallbackUrl
                  completion:(void (^)(NSDictionary *result))completion;

@end

NS_ASSUME_NONNULL_END
