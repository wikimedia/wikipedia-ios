import UIKit
import BackgroundTasks
import CocoaLumberjackSwift

#if TEST
// Avoids loading needless dependencies during unit tests
@main
class MockAppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}

#else

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private static let backgroundFetchInterval = TimeInterval(10800) // 3 Hours
    private static let backgroundAppRefreshTaskIdentifier = "org.wikimedia.wikipedia.appRefresh"
    private static let backgroundDatabaseHousekeeperTaskIdentifier = "org.wikimedia.wikipedia.databaseHousekeeper"
    
    // TODO: Refactor background task refresh and notification token registration logic out of WMFAppViewController. Then we can then move tab bar instantiation into SceneDelegate.
    let appViewController = WMFAppViewController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        registerUserDefaults()
        
#if DEBUG
        print("\nSimulator container directory:\n\t\(FileManager.default.wmf_containerPath())\n")
#endif
        UserDefaults.standard.wmf_migrateFontSizeMultiplier()
        UserDefaults.standard.shouldRestoreNavigationStackOnResume = shouldRestoreNavigationStackOnResumeAfterBecomingActive()
        
        UIApplication.shared.registerForRemoteNotifications()
        
        updateDynamicIconShortcutItems()
        registerBackgroundTasks()
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        updateDynamicIconShortcutItems()
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

    }
    
    // MARK: Public
    
    func updateDynamicIconShortcutItems() {
        UIApplication.shared.shortcutItems = [UIApplicationShortcutItem.wmf_random(), UIApplicationShortcutItem.wmf_nearby(), UIApplicationShortcutItem.wmf_search()]
    }
    
    func scheduleBackgroundAppRefreshTask() {
        let appRefreshTask = BGAppRefreshTaskRequest(identifier: Self.backgroundAppRefreshTaskIdentifier)
        appRefreshTask.earliestBeginDate = Date(timeIntervalSinceNow: Self.backgroundFetchInterval)
        do {
            try BGTaskScheduler.shared.submit(appRefreshTask)
        } catch {
            DDLogError("Unable to schedule background task: \(error)")
        }
    }
    
    func scheduleDatabaseHousekeeperTask() {
        let databaseHousekeeperTask = BGAppRefreshTaskRequest(identifier: Self.backgroundDatabaseHousekeeperTaskIdentifier)
        databaseHousekeeperTask.earliestBeginDate = nil // Docs indicate nil = no start delay.
        do {
            try BGTaskScheduler.shared.submit(databaseHousekeeperTask)
        } catch {
            DDLogError("Unable to schedule background task: \(error)")
        }
    }

    func cancelPendingBackgroundTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    // MARK: Notifications
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        DDLogError("Remote notification registration failure: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        appViewController.setRemoteNotificationRegistrationStatusWithDeviceToken(deviceToken, error: nil)
    }

    // MARK: Private
    
    private func registerUserDefaults() {
        UserDefaults.standard.register(defaults: ["WMFAutoSignTalkPageDiscussions": true])
    }
    
    private func shouldRestoreNavigationStackOnResumeAfterBecomingActive() -> Bool {
        let shouldOpenAppOnSearchTab = UserDefaults.standard.wmf_openAppOnSearchTab
        return !shouldOpenAppOnSearchTab
    }
    
    private func registerBackgroundTasks() {

        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.backgroundAppRefreshTaskIdentifier, using: .main) { [weak self] task in
            self?.appViewController.performBackgroundFetch { [weak self] result in
                switch result {
                case .failed:
                    task.setTaskCompleted(success: false)
                default:
                    task.setTaskCompleted(success: true)
                }
                
                self?.scheduleBackgroundAppRefreshTask()
            }
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.backgroundDatabaseHousekeeperTaskIdentifier, using: .main) { [weak self] task in
            self?.appViewController.performDatabaseHousekeeping { error in
                
                if error != nil {
                    task.setTaskCompleted(success: false)
                } else {
                    task.setTaskCompleted(success: true)
                }
            }
        }
    }
}
#endif
