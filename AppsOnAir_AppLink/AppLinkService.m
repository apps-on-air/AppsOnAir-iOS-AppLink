#import "AppLinkService.h"

// Conditional import for different project types
#if __has_include("AppsOnAir_AppLink-Swift.h")
    #import "AppsOnAir_AppLink-Swift.h"
#elif __has_include("AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h")
    #import "AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h"
#elif __has_include(<AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h>)
    #import <AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h>
#else
    #error "Swift bridging header not found. Please check your project configuration."
#endif

@implementation AppLinkServices

+ (instancetype)shared {
    static AppLinkServices *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}


- (void)initializeWithOnDeepLinkProcessed:(nonnull void (^)(NSURL * _Nullable __strong, NSDictionary * _Nonnull __strong))onDeepLinkProcessed onReferralLinkDetected:(nonnull void (^)(NSDictionary * _Nonnull __strong))onReferralLinkDetected{
    [[AppLinkService shared] initializeOnDeepLinkProcessed:onDeepLinkProcessed onReferralLinkDetected:onReferralLinkDetected];
}

+ (void)initializeWithOnDeepLinkProcessed:(nonnull void (^)(NSURL * _Nullable __strong, NSDictionary * _Nonnull __strong))onDeepLinkProcessed onReferralLinkDetected:(nonnull void (^)(NSDictionary * _Nonnull __strong))onReferralLinkDetected{
    [[AppLinkService shared] initializeOnDeepLinkProcessed:onDeepLinkProcessed onReferralLinkDetected:onReferralLinkDetected];
}

+ (void)handleAppLinkWithURL:(NSURL *)incomingURL {
    [[AppLinkService shared] handleAppLinkWithIncomingURL:incomingURL];
}

- (void)handleAppLinkWithURL:(NSURL *)incomingURL {
    [[AppLinkService shared] handleAppLinkWithIncomingURL:incomingURL];
}


+ (void)getReferralDetailsWithCompletion:(void (^)(NSDictionary *info))completion {
    // Deprecated — forward to new API
    [self getReferralInfoWithCompletion:completion];
}

- (void)getReferralDetailsWithCompletion:(void (^)(NSDictionary *info))completion {
    // Deprecated — forward to new API
    [self getReferralInfoWithCompletion:completion];
}

+ (void)getReferralInfoWithCompletion:(void (^)(NSDictionary *info))completion {
    [[AppLinkService shared] getReferralInfoWithCompletion:^(NSDictionary<NSString *,id> * _Nonnull linkInfo) {
        completion(linkInfo);
    }];
}

- (void)getReferralInfoWithCompletion:(void (^)(NSDictionary *info))completion {
    [[AppLinkService shared] getReferralInfoWithCompletion:^(NSDictionary<NSString *,id> * _Nonnull linkInfo) {
        completion(linkInfo);
    }];
}

+ (void)createAppLinkWithUrl:(NSString *)url
                        name:(NSString *)name
                   urlPrefix:(NSString *)urlPrefix
                     shortId:(NSString * _Nullable)shortId
                  socialMeta:(NSDictionary<NSString *, id> * _Nullable)socialMeta
        isOpenInBrowserApple:(NSNumber * _Nullable)isOpenInBrowserApple
              isOpenInIosApp:(NSNumber * _Nullable)isOpenInIosApp
              iosFallbackUrl:(NSString * _Nullable)iosFallbackUrl
          isOpenInAndroidApp:(NSNumber * _Nullable)isOpenInAndroidApp
      isOpenInBrowserAndroid:(NSNumber * _Nullable)isOpenInBrowserAndroid
          androidFallbackUrl:(NSString * _Nullable)androidFallbackUrl
                  completion:(void (^)(NSDictionary *result))completion {
    
    [[AppLinkService shared] createAppLinkWithUrl:url
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
                                       completion:^(NSDictionary<NSString *,id> *linkInfo) {
                                           completion(linkInfo);
                                       }];
}

- (void)createAppLinkWithUrl:(NSString *)url
                        name:(NSString *)name
                   urlPrefix:(NSString *)urlPrefix
                     shortId:(NSString * _Nullable)shortId
                  socialMeta:(NSDictionary<NSString *, id> * _Nullable)socialMeta
        isOpenInBrowserApple:(NSNumber * _Nullable)isOpenInBrowserApple
              isOpenInIosApp:(NSNumber * _Nullable)isOpenInIosApp
              iosFallbackUrl:(NSString * _Nullable)iosFallbackUrl
          isOpenInAndroidApp:(NSNumber * _Nullable)isOpenInAndroidApp
      isOpenInBrowserAndroid:(NSNumber * _Nullable)isOpenInBrowserAndroid
          androidFallbackUrl:(NSString * _Nullable)androidFallbackUrl
                  completion:(void (^)(NSDictionary *result))completion {
    
    [[AppLinkService shared] createAppLinkWithUrl:url
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
                                       completion:^(NSDictionary<NSString *,id> *linkInfo) {
                                           completion(linkInfo);
                                       }];
}

@end
