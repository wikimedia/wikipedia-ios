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


        // Background launches can run refresh tasks before setupWMFDataEnvironment() finishes, so configure the
        // shared cache store up front. Local notification logging depends on it during background refresh.
        if WMFDeveloperSettingsDataController.enableDailyTopReadNotifications,
           WMFDataEnvironment.current.sharedCacheStore == nil {
            WMFDataEnvironment.current.sharedCacheStore = SharedContainerCacheStore()
        }
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

    /// Background app refresh with the daily top read notification prototype enabled. Local notifications are only
    /// scheduled from here, to re-engage users who haven't opened the app.
    private func performBackgroundAppRefreshWithLocalNotifications(task: BGTask) {
        let completion = BackgroundAppRefreshCompletion(task: task) { [weak self] in
            self?.scheduleBackgroundAppRefreshTask()
        }

        let work = Task { @MainActor in
            async let localNotifications: Void = self.appViewController.performLocalNotificationsBackgroundRefresh()
            let result = await withCheckedContinuation { continuation in
                self.appViewController.performBackgroundFetch { result in
                    continuation.resume(returning: result)
                }
            }
            await localNotifications
            completion.complete(success: result != .failed)
        }

        // Completes the task before iOS terminates the app if the fetches run past the background time budget.
        task.expirationHandler = {
            work.cancel()
            Task { @MainActor in
                completion.complete(success: false)
            }
        }
    }

    private func registerBackgroundTasks() {

        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.backgroundAppRefreshTaskIdentifier, using: .main) { [weak self] task in
            guard WMFDeveloperSettingsDataController.enableDailyTopReadNotifications else {
                self?.appViewController.performBackgroundFetch { [weak self] result in
                    switch result {
                    case .failed:
                        task.setTaskCompleted(success: false)
                    default:
                        task.setTaskCompleted(success: true)
                    }

                    self?.scheduleBackgroundAppRefreshTask()
                }
                return
            }

            guard let self else {
                task.setTaskCompleted(success: false)
                return
            }
            self.performBackgroundAppRefreshWithLocalNotifications(task: task)
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

/// Completes a background task exactly once, whether its work finishes or its time expires first.
@MainActor
private final class BackgroundAppRefreshCompletion {
    private let task: BGTask
    private let didComplete: @MainActor () -> Void
    private var isCompleted = false

    init(task: BGTask, didComplete: @escaping @MainActor () -> Void) {
        self.task = task
        self.didComplete = didComplete
    }

    func complete(success: Bool) {
        guard !isCompleted else { return }
        isCompleted = true
        task.setTaskCompleted(success: success)
        didComplete()
    }
}
#endif
