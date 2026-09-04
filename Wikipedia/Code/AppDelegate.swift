import UIKit
import WMFData
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
        let databaseHousekeeperTask = BGProcessingTaskRequest(identifier: Self.backgroundDatabaseHousekeeperTaskIdentifier)
        databaseHousekeeperTask.earliestBeginDate = nil // Docs indicate nil = no start delay.
        databaseHousekeeperTask.requiresNetworkConnectivity = false
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
        #if DEBUG
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        debugPrint("Device Token: \(token)")
        #endif
        appViewController.setRemoteNotificationRegistrationStatus(deviceToken: deviceToken, error: nil)
    }

    // MARK: Private

    private func registerUserDefaults() {
        let storedData = UserDefaults.standard.object(forKey: WMFUserDefaultsKey.autoSignTalkPageDiscussions.rawValue)
        if storedData == nil {
            WMFSettingsDataController.shared.setAutoSignTalkPageDiscussions(true)
        }
    }

    private func shouldRestoreNavigationStackOnResumeAfterBecomingActive() -> Bool {
        // Read from WMFData store (migrated key)
        let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
        let shouldOpenAppOnSearchTab: Bool = (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.openAppOnSearchTab.rawValue)) ?? false
        return !shouldOpenAppOnSearchTab
    }

    private func registerBackgroundTasks() {

        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.backgroundAppRefreshTaskIdentifier, using: .main) { [weak self] task in
            let completion = BackgroundTaskCompletion(task: task)

            // iOS stops the app if the task uses all of its time and reports no completion.
            task.expirationHandler = {
                completion.complete(success: false)
            }

            self?.appViewController.performBackgroundFetch { [weak self] result in
                completion.complete(success: result != .failed)
                self?.scheduleBackgroundAppRefreshTask()
            }
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.backgroundDatabaseHousekeeperTaskIdentifier, using: .main) { [weak self] task in
            let completion = BackgroundTaskCompletion(task: task)

            // iOS stops the app if the task uses all of its time and reports no completion.
            task.expirationHandler = { [weak self] in
                self?.appViewController.cancelDatabaseHousekeeping()
                completion.complete(success: false)
            }

            self?.appViewController.performDatabaseHousekeeping { error in
                completion.complete(success: error == nil)
            }
        }
    }
}

/// Reports the completion of a background task one time only.
///
/// iOS stops the app if the code reports completion two times. Both the expiration handler
/// and the work of the task can report completion, thus the code must count the reports.
/// The task uses the main queue, therefore this class needs no lock.
private final class BackgroundTaskCompletion {
    private let task: BGTask
    private var isComplete = false

    init(task: BGTask) {
        self.task = task
    }

    func complete(success: Bool) {
        guard !isComplete else {
            return
        }
        isComplete = true
        task.setTaskCompleted(success: success)
    }
}
#endif
