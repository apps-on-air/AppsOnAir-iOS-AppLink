import UIKit
import AppsOnAir_Core

// Swizzler of AppDelegateSwizzler methods
@available(iOS 13.0, *)
public class AppDelegateSwizzler {
  
    public static let shared = AppDelegateSwizzler()

    private init() {
        //init swizzling
        swizzleAppDelegateMethod()
        swizzleApplicationOpenURL()
    }
    
    private func swizzleAppDelegateMethod() {
        // Safely cast UIApplication.shared.delegate to NSObject
        guard let delegate = UIApplication.shared.delegate as? NSObject,
              let originalMethod = class_getInstanceMethod(type(of: delegate), #selector(UIApplicationDelegate.application(_:continue:restorationHandler:))),
              let swizzledMethod = class_getInstanceMethod(AppDelegateSwizzler.self, #selector(swizzled_application(_:continue:restorationHandler:))) else {
            return
        }

        // Exchange the original method with the swizzled one
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    private func swizzleApplicationOpenURL() {
            guard let delegate = UIApplication.shared.delegate as? NSObject,
                  let originalMethod = class_getInstanceMethod(type(of: delegate), #selector(UIApplicationDelegate.application(_:open:options:))),
                  let swizzledMethod = class_getInstanceMethod(AppDelegateSwizzler.self, #selector(swizzled_app(_:open:options:))) else {
                return
            }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }

    ///Handle URL retrieval during the application's initial launch, including support for custom schema URLs.
    @objc func swizzled_app(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool { 
    
        if(!(url.absoluteString.isEmpty)){
            // Handle the dynamic link or custom domain here
            AppLinkService.shared.initialLinkSet = true
            AppLinkService.shared.handleLink(url: url)
            DispatchQueue.main.async{
                Snackbar.show(message: "App First Time Launch URL called : \(url.absoluteString)")
           }
            return true
        }
        return swizzled_app(app, open: url, options: options)
    }
    
    /// Retrieve Universal Links when the app is in the background or terminated state.
    @objc private func swizzled_application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Custom logic from your pod
        if let incomingURL = userActivity.webpageURL {
            AppLinkService.shared.handleLink(url: incomingURL)
            return true
        }
        // Call the original method (the one that was swizzled)
        return swizzled_application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
   
}
