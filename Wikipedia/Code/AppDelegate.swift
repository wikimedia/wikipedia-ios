import BackgroundTasks
import CocoaLumberjackSwift
import UIKit
import WMF

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let backgroundFetchInterval: TimeInterval = 10800 // 3 Hours
    private let backgroundAppRefreshTaskIdentifier = "org.wikimedia.wikipedia.appRefresh"
    
    var window: UIWindow? {
        get {
            if (_window == nil) {
                _window = UIWindow.init(frame: UIScreen.main.bounds)
            }
            return _window
        }
        set(newWindow) {
            _window = newWindow
        }
    }
    private var _window: UIWindow?

    var appViewController: WMFAppViewController?
    private var appNeedsResume = false
    
    
    // MARK: Defaults
    
    /**
     * Register default application preferences.
     * @note This must be loaded before application launch so unit tests can run
     */
    private static let setDefaultsForTesting: Void = UserDefaults.standard.register(defaults: ["WMFAutoSignTalkPageDiscussions": true])
    
    
    // MARK: UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        self.registerBackgroundTasksForApplication(application)
        
#if DEBUG
        // Use NSLog so we can break and copy/paste. DDLogDebug is async.
        NSLog("\nSimulator container directory:\n\t\(FileManager.default.wmf_containerPath())\n");
#endif
        
#if UI_TEST
        if (UserDefaults.standard.wmf_isFastlaneSnapshotInProgress()) {
            UIView.setAnimationsEnabled(false)
        }
#endif
        
        UserDefaults.standard.wmf_migrateFontSizeMultiplier()
        UserDefaults.standard.shouldRestoreNavigationStackOnResume = shouldRestoreNavigationStackOnResumeAfterBecomingActive(becameActiveDate: Date())
        
        appNeedsResume = true
        let vc = WMFAppViewController()
        UNUserNotificationCenter.current().delegate = vc
        vc.launchApp(in: window!, waitToResumeApp: appNeedsResume)
        appViewController = vc
        
        updateDynamicIconShortcutItems()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        UserDefaults.standard.wmf_setAppResignActiveDate(Date())
        EventPlatformClient.shared.appInBackground()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        updateDynamicIconShortcutItems()
        scheduleBackgroundAppRefreshTask()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        cancelPendingBackgroundTasks()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        resumeAppIfNecessary()
        EventPlatformClient.shared.appInForeground()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        applicationDidEnterBackground(application)
        EventPlatformClient.shared.appWillClose()
    }
    
    
    // MARK: AppVC Resume
    
    private func resumeAppIfNecessary() {
        if (appNeedsResume) {
            guard let vc = appViewController else {
                return
            }
            vc.hideSplashScreenAndResumeApp()
            appNeedsResume = false
        }
    }
    
    private func shouldRestoreNavigationStackOnResumeAfterBecomingActive(becameActiveDate: Date) -> Bool {
        if (!UserDefaults.standard.wmf_openAppOnSearchTab) {
            return false
        }
        guard let resignActiveDate = UserDefaults.standard.wmf_appResignActiveDate() else {
            return false
        }
        guard let cutoffDate = NSCalendar.wmf_utcGregorian().nextDate(after: resignActiveDate, matchingHour: 5, minute: 0, second: 0, options: NSCalendar.Options.matchStrictly) else {
            return false
            
        }
        return becameActiveDate < cutoffDate
    }
    
    
    // MARK: NSUserActivity Handling
    
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard let vc = appViewController else {
            return false
        }
        vc.showSplashView()
        return vc.processUserActivity(userActivity, animated: false) {
            if (self.appNeedsResume) {
                self.resumeAppIfNecessary()
            } else {
                vc.hideSplashView(animated: true)
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        DDLogDebug("didFailToContinueUserActivityWithType: \(userActivityType) error: \(error)");
    }
    
    func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) {
        DDLogDebug("didUpdateUserActivity: \(userActivity)");
    }
    
    
    // MARK: NSURL Handling
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let activity = NSUserActivity.wmf_activity(forWikipediaScheme: url) ?? NSUserActivity.wmf_activity(for: url) else {
            resumeAppIfNecessary()
            return false
        }
        guard let vc = appViewController else {
            return false
        }
        return vc.processUserActivity(activity, animated: false) {
            if (self.appNeedsResume) {
                self.resumeAppIfNecessary()
            } else {
                vc.hideSplashView(animated: true)
            }
        }
    }
    
    
    // MARK: Shortcuts
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        guard let vc = appViewController else {
            return
        }
        vc.processShortcutItem(shortcutItem, completion: completionHandler)
    }
    
    private func updateDynamicIconShortcutItems() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem.wmf_random(),
            UIApplicationShortcutItem.wmf_nearby(),
            UIApplicationShortcutItem.wmf_search()
        ]
    }
    
    
    // MARK: Background Fetch
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let vc = appViewController else {
            return
        }
        vc.performBackgroundFetch(completion: completionHandler)
    }

    /// Cancels any pending background tasks, if applicable on the current platform
    private func cancelPendingBackgroundTasks() {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.cancelAllTaskRequests()
        }
    }
    
    /// Register for any necessary background tasks or updates with the method appropriate for the platform
    private func registerBackgroundTasksForApplication(_ application: UIApplication) {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundAppRefreshTaskIdentifier, using: DispatchQueue.main) { task in
                guard let vc = self.appViewController else {
                    return
                }
                vc.performBackgroundFetch { result in
                    switch result {
                    case UIBackgroundFetchResult.failed:
                        task.setTaskCompleted(success: false)
                        break
                    default:
                        task.setTaskCompleted(success: true)
                        break
                    }
                }
                self.scheduleBackgroundAppRefreshTask()
            }
        } else {
            application.setMinimumBackgroundFetchInterval(backgroundFetchInterval)
        }
    }
    
    /// Schedule the next background refresh, if applicable on the current platform
    private func scheduleBackgroundAppRefreshTask() {
        if #available(iOS 13.0, *) {
            let appRefreshTask = BGAppRefreshTaskRequest.init(identifier: backgroundAppRefreshTaskIdentifier)
            appRefreshTask.earliestBeginDate = Date(timeIntervalSinceNow: backgroundFetchInterval)
            do {
                try BGTaskScheduler.shared.submit(appRefreshTask)
            } catch {
                DDLogError("Unable to schedule background task: \(error)");
            }
        }
    }
    
}
