import UIKit
import BackgroundTasks
import CocoaLumberjackSwift

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
    // Tracks the most recent source used to open the app (deep link, widget, shortcut, push, etc.)
    // This is consumed when the scene becomes active to submit the apps-open instrument.
    private var lastOpenSource: String? = nil
    // Holds a pending app_open source when the data environment isn't ready yet (e.g. fresh install).
    // Consumed by dataEnvironmentDidSetup() once setup completes.
    private var pendingAppOpenSource: String? = nil

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
        var userInfo = userActivity.userInfo
        userInfo?[WMFRoutingUserInfoKeys.source] = WMFRoutingUserInfoSourceValue.deepLinkRawValue
        // Only set deepLink source if not already set (e.g. by openURLContexts which may have extracted "widget" from the URL)
        if lastOpenSource == nil {
            self.lastOpenSource = WMFRoutingUserInfoSourceValue.deepLinkRawValue
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
        
        guard let firstURL = URLContexts.first?.url else {
            return
        }
        
        // Extract source from URL query parameters before any activity processing, so widget taps
        // (which include source=widget) are not overwritten by processUserActivity setting "deepLink".
        if let components = URLComponents(url: firstURL, resolvingAgainstBaseURL: false),
           let sourceValue = components.queryItems?.first(where: { $0.name == "source" })?.value {
            self.lastOpenSource = sourceValue
        } else {
            self.lastOpenSource = WMFRoutingUserInfoSourceValue.deepLinkRawValue
        }
        
        // Try to derive an NSUserActivity for the URL and route accordingly.
        if let activity = NSUserActivity.wmf_activity(forWikipediaScheme: firstURL) ?? NSUserActivity.wmf_activity(for: firstURL) {
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
        // Use a default source for foreground returns if none was recorded
        let source = lastOpenSource ?? "foreground"
        // Reset to avoid duplicate submissions
        lastOpenSource = nil

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
