import UIKit
import ObjectiveC
import AppsOnAir_Core

internal class AppSwizzler {
    
    /// Singleton instance
    static let shared = AppSwizzler()
    
    private init() {
        // Swizzle AppDelegate methods as a fallback if SceneDelegate class is not found
        guard let _ = getSceneDelegateClass() else {
            // Swizzle AppDelegate methods
            swizzleAppDelegateMethods()
            return
        }
        // Swizzle SceneDelegate methods
        swizzleSceneDelegateMethods()
    }
    
    // MARK: - AppDelegate Swizzling
    
    /// Main function to trigger swizzling of AppDelegate methods
    private func swizzleAppDelegateMethods() {
        swizzleAppDelegateIfNeeded()
        swizzleAppDelegateForOpenURLIfNeeded()
    }
    
    // MARK: - SceneDelegate Swizzling
    private func getSceneDelegateClass() -> NSObject.Type? {
        let moduleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String ?? ""
        
        // Try multiple class name patterns for different project types
        let classNameCandidates = [
            "\(moduleName).SceneDelegate",
            "SceneDelegate",
            "\(moduleName)_SceneDelegate",  // Common in C++ projects
            "\(Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_") ?? "")_SceneDelegate"
        ]
        
        for className in classNameCandidates {
            if let sceneDelegateClass = NSClassFromString(className) as? NSObject.Type {
                Logger.logInternal("✅ Found SceneDelegate class: \(className)")
                return sceneDelegateClass
            }
        }
        
        Logger.logInternal("❌ Swizzling failed: Could not find SceneDelegate class. Tried: \(classNameCandidates)")
        return nil
    }

    /// Main function to trigger swizzling of SceneDelegate methods
    private func swizzleSceneDelegateMethods() {
        // NOTE: Replace "SceneDelegate" with your actual class name if different
        guard let sceneDelegateClass = getSceneDelegateClass()else {
            Logger.logInternal("Swizzling failed: Could not find SceneDelegate class.")
            return
        }
        
        // Swizzle individual methods
        /// fetch URL when app killed
        swizzleSceneWillConnectTo(sceneDelegateClass)
        /// fetch URL when app in background
        swizzleSceneContinue(sceneDelegateClass)
        /// fetch custom URLS
        swizzleSceneOpenURLContexts(sceneDelegateClass)
    }
    
    /// Swizzle: application(_:continue:restorationHandler:) - Universal Link handling
    private func swizzleAppDelegateIfNeeded() {
        guard let delegate = UIApplication.shared.delegate,
              let delegateClass: AnyClass = object_getClass(delegate) else {
            Logger.logInternal("❌ Could not get UIApplication delegate")
            return
        }
        
        let originalSelector = NSSelectorFromString("application:continueUserActivity:restorationHandler:")
        let swizzledSelector = #selector(AppSwizzler.swizzled_application(_:continueUserActivity:restorationHandler:))
        
        guard let swizzledMethod = class_getInstanceMethod(AppSwizzler.self, swizzledSelector) else {
            Logger.logInternal("❌ Swizzled method application:continueUserActivity:restorationHandler not found")
            return
        }
        
        if let originalMethod = class_getInstanceMethod(delegateClass, originalSelector) {
            // Swizzle existing method
            method_exchangeImplementations(originalMethod, swizzledMethod)
            Logger.logInternal("✅ Swizzled existing method")
        } else {
            // Method doesn't exist - add ours
            let imp = method_getImplementation(swizzledMethod)
            let types = method_getTypeEncoding(swizzledMethod)
            let added = class_addMethod(delegateClass, originalSelector, imp, types)
             Logger.logInternal("Background method added: \(added ? "✅ Added and swizzled method" : "❌ Failed to add method")")
        }
    }
    
    /// Swizzle: application(_:open:options:) - Custom URL Scheme Handling and app is first time open
    private func swizzleAppDelegateForOpenURLIfNeeded() {
        guard let delegate = UIApplication.shared.delegate,
              let delegateClass: AnyClass = object_getClass(delegate) else {
            Logger.logInternal("❌ Could not get UIApplication delegate")
            return
        }
        
        let originalSelector = NSSelectorFromString("application:openURL:options:")
        let swizzledSelector = #selector(AppSwizzler.swizzled_application(_:openURL:options:))
        
        guard let swizzledMethod = class_getInstanceMethod(AppSwizzler.self, swizzledSelector) else {
            Logger.logInternal("❌ Swizzled method application:openURL:options: not found")
            return
        }
        
        if let originalMethod = class_getInstanceMethod(delegateClass, originalSelector) {
            // Method exists — do the swizzle
            method_exchangeImplementations(originalMethod, swizzledMethod)
            Logger.logInternal("✅ Swizzled existing openURL method")
        } else {
            // Method doesn't exist — add and swizzle
            let imp = method_getImplementation(swizzledMethod)
            let types = method_getTypeEncoding(swizzledMethod)
            let added = class_addMethod(delegateClass, originalSelector, imp, types)
            Logger.logInternal("Deep Liking method added: \(added ? "✅ Added and swizzled method" : "❌ Failed to add method")")
        }
    }
    
    
    /// Swizzle: scene(_:willConnectTo:options:)
    /// fetch URL when app is kill
    private func swizzleSceneWillConnectTo(_ sceneDelegateClass: NSObject.Type) {
        let originalSelector = #selector(UISceneDelegate.scene(_:willConnectTo:options:))
        let swizzledSelector = #selector(sceneDelegateClass.swizzled_scene(_:willConnectTo:options:))
        
        guard let originalMethod = class_getInstanceMethod(sceneDelegateClass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(sceneDelegateClass, swizzledSelector) else {
            Logger.logInternal("Swizzling failed: Could not find methods to swizzle scene(_:willConnectTo:options:).")
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
        Logger.logInternal("✅ Successfully swizzled scene(_:willConnectTo:options:).")
    }
    
    /// Swizzle: scene(_:continue:)
    /// fetch URL when app in background
    private func swizzleSceneContinue(_ sceneDelegateClass: NSObject.Type) {
        let originalSelector = #selector(UISceneDelegate.scene(_:continue:))
        let swizzledSelector = #selector(sceneDelegateClass.swizzled_scene(_:continue:))
        
        guard let originalMethod = class_getInstanceMethod(sceneDelegateClass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(sceneDelegateClass, swizzledSelector) else {
            Logger.logInternal("Swizzling failed: Could not find methods to swizzle scene(_:continue:).")
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
        Logger.logInternal("✅ Successfully swizzled scene(_:continue:).")
    }
    
    /// Swizzle: scene(_:openURLContexts:)
    private func swizzleSceneOpenURLContexts(_ sceneDelegateClass: NSObject.Type) {
        let originalSelector = #selector(UISceneDelegate.scene(_:openURLContexts:))
        let swizzledSelector = #selector(sceneDelegateClass.swizzle_scene_continue(_:openURLContexts:))
        
        guard let originalMethod = class_getInstanceMethod(sceneDelegateClass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(sceneDelegateClass, swizzledSelector) else {
            Logger.logInternal("Swizzling failed: Could not find methods to swizzle scene(_:openURLContexts:).")
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
        Logger.logInternal("✅ Successfully swizzled scene(_:openURLContexts:).")
    }
}

// MARK: - Swizzled AppDelegate Methods

extension AppSwizzler {
    
    /// Swizzled: Handle custom URL schemes (e.g. myapp://)
    @objc func swizzled_application(_ application: UIApplication,
                                           openURL url: URL,
                                           options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Logger.logInternal("🔥Swizzled method called with URL: \(url)")
        if !url.absoluteString.trimmed.isEmpty {
            AppLinkService.shared.appLinkHandler(inComingURL: url)
            return true
        }
        
        // Forward to original (now swizzled) implementation
        return swizzled_application(application, openURL: url, options: options)
    }
    
    /// Swizzled: Handle universal links when app is resumed
    @objc func swizzled_application(_ application: UIApplication,
                                    continueUserActivity userActivity: NSUserActivity,
                                    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        Logger.logInternal("🔥 Swizzled: Handling universal link - \(userActivity.webpageURL ?? URL(fileURLWithPath: ""))")
        
        if let incomingURL = userActivity.webpageURL {
            AppLinkService.shared.appLinkHandler(inComingURL: incomingURL)
            return true
        }
        
        return swizzled_application(application, continueUserActivity: userActivity, restorationHandler: restorationHandler)
    }
}

// MARK: - Swizzled SceneDelegate Methods

extension NSObject {
    
    /// Swizzled: scene(_:willConnectTo:options:)
    /// for init link when app in kill mode
    @objc func swizzled_scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        Logger.logInternal("🔥 Swizzled method called: scene(_:willConnectTo:options:)")
        
        // Always call original implementation first to ensure UI setup
        self.swizzled_scene(scene, willConnectTo: session, options: connectionOptions)
        
        // Then handle deep links after UI is initialized
        var handledLink = false
        
        // Check for Universal Links
        if let userActivity = connectionOptions.userActivities.first,
           userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            
            Logger.logInternal("🔗 Handling Universal Link from kill state: \(url)")
            // Add slight delay to ensure UI is fully rendered, especially critical for C++ projects
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                AppLinkService.shared.appLinkHandler(inComingURL: url)
            }
            handledLink = true
        }
        
        // Check for Custom URL Schemes
        if !handledLink, let urlContext = connectionOptions.urlContexts.first {
            let url = urlContext.url
            Logger.logInternal("🔗 Handling Custom URL from kill state: \(url)")
            // Add slight delay to ensure UI is fully rendered, especially critical for C++ projects
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                AppLinkService.shared.appLinkHandler(inComingURL: url)
            }
        }
    }
    
    /// Swizzled: scene(_:continue:)
    /// for background fetch the link when app in background
    @objc func swizzled_scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        Logger.logInternal("🔥 Swizzled method called: scene(_ scene: UIScene, continue userActivity: NSUserActivity)")
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            AppLinkService.shared.appLinkHandler(inComingURL: url)
            return
        }
        
        self.swizzled_scene(scene, continue: userActivity)
    }
    
    /// Swizzled: scene(_:openURLContexts:)
    /// for custom URL schema handling 
    @objc func swizzle_scene_continue(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        let url = urlContext.url
        
        if !(url.scheme?.trimmed.isEmpty ?? false) {
            Logger.logInternal("🔥 Custom URL scheme opened: \(url)")
            AppLinkService.shared.appLinkHandler(inComingURL: url)
            return
        }
        
        self.swizzle_scene_continue(scene, openURLContexts: URLContexts)
    }
}
