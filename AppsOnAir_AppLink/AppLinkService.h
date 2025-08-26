#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Pure Objective-C facade for AppsOnAir AppLink.
/// Safe to include from both .m and .mm files.
/// Note: Renamed to avoid clashing with Swift-exposed `AppLinkService` in the generated -Swift.h
@interface AppLinkServices : NSObject

/// Shared singleton facade instance
+ (instancetype)shared;

/// Initialize SDK
+ (void)initializeWithCompletion:(void (^)(NSURL * _Nullable url, NSDictionary *info))completion;
- (void)initializeWithCompletion:(void (^)(NSURL * _Nullable url, NSDictionary *info))completion;

/// Handle incoming link
+ (void)handleAppLinkWithURL:(NSURL *)incomingURL;
- (void)handleAppLinkWithURL:(NSURL *)incomingURL; // instance convenience

/// Get referral info
+ (void)getReferralDetailsWithCompletion:(void (^)(NSDictionary *info))completion;
- (void)getReferralDetailsWithCompletion:(void (^)(NSDictionary *info))completion;

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
