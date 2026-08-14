## [![pub package](https://appsonair.com/images/logo.svg)](https://cocoapods.org/pods/AppsOnAir-AppLink)
# AppsOnAir-AppLink

[![CI Status](https://img.shields.io/travis/164989979/AppsOnAir-AppLink.svg?style=flat)](https://travis-ci.org/164989979/AppsOnAir-AppLink)
[![Version](https://img.shields.io/cocoapods/v/AppsOnAir-AppLink.svg?style=flat)](https://cocoapods.org/pods/AppsOnAir-AppLink)
[![License](https://img.shields.io/cocoapods/l/AppsOnAir-AppLink.svg?style=flat)](https://cocoapods.org/pods/AppsOnAir-AppLink)
[![Platform](https://img.shields.io/cocoapods/p/AppsOnAir-AppLink.svg?style=flat)](https://cocoapods.org/pods/AppsOnAir-AppLink)

## Overview

**AppsOnAir-AppLink** enables you to handle deep links, and in-app routing seamlessly in your IOS app. With a simple integration, you can configure, manage, and act on links from the web dashboard in real time.

## 🚀 Features

- ✅ Deep link support (URI scheme, AppLinks)
- ✅ Fallback behavior (e.g., open App Store)
- ✅ Custom domain support
- ✅ Referral tracking
- ✅ Seamless migration from Firebase Dynamic Links to AppLink

**Note:** For comprehensive instructions on migrating Firebase Dynamic Links to AppLink, refer to the [documentation](https://documentation.appsonair.com/MobileQuickstart/AppLink/firebase-dynamiclinks-migration).

## Installation

AppsOnAir-AppLink supports installation via [CocoaPods](https://cocoapods.org) and [Swift Package Manager](https://swift.org/package-manager/).

### CocoaPods

To install via CocoaPods, simply add the following line to your Podfile:

```ruby
pod 'AppsOnAir-AppLink'
```

Then run:

```bash
pod install
```

### Swift Package Manager

You can add AppsOnAir-AppLink to your project using Swift Package Manager in one of the following ways:

#### Using Xcode

1. Open your project in Xcode.
2. Go to **File → Add Package Dependencies...**
3. Enter the package URL:

    ```
    https://github.com/apps-on-air/AppsOnAir-iOS-AppLink.git
    ```

4. Select the version rule (e.g., **Up to Next Major Version**) and click **Add Package**.
5. Choose the `AppsOnAir-AppLink` library and add it to your target.

#### Using Package.swift

If you are integrating AppsOnAir-AppLink into another Swift package, add it to the `dependencies` array in your `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/apps-on-air/AppsOnAir-iOS-AppLink.git",
        from: "1.4.1"
    )
]
```

Then add `AppsOnAir-AppLink` to the dependencies of the targets that need it:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "AppsOnAir-AppLink", package: "AppsOnAir-iOS-AppLink")
    ]
)
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

Minimum deployment target: 13.0


## USAGE 

#### Enable the Advanced Deferred AppLink feature in your iOS app by adding the EnableAdvancedDeferredLink Boolean flag to your Info.plist file.
```xml
<key>EnableAdvancedDeferredLink</key>
<true/>
```

#### Add AppsonairAppId in your app info.plist file.
```xml
<key>AppsonairAppId</key>
<string>XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX</string>
```
how to get AppsonairAppId for more details check this [URL](https://documentation.appsonair.com/MobileQuickstart/GettingStarted/)

#### Add `YOUR_PROJECT.entitlements` file and add below code file for Add Associated Domain

```
<!-- If Using Universal Links -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:YOUR_DOMAIN</string> <!-- Replace with your actual domain -->
</array>
```

> ℹ️ **Note:** After configuring the Associated Domain for Universal Links, it may take up to 24 hours for the changes to be reflected and become active. The Associated Domain setup and verification process is managed by Apple.

#### If you want to add Custom URL schema for add below code to the app's `info.plist` file for. 

```
<!-- If Using Custom Url Schema -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>YOUR_URL_NAME</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_CUSTOM_URL_SCHEME</string> <!-- Replace with your custom URL scheme -->
        </array>
    </dict>
</array>
```

## 1. Initialize the AppLink services 
### Firstly, import AppsOnAir_AppLink in appDelegate

Swift / SwiftUI
```swift
import AppsOnAir_AppLink
```
Objective-C

```swift
#import "AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h"
```
Objective-C++

```swift
#import "AppsOnAir-AppLink/AppLinkService.h"
```

### App-Link Implement Code

**When using SwiftUI, it is necessary to add the **.onOpenURL** modifier in ContentView.swift, directly after any layout container such as VStack, Button, or similar views.**


```swift
VStack {
    // Your UI components here
}
.onOpenURL { url in
    AppLinkService.shared.handleAppLink(incomingURL: url)
}
```

**When using Swift with a SceneDelegate, it is necessary to add the following method inside SceneDelegate.swift**

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts:   Set<UIOpenURLContext>) {

}

func scene(_ scene: UIScene, continue userActivity:NSUserActivity) {

}
```

SwiftUI

```swift
import SwiftUI
import AppsOnAir_AppLink

@main
struct appsonairApp: App {
  
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AppLinkService.shared.initialize { url, linkInfo in
            //Write the code for handling flow based on url
        } onAttributionListener: { attributionInfo in
            //Write the code for handling attribution flow
        }
      return true
  }
}
```

Swift
```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Help to initialize link services
        AppLinkService.shared.initialize { url, linkInfo in
            //Write the code for handling flow based on url
        } onAttributionListener: { attributionInfo in
            //Write the code for handling attribution flow
        }
        return true
    }
}
```

Objective-C
```swift
#import "AppDelegate.h"
#import "AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h"

@interface AppDelegate ()
@property (nonatomic, strong) AppLinkService *appLinkServices;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
       
    // AppLink Class instance create
    self.appLinkServices = [AppLinkService shared];
    
    // Help to initialize link services
    [self.appLinkServices initializeOnDeepLinkProcessed:^(NSURL * url, NSDictionary<NSString *,id> * linkInfo) {
        //Write the code for handling flow based on url
    } onAttributionListener:^(NSDictionary<NSString *,id> * attributionInfo) {
        //Write the code for handling attribution flow
    }];
    // Override point for customization after application launch.
    return YES;
}

```

Objective-C++

```swift
#import "AppDelegate.h"
#import "AppsOnAir-AppLink/AppLinkService.h"

@interface AppDelegate ()
@property (nonatomic, strong)  AppLinkService *appLinkServices;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.appLinkServices = [AppLinkService shared];

  [self.appLinkServices initializeOnDeepLinkProcessed:^(NSURL * _Nullable url, NSDictionary * _Nonnull linkInfo) {
      //Write the code for handling flow based on url
  } onAttributionListener:^(NSDictionary * _Nonnull attributionInfo) {
      //Write the code for handling attribution flow
  }];
  
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

```

`onAttributionListener()` fires at most twice: once when the attribution is first detected, and
once more on the return to the foreground that follows `isFirstLaunch` turning `false`, so the
payload carries that flip. Later foreground returns are silent — they would only repeat the same
persisted state. Gate any one time logic on `isFirstLaunch` rather than on the callback firing.
The payload is the same one [`getAttributionInfo()`](#3-retrieving-the-attribution-info) returns.

## 2. Creating the AppLink 
You can also create link, such as from a button action:
### Firstly, import AppsOnAir_AppLink in your ViewController file or swift code file

Swift / SwiftUI
```swift
import AppsOnAir_AppLink
```
Objective-C

```swift
#import "AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h"
```
Objective-C++

```swift
#import "AppsOnAir-AppLink/AppLinkService.h"
```

### `appsFlyer` Parameters

*(Optional)* Pass this dictionary to `createAppLink` to attach AppsFlyer attribution data to the generated link.

| Key | Type | Required | Description |
|---|---|---|---|
| `channel` | String | Optional | The media source / channel driving traffic to this link (e.g. `"appsonair"`). |
| `campaignId` | String | Optional | Unique identifier for the marketing campaign. |
| `campaign` | String | Optional | Human-readable name of the marketing campaign. |
| `subs` | [String] | Optional | Sub-parameters for granular tracking (e.g. `["sub1", "sub2", "sub3", "sub4", "sub5"]`). |
| `metaTitle` | String | Optional | Title used for attribution metadata. |
| `metaDescription` | String | Optional | Description used for attribution metadata. |

### App-Link Implement Code

Swift UI
```swift
import SwiftUI
import AppsOnAir_AppLink

struct ContentView: View {
    @State private var showToast = false
    @State private var message = ""

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                // Help to create the link

                AppLinkService.shared.createAppLink(
                    url: "https://appsonair.com",
                    name: "AppsOnAir",
                    urlPrefix: "YOUR_DOMAIN_NAME", //  <urlPrefix> shouldn't contain http or https
                    shortId: "LINK_ID",   // <shortId>  If not set, it will be auto-generated
                    socialMeta: ["title": "link title","description": "link description","imageUrl": "https://image.png"],
                    isOpenInBrowserApple: false,
                    isOpenInIosApp: true,
                    iosFallbackUrl: "https://appstore.com",
                    appsFlyer: [ // Optional: AppsFlyer attribution params
                        "channel": "appsonair",
                        "campaignId": "01",
                        "campaign": "test",
                        "subs": ["sub1", "sub2", "sub3", "sub4", "sub5"],
                        "metaTitle": "metaTitle",
                        "metaDescription": "metaDescription"
                    ]
                ) { linkInfo in
                     //Write the code for handling create link
                }
            }) {
                Text("Create Link")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .toast(isPresented: $showToast, message: message)
        .onOpenURL { url in
            AppLinkService.shared.handleAppLink(incomingURL: url)
        }
    }
}
```

Swift
```swift
class ViewController: UIViewController {
  
    override func viewDidLoad() {
        super.viewDidLoad()
       
            
        let button = UIButton(type: .system)
                button.setTitle("Button", for: .normal)
                button.backgroundColor = .systemBlue
                button.setTitleColor(.white, for: .normal)
                button.layer.cornerRadius = 10
                
                // Set button frame (size and position)
                button.frame = CGRect(x: 100, y: 200, width: 150, height: 50)
                
                // Add target for onPressed (TouchUpInside)
                button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
                
                // Add the button to the view
                self.view.addSubview(button)
          }
    
          // Define the action when button is pressed
           @objc func buttonPressed() {
               // Help to create the link
               // <urlPrefix> shouldn't contain http or https
               // <shortId>  If not set, it will be auto-generated
               AppLinkService.shared.createAppLink(url: "https://appsonair.com",name: "AppsOnAir",urlPrefix: "YOUR_DOMAIN_NAME",shortId: "LINK_ID",socialMeta: ["title": "link title","description":  "link description","imageUrl": "https://image.png"],isOpenInBrowserApple: false,isOpenInIosApp: true,iosFallbackUrl: "https://appstore.com",appsFlyer: ["channel": "appsonair","campaignId": "01","campaign": "test","subs": ["sub1", "sub2", "sub3", "sub4", "sub5"],"metaTitle": "metaTitle","metaDescription": "metaDescription"]
        ) { linkInfo  in
                    //Write the code for handling create link
                }
           }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
```

Objective-C
```swift
#import "ViewController.h"
#import "AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h"


@interface ViewController ()
@property (nonatomic, strong) AppLinkService *appLinkService;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.appLinkService = [AppLinkService shared];
    // Create a UIButton programmatically
       UIButton *ctaButton = [UIButton buttonWithType:UIButtonTypeSystem];
       
       // Set button title
       [ctaButton setTitle:@"Create Link" forState:UIControlStateNormal];
       
       // Set button frame (position and size)
       ctaButton.frame = CGRectMake(100, 200, 200, 50);
       
       // Add target-action for button tap
       [ctaButton addTarget:self action:@selector(openNextScreen) forControlEvents:UIControlEventTouchUpInside];
       
       // Add button to the view
       [self.view addSubview:ctaButton];
}
- (void)openNextScreen {
     // Help to create link
     // <urlPrefix> shouldn't contain http or https
     // <shortId>  If not set, it will be auto-generated
    [self.appLinkService createAppLinkWithUrl:@"https://appsonair.com" name:@"AppsOnAir" urlPrefix:@"YOUR_DOMAIN_NAME" shortId: @"LINK_ID"socialMeta:@{@"title":@"link title",@"description":@"link description",@"imageUrl":@"https://image.png"}isOpenInBrowserApple:@0 isOpenInIosApp:@1 iosFallbackUrl:@"https://appstore.com" isOpenInAndroidApp:@1 isOpenInBrowserAndroid:@0 androidFallbackUrl:@"https://play.google.com"appsFlyer:@{@"channel":@"appsonair",@"campaignId":@"01",@"campaign":@"test",@"subs":@[@"sub1",@"sub2",@"sub3",@"sub4",@"sub5"],@"metaTitle":@"metaTitle",@"metaDescription":@"metaDescription"} completion:^(NSDictionary<NSString *,id> * linkInfo) {
        //Write the code for handling create link
    }];
}
```


Objective-C++
```swift
#import "AppsOnAir-AppLink/AppLinkService.h"

@interface AppDelegate ()
@property (nonatomic, strong)  AppLinkService *appLinkServices;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

  self.appLinkServices = [AppLinkService shared];

  [self.appLinkServices createAppLinkWithUrl:@"https://appsonair.com" name:@"AppsOnAir" urlPrefix:@"YOUR_DOMAIN_NAME" shortId: @"LINK_ID" socialMeta:@{@"title":@"link title",@"description":@"link description",@"imageUrl":@"https://image.png"}isOpenInBrowserApple:@0 isOpenInIosApp:@1 iosFallbackUrl:@"https://appstore.com" isOpenInAndroidApp:@1 isOpenInBrowserAndroid:@0 androidFallbackUrl:@"https://play.google.com" appsFlyer:@{@"channel":@"appsonair",@"campaignId":@"01",@"campaign":@"test",@"subs":@[@"sub1",@"sub2",@"sub3",@"sub4",@"sub5"],@"metaTitle":@"metaTitle",@"metaDescription":@"metaDescription"} completion:^(NSDictionary<NSString*,id> * linkInfo) {
    //Write the code for handling create link
    }];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
```


## 3. Retrieving the attribution info
You can also retrieve the attribution info on demand, such as from a button action:
### Firstly, import AppsOnAir_AppLink in your ViewController file or swift code file

Swift / SwiftUI
```swift
import AppsOnAir_AppLink
```
Objective-C

```swift
#import "AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h"
```
Objective-C++ 
```swift
#import "AppsOnAir-AppLink/AppLinkService.h"
```

### App-Link Implement Code

Swift UI
```swift
import SwiftUI
import AppsOnAir_AppLink

struct ContentView: View {
    @State private var showToast = false
    @State private var message = ""

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                AppLinkService.shared.getAttributionInfo { attributionInfo in
                   //Write the code for handling attribution flow
                }
            }) {
                Text("Fetch Attribution Info")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .toast(isPresented: $showToast, message: message)
        .onOpenURL { url in
            AppLinkService.shared.handleAppLink(incomingURL: url)
        }
    }
}
```

Swift
```swift
class ViewController: UIViewController {
  
    override func viewDidLoad() {
        super.viewDidLoad()
       
            
        let button = UIButton(type: .system)
                button.setTitle("Button", for: .normal)
                button.backgroundColor = .systemBlue
                button.setTitleColor(.white, for: .normal)
                button.layer.cornerRadius = 10
                
                // Set button frame (size and position)
                button.frame = CGRect(x: 100, y: 200, width: 150, height: 50)
                
                // Add target for onPressed (TouchUpInside)
                button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
                
                // Add the button to the view
                self.view.addSubview(button)
          }
    
          // Define the action when button is pressed
           @objc func buttonPressed() {
                // Help to retrieving the attribution info
                AppLinkService.shared.getAttributionInfo { attributionInfo in
                   //Write the code for handling attribution info
                }
           }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
```

Objective-C
```swift
#import "ViewController.h"
#import "AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h"


@interface ViewController ()
@property (nonatomic, strong) AppLinkService *appLinkService;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.appLinkService = [AppLinkService shared];
    // Create a UIButton programmatically
       UIButton *ctaButton = [UIButton buttonWithType:UIButtonTypeSystem];
       
       // Set button title
       [ctaButton setTitle:@"Fetch Attribution Info" forState:UIControlStateNormal];
       
       // Set button frame (position and size)
       ctaButton.frame = CGRectMake(100, 200, 200, 50);
       
       // Add target-action for button tap
       [ctaButton addTarget:self action:@selector(openNextScreen) forControlEvents:UIControlEventTouchUpInside];
       
       // Add button to the view
       [self.view addSubview:ctaButton];
}
- (void)openNextScreen {
    // Help to retrieving the attribution info
    [self.appLinkService getAttributionInfoWithCompletion:^(NSDictionary<NSString *,id> * attributionInfo) {
         //Write the code for handling attribution info
    }];
}
```


Objective-C++
```swift
#import "AppsOnAir-AppLink/AppLinkService.h"

@interface AppDelegate ()
@property (nonatomic, strong)  AppLinkService *appLinkServices;
@end
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

  self.appLinkServices = [AppLinkService shared];

  [self.appLinkServices getAttributionInfoWithCompletion:^(NSDictionary * _Nonnull attributionInfo) {
      //Write the code for handling attribution info
  }];

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
```

Along with the referral details, `getAttributionInfo()` and `onAttributionListener()` add the
following keys inside the `data` object of the response:

| Response Key | Type | Description |
| --- | --- | --- |
| `isFirstLaunch` | Bool | `true` only during the very first app launch after installation. It turns `false` as soon as the app leaves the foreground (backgrounded or phone locked) and stays `false` on every later launch. |
| `firstInstallTime` | Int64 | Timestamp (epoch milliseconds) of the app's first installation, derived from the app's Documents directory creation date. Computed locally, so it is always available. |
| `isConsumed` | Bool | `true` once a referral fetch has returned successfully for this install. Persisted, so it stays `true` on every later launch. |
| `attributionStatus` | String | `non-organic` when the install happened within `attributionTtl` seconds of the click, otherwise `organic`. A referral that was found but could not be timed — no click time, no `attributionTtl` in the response, or no install time — stays `non-organic`. Resolved once and restored from storage on later launches. |
| `applink_click_time` | Int64 | Timestamp (epoch milliseconds) of the click. Only present when the Advanced Deferred AppLink feature is enabled and the link carries the parameter, since the clipboard is the only source for it on iOS. |

### Deprecated APIs

The following APIs are deprecated and will be removed in a future release. Existing
integrations keep working, but should migrate:

| Deprecated | Use instead |
| --- | --- |
| `initialize(onDeepLinkProcessed:onReferralLinkDetected:)` | `initialize(onDeepLinkProcessed:onAttributionListener:)` |
| `onReferralLinkDetected()` | `onAttributionListener()` |
| `getReferralInfo()` | `getAttributionInfo()` |
| `getReferralDetails()` | `getAttributionInfo()` |

## Troubleshooting

### Swift Implementation

If your app isn’t handling Universal or Deep Links as expected, make sure the relevant methods are correctly implemented in both AppDelegate and SceneDelegate.

**AppDelegate.swift**
```swift
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let appLinkService = AppLinkService.shared
  
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        AppLinkService.shared.handleAppLink(incomingURL: url)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppLinkService.shared.handleAppLink(incomingURL: url)
        return true
    }
}
```

**SceneDelegate.swift**

```swift
import AppsOnAir_AppLink

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        let url = urlContext.url
        AppLinkService.shared.handleAppLink(incomingURL: url)
    }
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            return
        }
        AppLinkService.shared.handleAppLink(incomingURL: incomingURL)
    }
}
```

### Objective-C Implementation

**AppDelegate.m**
```swift
#import "AppDelegate.h"
#import "AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h"

@interface AppDelegate ()
@property (nonatomic, strong) AppLinkService *appLinkServices;
@end

- (BOOL)application:(UIApplication * )application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.appLinkServices = [AppLinkService shared];
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    
    [self.appLinkServices handleAppLinkWithIncomingURL:url];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {

    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = userActivity.webpageURL;
        [self.appLinkServices handleAppLinkWithIncomingURL:url];
    }
    return NO;
}

```

**SceneDelegatee.m**

```swift
#import "SceneDelegate.h"
#import "AppsOnAir_AppLink/AppsOnAir_AppLink-Swift.h"
#import "ViewController.h"

@interface SceneDelegate ()
@property (nonatomic, strong) AppLinkService *appLinkServices;
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
willConnectToSession:(UISceneSession *)session
     options:(UISceneConnectionOptions *)connectionOptions {
    
    // Handle URLs when app is cold started
    if (connectionOptions.URLContexts.count > 0) {
        UIOpenURLContext *urlContext = connectionOptions.URLContexts.allObjects.firstObject;
        NSURL *url = urlContext.URL;
        if (url) {
            [self.appLinkServices handleAppLinkWithIncomingURL:url];
        }
    }

    // Handle Universal Link via user activity when app is cold started
    if (connectionOptions.userActivities.count > 0) {
        NSUserActivity *userActivity = connectionOptions.userActivities.allObjects.firstObject;
        if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
            NSURL *url = userActivity.webpageURL;
            if (url) {
                [self.appLinkServices handleAppLinkWithIncomingURL:url];
            }
        }
    }
    self.appLinkServices = [AppLinkService shared];
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    // Set root view controller
    self.window.rootViewController = [[ViewController alloc] init];
    [self.window makeKeyAndVisible];
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *incomingURL = userActivity.webpageURL;
        if (incomingURL) {
            [self.appLinkServices handleAppLinkWithIncomingURL:incomingURL];
        }
    }
}
- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    UIOpenURLContext *urlContext = [URLContexts anyObject];
    if (urlContext) {
        NSURL *url = urlContext.URL;
        [self.appLinkServices handleAppLinkWithIncomingURL:url];
    }
}
@end

```

### Objective-C++ Implementation

```swift
#import "AppsOnAir-AppLink/AppLinkService.h"

@interface AppDelegate ()
@property (nonatomic, strong)  AppLinkService *appLinkServices;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  
  self.appLinkServices = [AppLinkService shared];
  
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {

  [self.appLinkServices handleAppLinkWithURL:url];
  
    return YES;
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {

    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = userActivity.webpageURL;
        [self.appLinkServices handleAppLinkWithURL:url];
    }
    return NO;
}
```

### Note:

For testing purposes:

- Click the referral link, it should redirect you to the App Store.

- To retrieve the latest referral data, you must uninstall the app, then reinstall it, and fetch the referral again.

## Author

devtools-logicwind, devtools@logicwind.com

## License

AppsOnAir-AppLink is available under the MIT license. See the LICENSE file for more info.

## Documentation
For more detail refer this [documentation](https://documentation.appsonair.com/MobileQuickstart/GettingStarted/).
