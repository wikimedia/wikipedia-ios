import UIKit
import BackgroundTasks
import CocoaLumberjackSwift
import WMFTestKitchen

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
#if TEST
// Avoids loading needless dependencies during unit tests
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
    }
    
#else

    var window: UIWindow?
    private var appNeedsResume = true
    // Tracks the most recent source used to open the app (external_link, widget, shortcut, notification, etc.)
    // This is consumed when the scene becomes active to submit the apps-open instrument.
    var lastOpenSource: String? = nil
    // Tracks whether the current activation was triggered by an external link (deep link from Safari, etc.).
    // Unlike `lastOpenSource`, this is NOT consumed by the app_open instrument — it persists for the
    // activation so announcement modals (on Explore and Article) can suppress themselves and defer to the
    // next normal app open. Reset to false at the start of each foreground cycle.
    var didOpenAppFromExternalLink = false
    // Holds a pending app_open source when the data environment isn't ready yet (e.g. fresh install).
    // Consumed by dataEnvironmentDidSetup() once setup completes.
    private var pendingAppOpenSource: String? = nil
    // Tracks whether the app was in the background before this activation cycle.
    // Used to distinguish cold launch (app_icon) from background-to-foreground return (background).
    private var wasInBackground = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        guard let appViewController else {
            return
        }
        
        // scene(_ scene: UIScene, continue userActivity: NSUserActivity) and
        // scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>)
        // windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void)
        // are not called upon terminated state, so we need to handle them explicitly here.
        if let userActivity = connectionOptions.userActivities.first {
            processUserActivity(userActivity)
        } else if !connectionOptions.urlContexts.isEmpty {
            openURLContexts(connectionOptions.urlContexts)
        } else if let shortcutItem = connectionOptions.shortcutItem {
            processShortcutItem(shortcutItem)
        }
        
        UNUserNotificationCenter.current().delegate = appViewController
        appViewController.launchApp(in: window, waitToResumeApp: appNeedsResume)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {

    }

    func sceneDidBecomeActive(_ scene: UIScene) {

        // Submit app_open instrument with the most recent source (if any), then resume the app.
        submitAppOpenIfNeeded()

        resumeAppIfNecessary()
    }

    func sceneWillResignActive(_ scene: UIScene) {

        UserDefaults.standard.wmf_setAppResignActiveDate(Date())
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        appDelegate?.cancelPendingBackgroundTasks()
        wasInBackground = true
        // Reset at the start of each foreground cycle. If this activation is an external-link open,
        // openURLContexts/continue userActivity (which fire after this) will set it back to true.
        didOpenAppFromExternalLink = false
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        appDelegate?.updateDynamicIconShortcutItems()
        appDelegate?.scheduleBackgroundAppRefreshTask()
        appDelegate?.scheduleDatabaseHousekeeperTask()
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        processShortcutItem(shortcutItem, completionHandler: completionHandler)
    }
    
    private func processShortcutItem(_ shortcutItem: UIApplicationShortcutItem, completionHandler: ((Bool) -> Void)? = nil) {
        // Record that the app was opened via a home screen shortcut
        self.lastOpenSource = "shortcut"
        appViewController?.processShortcutItem(shortcutItem) { handled in
            completionHandler?(handled)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        processUserActivity(userActivity)
    }
    
    private func processUserActivity(_ userActivity: NSUserActivity) {
        guard let appViewController else {
            return
        }
        
        appViewController.showSplashView()

        // Extract source from the webpage URL's query parameters (e.g. universal links from widgets
        // include source=widget_* so we can attribute the open correctly without overwriting
        // a source that openURLContexts may have already set).
        if lastOpenSource == nil,
           let webpageURL = userActivity.webpageURL,
           let components = URLComponents(url: webpageURL, resolvingAgainstBaseURL: false),
           let sourceValue = components.queryItems?.first(where: { $0.name == "source" })?.value {
            self.lastOpenSource = sourceValue
        }

        var userInfo = userActivity.userInfo
        userInfo?[WMFRoutingUserInfoKeys.source] = WMFRoutingUserInfoSourceValue.deepLinkRawValue

        // Inject widget article source if this activation came from a widget universal link, so the
        // ios_article_link_interaction instrument can record source = 29 (widget).
        if let openSource = lastOpenSource, openSource.hasPrefix("widget_") {
            var info = userInfo ?? [:]
            info[ArticleSourceUserInfoKeys.articleSource] = ArticleSource.widget.rawValue
            userInfo = info
        }

        // Only set external_link source if not already set (e.g. by openURLContexts which may have
        // extracted a widget source from the URL, or extracted above from the webpageURL query params).
        if lastOpenSource == nil {
            self.lastOpenSource = "external_link"
            self.didOpenAppFromExternalLink = true
        }
        userActivity.userInfo = userInfo
        
        _ = appViewController.processUserActivity(userActivity, animated: false) { [weak self] in

            guard let self else {
                return
            }
            
            if appNeedsResume {
                resumeAppIfNecessary()
            } else {
                appViewController.hideSplashView()
            }
        }
    }
    
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: any Error) {
        DDLogDebug("didFailToContinueUserActivityWithType: \(userActivityType) error: \(error)")
    }
    
    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) {
        DDLogDebug("didUpdateUserActivity: \(userActivity)")
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        openURLContexts(URLContexts)
    }
    
    private func openURLContexts(_ URLContexts: Set<UIOpenURLContext>) {
        guard let appViewController else {
            return
        }
        
        guard var firstURL = URLContexts.first?.url else {
            return
        }
        
        // Extract source from URL query parameters before any activity processing, so widget taps
        // (which include source=widget_*) are not overwritten by processUserActivity setting "external_link".
        if var components = URLComponents(url: firstURL, resolvingAgainstBaseURL: false),
           let sourceValue = components.queryItems?.first(where: { $0.name == "source" })?.value {
            self.lastOpenSource = sourceValue
            
            // reassign without source component before deep linking
            // Fixes deep link bug https://phabricator.wikimedia.org/T426637
            components.queryItems = components.queryItems?.filter { $0.name != "source" }
            if (components.queryItems?.count ?? 0) == 0 {
                components.queryItems = nil
            }
            if let strippedFirstURL = components.url {
                firstURL = strippedFirstURL
            }
            
        } else {
            // URL opened from an external app (e.g. Chrome, Safari) with no source param.
            self.lastOpenSource = "external_link"
            self.didOpenAppFromExternalLink = true
        }
        
        // Try to derive an NSUserActivity for the URL and route accordingly.
        if var activity = NSUserActivity.wmf_activity(forWikipediaScheme: firstURL) ?? NSUserActivity.wmf_activity(for: firstURL) {
            // Propagate widget article source into the activity userInfo so article-view
            // instrumentation (ios_article_link_interaction) can record source = 29 (widget).
            if let openSource = self.lastOpenSource, openSource.hasPrefix("widget_") {
                var userInfo = activity.userInfo ?? [:]
                userInfo[ArticleSourceUserInfoKeys.articleSource] = ArticleSource.widget.rawValue
                activity.userInfo = userInfo
            }
            appViewController.showSplashView()
            _ = appViewController.processUserActivity(activity, animated: false) { [weak self] in
                
                guard let self else {
                    return
                }
                
                if appNeedsResume {
                    resumeAppIfNecessary()
                } else {
                    appViewController.hideSplashView()
                }
            }
        } else {
            resumeAppIfNecessary()
        }
    }
    
    // Submit the TestKitchen "apps-open" instrument for app opens. This reads and consumes `lastOpenSource`.
    private func submitAppOpenIfNeeded() {
        // If no specific entry point was recorded, determine the source from how the app was activated:
        // - Cold launch with no external entry point → user tapped the app icon.
        // - Warm foreground return with no external entry point → app came back from background.
        let source: String
        if let explicitSource = lastOpenSource {
            source = explicitSource
        } else if !wasInBackground {
            // sceneWillEnterForeground was not called before this activation, so this is a cold launch.
            source = "app_icon"
        } else {
            source = "background"
        }
        lastOpenSource = nil
        wasInBackground = false

        // On fresh install, the data environment (languages, mediawiki project) may not be ready yet
        // when sceneDidBecomeActive fires. Defer the submission until dataEnvironmentDidSetup() is called.
        guard MWKDataStore.shared().primarySiteURL != nil else {
            pendingAppOpenSource = source
            return
        }

        submitAppOpen(source: source)
    }

    private func submitAppOpen(source: String) {
        let instrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-open")
            .startFunnel(name: "apps_open")
        instrument.submitInteraction(action: "app_open", actionSource: source)
    }

    // Called from setupWMFDataEnvironment once the data store and languages are ready.
    // Submits any app_open event that was deferred due to the data environment not being set up yet.
    @objc func dataEnvironmentDidSetup() {
        guard let source = pendingAppOpenSource else { return }
        pendingAppOpenSource = nil
        submitAppOpen(source: source)
    }
    
    // Exposed to Objective-C so other app-side ObjC code (e.g. WMFAppViewController) can mark the last open source
    // when a notification or other entry point is handled prior to scene activation.
    @objc func setLastOpenSource(_ source: NSString?) {
        self.lastOpenSource = source as String?
    }

    // MARK: Private
    
    private var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    private var appViewController: WMFAppViewController? {
        return appDelegate?.appViewController
    }
    
    private func resumeAppIfNecessary() {
        if appNeedsResume {
            appViewController?.hideSplashScreenAndResumeApp()
            appNeedsResume = false
        }
    }
    
#endif
}
