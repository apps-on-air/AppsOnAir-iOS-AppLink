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

+ (void)initializeWithCompletion:(void (^)(NSURL * _Nullable url, NSDictionary *info))completion {
    [[AppLinkService shared] initializeWithCompletion:^(NSURL *url, NSDictionary<NSString *,id> *linkInfo) {
        completion(url, linkInfo);
    }];
}

- (void)initializeWithCompletion:(void (^)(NSURL * _Nullable url, NSDictionary *info))completion {
    [[AppLinkService shared] initializeWithCompletion:^(NSURL *url, NSDictionary<NSString *,id> *linkInfo) {
        completion(url, linkInfo);
    }];
}

+ (void)handleAppLinkWithURL:(NSURL *)incomingURL {
    [[AppLinkService shared] handleAppLinkWithIncomingURL:incomingURL];
}

- (void)handleAppLinkWithURL:(NSURL *)incomingURL {
    [[AppLinkService shared] handleAppLinkWithIncomingURL:incomingURL];
}

+ (void)getReferralDetailsWithCompletion:(void (^)(NSDictionary *info))completion {
    [[AppLinkService shared] getReferralDetailsWithCompletion:^(NSDictionary<NSString *,id> *linkInfo) {
        completion(linkInfo);
    }];
}

- (void)getReferralDetailsWithCompletion:(void (^)(NSDictionary *info))completion {
   [[AppLinkService shared] getReferralDetailsWithCompletion:^(NSDictionary<NSString *,id> *linkInfo) {
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
