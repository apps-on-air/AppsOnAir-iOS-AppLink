#if canImport(UIKit)
    import UIKit
    import ObjectiveC
    import AppsOnAir_Core

    internal class AppSwizzler {

        /// Singleton instance
        static let shared = AppSwizzler()

        /// Scene delegate classes whose methods are already hooked. Hooking a class twice would
        /// wrap the handler twice and process every link twice.
        private var hookedSceneDelegateClasses = Set<ObjectIdentifier>()

        private init() {
            let sceneDelegateClasses = getSceneDelegateClasses()

            // A scene delegate can also come from `application(_:configurationForConnecting:options:)`
            // instead of Info.plist. Hook it so we catch that class before its scene connects.
            hookSceneConfigurationProviderIfNeeded()

            // Swizzle AppDelegate methods as a fallback if SceneDelegate class is not found
            guard !sceneDelegateClasses.isEmpty else {
                // Swizzle AppDelegate methods
                swizzleAppDelegateMethods()
                return
            }
            // Swizzle SceneDelegate methods
            sceneDelegateClasses.forEach { swizzleSceneDelegateMethods($0) }
        }

        // MARK: - AppDelegate Swizzling

        /// Main function to trigger swizzling of AppDelegate methods
        private func swizzleAppDelegateMethods() {
            swizzleAppDelegateIfNeeded()
            swizzleAppDelegateForOpenURLIfNeeded()
        }

        // MARK: - SceneDelegate Swizzling

        /// Resolves the app's scene delegate classes.
        ///
        /// iOS 27 requires the UIScene lifecycle for apps built with its SDK, so the delegate class
        /// is read from the `UIApplicationSceneManifest` first (this covers any class name). The
        /// name-based lookup is kept as a fallback for older setups.
        private func getSceneDelegateClasses() -> [AnyClass] {
            var classes: [AnyClass] = []
            func append(_ cls: AnyClass) {
                if !classes.contains(where: { $0 == cls }) { classes.append(cls) }
            }

            for className in sceneDelegateClassNamesFromManifest() {
                if let cls = resolveClass(named: className) {
                    Logger.logInternal("✅ Found SceneDelegate class from scene manifest: \(className)")
                    append(cls)
                }
            }

            if let cls = getSceneDelegateClassByName() {
                append(cls)
            }
            return classes
        }

        /// Reads every `UISceneDelegateClassName` declared in the Info.plist scene manifest.
        private func sceneDelegateClassNamesFromManifest() -> [String] {
            guard
                let manifest = Bundle.main.object(forInfoDictionaryKey: "UIApplicationSceneManifest")
                    as? [String: Any],
                let configurations = manifest["UISceneConfigurations"] as? [String: Any]
            else { return [] }

            return configurations.values
                .compactMap { $0 as? [[String: Any]] }
                .flatMap { $0 }
                .compactMap { $0["UISceneDelegateClassName"] as? String }
                .filter { !$0.trimmed.isEmpty }
        }

        /// Resolves a class name, also trying it with the app's module prefix.
        private func resolveClass(named className: String) -> AnyClass? {
            if let cls = NSClassFromString(className) { return cls }
            let moduleName =
                (Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String ?? "")
                .replacingOccurrences(of: "-", with: "_")
                .replacingOccurrences(of: " ", with: "_")
            guard !moduleName.isEmpty, !className.contains(".") else { return nil }
            return NSClassFromString("\(moduleName).\(className)")
        }

        private func getSceneDelegateClassByName() -> NSObject.Type? {
            let moduleName =
                Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String ?? ""

            // Try multiple class name patterns for different project types
            let classNameCandidates = [
                "\(moduleName).SceneDelegate",
                "SceneDelegate",
                "\(moduleName)_SceneDelegate",  // Common in C++ projects
                "\(Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_") ?? "")_SceneDelegate",
            ]

            for className in classNameCandidates {
                if let sceneDelegateClass = NSClassFromString(className) as? NSObject.Type {
                    Logger.logInternal("✅ Found SceneDelegate class: \(className)")
                    return sceneDelegateClass
                }
            }

            Logger.logInternal(
                "❌ Swizzling failed: Could not find SceneDelegate class. Tried: \(classNameCandidates)"
            )
            return nil
        }

        /// Hooks the deep link methods of one scene delegate class.
        ///
        /// Each method gets its own replacement implementation that calls the class's original one,
        /// so hooking several classes never affects another class or `NSObject`. A method the class
        /// does not implement is added, so links still reach the SDK.
        private func swizzleSceneDelegateMethods(_ sceneDelegateClass: AnyClass) {
            guard !hookedSceneDelegateClasses.contains(ObjectIdentifier(sceneDelegateClass)) else {
                return
            }
            // A subclass of an already hooked class inherits the hooks; hooking it as well would
            // run the handler twice.
            var superclass: AnyClass? = class_getSuperclass(sceneDelegateClass)
            while let current = superclass {
                if hookedSceneDelegateClasses.contains(ObjectIdentifier(current)) { return }
                superclass = class_getSuperclass(current)
            }
            hookedSceneDelegateClasses.insert(ObjectIdentifier(sceneDelegateClass))

            /// fetch URL when app killed
            swizzleSceneWillConnectTo(sceneDelegateClass)
            /// fetch URL when app in background
            swizzleSceneContinue(sceneDelegateClass)
            /// fetch custom URLS
            swizzleSceneOpenURLContexts(sceneDelegateClass)
        }

        /// Replaces `selector` on `cls` with the IMP built by `makeIMP`, which receives the
        /// original IMP (nil when neither the class nor its superclasses implement the method).
        private func replaceMethod(
            on cls: AnyClass, selector: Selector, makeIMP: (IMP?) -> IMP
        ) -> Bool {
            let originalMethod = class_getInstanceMethod(cls, selector)
            let types =
                originalMethod.flatMap { method_getTypeEncoding($0) }
                ?? sceneDelegateTypeEncoding(for: selector)
            guard let types else { return false }

            let newIMP = makeIMP(originalMethod.map { method_getImplementation($0) })

            // Succeeds when the method is inherited or missing, adding it only to this class.
            if class_addMethod(cls, selector, newIMP, types) { return true }
            // The class implements the method itself: replace only its implementation.
            guard let originalMethod else { return false }
            method_setImplementation(originalMethod, newIMP)
            return true
        }

        private func sceneDelegateTypeEncoding(for selector: Selector) -> UnsafePointer<CChar>? {
            guard let sceneProtocol = objc_getProtocol("UISceneDelegate") else { return nil }
            return protocol_getMethodDescription(sceneProtocol, selector, false, true).types.map {
                UnsafePointer($0)
            }
        }

        /// Swizzle: application(_:configurationForConnecting:options:)
        /// captures scene delegate classes that are configured in code.
        private func hookSceneConfigurationProviderIfNeeded() {
            guard let delegate = UIApplication.shared.delegate,
                let delegateClass: AnyClass = object_getClass(delegate)
            else { return }

            let selector = NSSelectorFromString(
                "application:configurationForConnectingSceneSession:options:")
            // Only hook an existing implementation; adding one would change how scenes are configured.
            guard class_getInstanceMethod(delegateClass, selector) != nil else { return }

            typealias Original =
                @convention(c) (
                    AnyObject, Selector, UIApplication, UISceneSession, UIScene.ConnectionOptions
                ) -> UISceneConfiguration

            let hooked = replaceMethod(on: delegateClass, selector: selector) { originalIMP in
                let original = unsafeBitCast(originalIMP!, to: Original.self)
                let block:
                    @convention(block) (
                        AnyObject, UIApplication, UISceneSession, UIScene.ConnectionOptions
                    ) -> UISceneConfiguration = { object, application, session, options in
                        let configuration = original(object, selector, application, session, options)
                        if let sceneDelegateClass = configuration.delegateClass {
                            AppSwizzler.shared.swizzleSceneDelegateMethods(sceneDelegateClass)
                        }
                        return configuration
                    }
                return imp_implementationWithBlock(block)
            }
            Logger.logInternal(
                hooked
                    ? "✅ Hooked application(_:configurationForConnecting:options:)."
                    : "❌ Could not hook application(_:configurationForConnecting:options:).")
        }

        /// Swizzle: application(_:continue:restorationHandler:) - Universal Link handling
        private func swizzleAppDelegateIfNeeded() {
            guard let delegate = UIApplication.shared.delegate,
                let delegateClass: AnyClass = object_getClass(delegate)
            else {
                Logger.logInternal("❌ Could not get UIApplication delegate")
                return
            }

            let originalSelector = NSSelectorFromString(
                "application:continueUserActivity:restorationHandler:")
            let swizzledSelector = #selector(
                AppSwizzler.swizzled_application(_:continueUserActivity:restorationHandler:))

            guard let swizzledMethod = class_getInstanceMethod(AppSwizzler.self, swizzledSelector)
            else {
                Logger.logInternal(
                    "❌ Swizzled method application:continueUserActivity:restorationHandler not found"
                )
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
                Logger.logInternal(
                    "Background method added: \(added ? "✅ Added and swizzled method" : "❌ Failed to add method")"
                )
            }
        }

        /// Swizzle: application(_:open:options:) - Custom URL Scheme Handling and app is first time open
        private func swizzleAppDelegateForOpenURLIfNeeded() {
            guard let delegate = UIApplication.shared.delegate,
                let delegateClass: AnyClass = object_getClass(delegate)
            else {
                Logger.logInternal("❌ Could not get UIApplication delegate")
                return
            }

            let originalSelector = NSSelectorFromString("application:openURL:options:")
            let swizzledSelector = #selector(AppSwizzler.swizzled_application(_:openURL:options:))

            guard let swizzledMethod = class_getInstanceMethod(AppSwizzler.self, swizzledSelector)
            else {
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
                Logger.logInternal(
                    "Deep Liking method added: \(added ? "✅ Added and swizzled method" : "❌ Failed to add method")"
                )
            }
        }

        /// Swizzle: scene(_:willConnectTo:options:)
        /// fetch URL when app is kill
        private func swizzleSceneWillConnectTo(_ sceneDelegateClass: AnyClass) {
            let selector = #selector(UISceneDelegate.scene(_:willConnectTo:options:))
            typealias Original =
                @convention(c) (AnyObject, Selector, UIScene, UISceneSession, UIScene.ConnectionOptions)
                -> Void

            let hooked = replaceMethod(on: sceneDelegateClass, selector: selector) { originalIMP in
                let original = originalIMP.map { unsafeBitCast($0, to: Original.self) }
                let block:
                    @convention(block) (AnyObject, UIScene, UISceneSession, UIScene.ConnectionOptions)
                        -> Void = { object, scene, session, connectionOptions in
                        Logger.logInternal("🔥 Swizzled method called: scene(_:willConnectTo:options:)")
                        // Always call original implementation first to ensure UI setup
                        original?(object, selector, scene, session, connectionOptions)
                        AppSwizzler.handleSceneConnectionOptions(connectionOptions)
                    }
                return imp_implementationWithBlock(block)
            }
            Logger.logInternal(
                hooked
                    ? "✅ Successfully swizzled scene(_:willConnectTo:options:)."
                    : "Swizzling failed: Could not swizzle scene(_:willConnectTo:options:).")
        }

        /// Swizzle: scene(_:continue:)
        /// fetch URL when app in background
        private func swizzleSceneContinue(_ sceneDelegateClass: AnyClass) {
            let selector = #selector(UISceneDelegate.scene(_:continue:))
            typealias Original = @convention(c) (AnyObject, Selector, UIScene, NSUserActivity) -> Void

            let hooked = replaceMethod(on: sceneDelegateClass, selector: selector) { originalIMP in
                let original = originalIMP.map { unsafeBitCast($0, to: Original.self) }
                let block: @convention(block) (AnyObject, UIScene, NSUserActivity) -> Void = {
                    object, scene, userActivity in
                    Logger.logInternal(
                        "🔥 Swizzled method called: scene(_ scene: UIScene, continue userActivity: NSUserActivity)"
                    )
                    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
                        let url = userActivity.webpageURL
                    {
                        AppLinkService.shared.appLinkHandler(inComingURL: url)
                        return
                    }
                    original?(object, selector, scene, userActivity)
                }
                return imp_implementationWithBlock(block)
            }
            Logger.logInternal(
                hooked
                    ? "✅ Successfully swizzled scene(_:continue:)."
                    : "Swizzling failed: Could not swizzle scene(_:continue:).")
        }

        /// Swizzle: scene(_:openURLContexts:)
        private func swizzleSceneOpenURLContexts(_ sceneDelegateClass: AnyClass) {
            let selector = #selector(UISceneDelegate.scene(_:openURLContexts:))
            typealias Original =
                @convention(c) (AnyObject, Selector, UIScene, Set<UIOpenURLContext>) -> Void

            let hooked = replaceMethod(on: sceneDelegateClass, selector: selector) { originalIMP in
                let original = originalIMP.map { unsafeBitCast($0, to: Original.self) }
                let block: @convention(block) (AnyObject, UIScene, Set<UIOpenURLContext>) -> Void = {
                    object, scene, URLContexts in
                    guard let urlContext = URLContexts.first else { return }
                    let url = urlContext.url

                    if !(url.scheme?.trimmed.isEmpty ?? false) {
                        Logger.logInternal("🔥 Custom URL scheme opened: \(url)")
                        AppLinkService.shared.appLinkHandler(inComingURL: url)
                        return
                    }
                    original?(object, selector, scene, URLContexts)
                }
                return imp_implementationWithBlock(block)
            }
            Logger.logInternal(
                hooked
                    ? "✅ Successfully swizzled scene(_:openURLContexts:)."
                    : "Swizzling failed: Could not swizzle scene(_:openURLContexts:).")
        }

        /// Handles a link the app was launched with (killed state).
        private static func handleSceneConnectionOptions(
            _ connectionOptions: UIScene.ConnectionOptions
        ) {
            // Check for Universal Links
            if let userActivity = connectionOptions.userActivities.first,
                userActivity.activityType == NSUserActivityTypeBrowsingWeb,
                let url = userActivity.webpageURL
            {
                Logger.logInternal("🔗 Handling Universal Link from kill state: \(url)")
                // Add slight delay to ensure UI is fully rendered, especially critical for C++ projects
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    AppLinkService.shared.appLinkHandler(inComingURL: url)
                }
                return
            }

            // Check for Custom URL Schemes
            if let urlContext = connectionOptions.urlContexts.first {
                let url = urlContext.url
                Logger.logInternal("🔗 Handling Custom URL from kill state: \(url)")
                // Add slight delay to ensure UI is fully rendered, especially critical for C++ projects
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    AppLinkService.shared.appLinkHandler(inComingURL: url)
                }
            }
        }
    }

    // MARK: - Swizzled AppDelegate Methods

    extension AppSwizzler {

        /// Swizzled: Handle custom URL schemes (e.g. myapp://)
        @objc func swizzled_application(
            _ application: UIApplication,
            openURL url: URL,
            options: [UIApplication.OpenURLOptionsKey: Any] = [:]
        ) -> Bool {
            Logger.logInternal("🔥Swizzled method called with URL: \(url)")
            if !url.absoluteString.trimmed.isEmpty {
                AppLinkService.shared.appLinkHandler(inComingURL: url)
                return true
            }

            // Forward to original (now swizzled) implementation
            return swizzled_application(application, openURL: url, options: options)
        }

        /// Swizzled: Handle universal links when app is resumed
        @objc func swizzled_application(
            _ application: UIApplication,
            continueUserActivity userActivity: NSUserActivity,
            restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
        ) -> Bool {
            Logger.logInternal(
                "🔥 Swizzled: Handling universal link - \(userActivity.webpageURL ?? URL(fileURLWithPath: ""))"
            )

            if let incomingURL = userActivity.webpageURL {
                AppLinkService.shared.appLinkHandler(inComingURL: incomingURL)
                return true
            }

            return swizzled_application(
                application, continueUserActivity: userActivity,
                restorationHandler: restorationHandler)
        }
    }

#endif
