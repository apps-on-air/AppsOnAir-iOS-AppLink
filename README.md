## [![pub package](https://appsonair.com/images/logo.svg)](https://cocoapods.org/pods/AppsOnAir-AppRemark)
# AppsOnAir-AppLink

[![CI Status](https://img.shields.io/travis/164989979/AppsOnAir-AppLink.svg?style=flat)](https://travis-ci.org/164989979/AppsOnAir-AppLink)
[![Version](https://img.shields.io/cocoapods/v/AppsOnAir-AppLink.svg?style=flat)](https://cocoapods.org/pods/AppsOnAir-AppLink)
[![License](https://img.shields.io/cocoapods/l/AppsOnAir-AppLink.svg?style=flat)](https://cocoapods.org/pods/AppsOnAir-AppLink)
[![Platform](https://img.shields.io/cocoapods/p/AppsOnAir-AppLink.svg?style=flat)](https://cocoapods.org/pods/AppsOnAir-AppLink)

## Overview

**AppsOnAir-AppLink** enables you to handle deep links, and in-app routing seamlessly in your IOS app. With a simple integration, you can configure, manage, and act on links from the web dashboard in real time.

## ⚠️ Important Notice ⚠️

This plugin is currently in **pre-production**. While the plugin is fully functional, the supported services it integrates with are not yet live in production. Stay tuned for updates as we bring our services to production!

## 🚀 Features

- ✅ Deep link support (URI scheme, App Links)
- ✅ Fallback behavior (e.g., open App Store)
- ✅ Custom domain support
- ✅ Firebase dynamic link migration to AppLink(Coming Soon)

## Installation

AppsOnAir-AppLink is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AppsOnAir-AppLink'
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

Minimum deployment target: 13.0


## USAGE 

#### Add APIKey in your app info.plist file.
```xml
<key>AppsOnAirAPIKey</key>
<string>XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX</string>
```
how to get APIKey for more details check this [URL](https://documentation.appsonair.com/MobileQuickstart/GettingStarted/)

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

## 1. Initialize the AppLink service 
### Firstly, import AppsOnAir_AppLink in appDelegate

Swift / SwiftUI
```swift
import AppsOnAir_AppLink
```
Objective-C

```swift
#import "AppsOnAir_AppLink-Swift.h"
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
      AppLinkService.shared.initialize { incomingURL,linkInfo in
          //write the code for handling flow based o url
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
    let appOnAirLinkService = AppLinkService.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // help to initialize link services
        appOnAirLinkService.initialize { url,linkInfo in
           //write the code for handling flow based o url
        }
        return true
    }
}
```

Objective-c
```swift
#import "AppDelegate.h"
#import "AppsOnAir_AppLink-Swift.h"

@interface AppDelegate ()
@property (nonatomic, strong) AppLinkService *appLinkServices;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
       
    // App Link Class instance create
    self.appLinkServices = [AppLinkService shared];
    
    // help to initialize link services
    [self.appLinkServices initializeWithCompletion:^(NSURL * url, NSDictionary<NSString *,id> * linkInfo) {
        //write the code for handling flow based on url
    }];
    // Override point for customization after application launch.
    return YES;
}

```

## 2. Creating the AppLink 
You can also create link, such as from a button action:
### Firstly, import AppsOnAir_AppLink in your ViewController file or swift code file

Swift / SwiftUI
```swift
import AppsOnAir_AppLink
```
Objective-C

```swift
#import "AppsOnAir_AppLink-Swift.h"
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
                AppLinkService.shared.createAppLink(
                    url: "https://example.com",
                    name: "YOUR_LINK_NAME",
                    urlPrefix: "YOUR_DOMAIN_NAME",
                    shortId: "LINK_ID",
                    socialMeta: [:],
                    isOpenInBrowserApple: false,
                    isOpenInIosApp: true,
                    iOSFallbackUrl: "",
                    isOpenInAndroidApp: true,
                    isOpenInBrowserAndroid: false,
                    androidFallbackUrl: ""
                ) { linkInfo in
                     //write the code for handling create link
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
    let appOnAirLinkService = AppLinkService.shared
  
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
               appOnAirLinkService.createAppLink(url: "https://example.com",name: "YOUR_LINK_NAME",urlPrefix: "YOUR_DOMAIN_NAME",shortId: "LINK_ID",socialMeta: [:],isOpenInBrowserApple: false,isOpenInIosApp: true,iOSFallbackUrl: "",isOpenInAndroidApp: true,isOpenInBrowserAndroid: false,androidFallbackUrl: ""
        ) { linkInfo  in
                    //write the code for handling create link
                }
           }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
```

Objective-c
```swift
#import "ViewController.h"
#import "AppsOnAir_AppLink-Swift.h"


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
    [self.appLinkService createAppLinkWithUrl:@"https://example.com" name:@"YOUR_LINK_NAME" urlPrefix:@"YOUR_DOMAIN_NAME" shortId: @"LINK_ID"socialMeta:@{}isOpenInBrowserApple:true isOpenInIosApp:true iOSFallbackUrl:@"www.google.com" isOpenInAndroidApp:true isOpenInBrowserAndroid:false androidFallbackUrl:@"www.google.com" completion:^(NSDictionary<NSString *,id> * linkInfo) {
        //write the code for handling create link
    }];
}
```

## Troubleshooting

### Swift Implementation

If your app isn’t handling Universal or Deep Links as expected, make sure the relevant methods are correctly implemented in both AppDelegate and SceneDelegate.

**AppDelegate.swift**
```swift
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let appOnAirLinkService = AppLinkService.shared
  
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        appOnAirLinkService.handleAppLink(incomingURL: url)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        appOnAirLinkService.handleAppLink(incomingURL: url)
        return true
    }
}
```

**SceneDelegate.swift**

```swift
import AppsOnAir_AppLink

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    let appOnAirLinkService = AppLinkService.shared
    var window: UIWindow?

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        let url = urlContext.url
        appOnAirLinkService.handleAppLink(incomingURL: url)
    }
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            return
        }
        appOnAirLinkService.handleAppLink(incomingURL: incomingURL)
    }
}
```

### Objective-C Implementation

**AppDelegate.m**
```swift
#import "AppDelegate.h"
#import "AppsOnAir_AppLink-Swift.h"

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
#import "AppsOnAir_AppLink-Swift.h"
#import "ViewController.h"

@interface SceneDelegate ()
@property (nonatomic, strong) AppLinkService *appLinkServices;
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
willConnectToSession:(UISceneSession *)session
     options:(UISceneConnectionOptions *)connectionOptions {
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

## Author

devtools-logicwind, devtools@logicwind.com

## License

AppsOnAir-AppLink is available under the MIT license. See the LICENSE file for more info.

## Documentation
For more detail refer this [documentation](https://documentation.appsonair.com/MobileQuickstart/GettingStarted/).