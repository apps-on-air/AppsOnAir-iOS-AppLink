#import "AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h"

@interface AppLinkWrapper : NSObject
+ (void)initializeWithOnDeepLinkProcessed:
            (void (^)(NSURL *_Nullable, NSDictionary *))onDeepLinkProcessed
                    onAttributionListener:
                        (nullable void (^)(NSDictionary *))onAttributionListener;
+ (void)initializeWithOnDeepLinkProcessed:
            (void (^)(NSURL *_Nullable, NSDictionary *))onDeepLinkProcessed
                   onReferralLinkDetected:
                       (nullable void (^)(NSDictionary *))onReferralLinkDetected;
+ (void)handleAppLinkWithURL:(NSURL *)url;
+ (void)getReferralInfoWithCompletion:(void (^)(NSDictionary *))completion;
+ (void)getReferralDetailsWithCompletion:(void (^)(NSDictionary *))completion;
+ (void)getAttributionInfoWithCompletion:(void (^)(NSDictionary *))completion;
+ (void)createAppLinkWithUrl:(NSString *)url
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
                  completion:(void (^)(NSDictionary *))completion;
+ (void)handleLaunchOptions:(NSDictionary *)launchOptions;
+ (void)continueUserActivity:(NSUserActivity *)userActivity;
@end

@implementation AppLinkService

+ (instancetype)shared {
  static AppLinkService *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

+ (void)initializeOnDeepLinkProcessed:
            (void (^)(NSURL *_Nullable, NSDictionary *))onDeepLinkProcessed
                onAttributionListener:(nullable void (^)(NSDictionary *))
                                          onAttributionListener {
  [AppLinkWrapper initializeWithOnDeepLinkProcessed:onDeepLinkProcessed
                              onAttributionListener:onAttributionListener];
}

- (void)initializeOnDeepLinkProcessed:
            (void (^)(NSURL *_Nullable, NSDictionary *))onDeepLinkProcessed
                onAttributionListener:(nullable void (^)(NSDictionary *))
                                          onAttributionListener {
  [AppLinkWrapper initializeWithOnDeepLinkProcessed:onDeepLinkProcessed
                              onAttributionListener:onAttributionListener];
}

+ (void)initializeOnDeepLinkProcessed:
            (void (^)(NSURL *_Nullable, NSDictionary *))onDeepLinkProcessed
                onReferralLinkDetected:(nullable void (^)(NSDictionary *))
                                           onReferralLinkDetected {
  [AppLinkWrapper initializeWithOnDeepLinkProcessed:onDeepLinkProcessed
                             onReferralLinkDetected:onReferralLinkDetected];
}

- (void)initializeOnDeepLinkProcessed:
            (void (^)(NSURL *_Nullable, NSDictionary *))onDeepLinkProcessed
                onReferralLinkDetected:(nullable void (^)(NSDictionary *))
                                           onReferralLinkDetected {
  [AppLinkWrapper initializeWithOnDeepLinkProcessed:onDeepLinkProcessed
                             onReferralLinkDetected:onReferralLinkDetected];
}

+ (void)handleAppLinkWithIncomingURL:(NSURL *)url {
  [AppLinkWrapper handleAppLinkWithURL:url];
}

- (void)handleAppLinkWithIncomingURL:(NSURL *)url {
  [AppLinkWrapper handleAppLinkWithURL:url];
}

+ (void)getReferralInfoWithCompletion:(void (^)(NSDictionary *))completion {
  [AppLinkWrapper getReferralInfoWithCompletion:completion];
}

- (void)getReferralInfoWithCompletion:(void (^)(NSDictionary *))completion {
  [AppLinkWrapper getReferralInfoWithCompletion:completion];
}

+ (void)getReferralDetailsWithCompletion:(void (^)(NSDictionary *))completion {
  [AppLinkWrapper getReferralDetailsWithCompletion:completion];
}

- (void)getReferralDetailsWithCompletion:(void (^)(NSDictionary *))completion {
  [AppLinkWrapper getReferralDetailsWithCompletion:completion];
}

+ (void)getAttributionInfoWithCompletion:(void (^)(NSDictionary *))completion {
  [AppLinkWrapper getAttributionInfoWithCompletion:completion];
}

- (void)getAttributionInfoWithCompletion:(void (^)(NSDictionary *))completion {
  [AppLinkWrapper getAttributionInfoWithCompletion:completion];
}

+ (void)createAppLinkWithUrl:(NSString *)url
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
                  completion:(void (^)(NSDictionary *))completion {
  [AppLinkWrapper createAppLinkWithUrl:url
                                  name:name
                             urlPrefix:urlPrefix
                               shortId:shortId
                            socialMeta:socialMeta
                  isOpenInBrowserApple:isOpenInBrowserApple
                        isOpenInIosApp:isOpenInIosApp
                        iosFallbackUrl:iosFallbackUrl
                    isOpenInAndroidApp:isOpenInAndroidApp
                isOpenInBrowserAndroid:isOpenInBrowserAndroid
                    androidFallbackUrl:androidFallbackUrl
                             appsFlyer:appsFlyer
                       attributionTtl:attributionTtl
                            completion:completion];
}

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
                  completion:(void (^)(NSDictionary *))completion {
  [AppLinkService createAppLinkWithUrl:url
                                  name:name
                             urlPrefix:urlPrefix
                               shortId:shortId
                            socialMeta:socialMeta
                  isOpenInBrowserApple:isOpenInBrowserApple
                        isOpenInIosApp:isOpenInIosApp
                        iosFallbackUrl:iosFallbackUrl
                    isOpenInAndroidApp:isOpenInAndroidApp
                isOpenInBrowserAndroid:isOpenInBrowserAndroid
                    androidFallbackUrl:androidFallbackUrl
                             appsFlyer:appsFlyer
                       attributionTtl:attributionTtl
                            completion:completion];
}

+ (void)handleLaunchOptions:(NSDictionary *)launchOptions {
  [AppLinkService handleLaunchOptions:launchOptions];
}

- (void)handleLaunchOptions:(NSDictionary *)launchOptions {
  [AppLinkService handleLaunchOptions:launchOptions];
}

+ (void)continueUserActivity:(NSUserActivity *)userActivity {
  [AppLinkService continueUserActivity:userActivity];
}

- (void)continueUserActivity:(NSUserActivity *)userActivity {
  [AppLinkService continueUserActivity:userActivity];
}

@end
