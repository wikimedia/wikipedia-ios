import UIKit
import BackgroundTasks
import CocoaLumberjackSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    private static let backgroundFetchInterval = TimeInterval(10800) // 3 Hours
    private static let backgroundAppRefreshTaskIdentifier = "org.wikimedia.wikipedia.appRefresh"
    private static let backgroundDatabaseHousekeeperTaskIdentifier = "org.wikimedia.wikipedia.databaseHousekeeper"

    var window: UIWindow?
    private(set) var appViewController: WMFAppViewController?
    private var appNeedsResume = true

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        let appViewController = WMFAppViewController()
        UNUserNotificationCenter.current().delegate = appViewController
        appViewController.launchApp(in: window, waitToResumeApp: appNeedsResume)
        self.appViewController = appViewController
        
        registerBackgroundTasks()
    }

    func sceneDidDisconnect(_ scene: UIScene) {

    }

    func sceneDidBecomeActive(_ scene: UIScene) {

        resumeAppIfNecessary()
    }

    func sceneWillResignActive(_ scene: UIScene) {

        UserDefaults.standard.wmf_setAppResignActiveDate(Date())
    }

    func sceneWillEnterForeground(_ scene: UIScene) {

        cancelPendingBackgroundTasks()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {

        appDelegate?.updateDynamicIconShortcutItems()
        scheduleBackgroundAppRefreshTask()
        scheduleDatabaseHousekeeperTask()
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        appViewController?.processShortcutItem(shortcutItem, completion: completionHandler)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let appViewController else {
            return
        }
        
        appViewController.showSplashView()
        var userInfo = userActivity.userInfo
        userInfo?[WMFRoutingUserInfoKeys.source] = WMFRoutingUserInfoSourceValue.deepLinkRawValue
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
        
        guard let appViewController else {
            return
        }
        
        guard let firstURL = URLContexts.first?.url else {
            return
        }
        
        guard let activity = NSUserActivity.wmf_activity(forWikipediaScheme: firstURL) ?? NSUserActivity.wmf_activity(for: firstURL) else {
            resumeAppIfNecessary()
            return
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
    }

    // MARK: Private
    
    private var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    private func resumeAppIfNecessary() {
        if appNeedsResume {
            appViewController?.hideSplashScreenAndResumeApp()
            appNeedsResume = false
        }
    }
    
    private func registerBackgroundTasks() {
        
        guard let appViewController else {
            return
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.backgroundAppRefreshTaskIdentifier, using: .main) { [weak self] task in
            appViewController.performBackgroundFetch { [weak self] result in
                switch result {
                case .failed:
                    task.setTaskCompleted(success: false)
                default:
                    task.setTaskCompleted(success: true)
                }
                
                self?.scheduleBackgroundAppRefreshTask()
            }
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.backgroundDatabaseHousekeeperTaskIdentifier, using: .main) {task in
            appViewController.performDatabaseHousekeeping { error in
                
                if error != nil {
                    task.setTaskCompleted(success: false)
                } else {
                    task.setTaskCompleted(success: true)
                }
            }
        }
    }
    
    private func scheduleBackgroundAppRefreshTask() {
        let appRefreshTask = BGAppRefreshTaskRequest(identifier: Self.backgroundAppRefreshTaskIdentifier)
        appRefreshTask.earliestBeginDate = Date(timeIntervalSinceNow: Self.backgroundFetchInterval)
        do {
            try BGTaskScheduler.shared.submit(appRefreshTask)
        } catch {
            DDLogError("Unable to schedule background task: \(error)")
        }
    }
    
    private func scheduleDatabaseHousekeeperTask() {
        let databaseHousekeeperTask = BGAppRefreshTaskRequest(identifier: Self.backgroundDatabaseHousekeeperTaskIdentifier)
        databaseHousekeeperTask.earliestBeginDate = nil // Docs indicate nil = no start delay.
        do {
            try BGTaskScheduler.shared.submit(databaseHousekeeperTask)
        } catch {
            DDLogError("Unable to schedule background task: \(error)")
        }
    }

    private func cancelPendingBackgroundTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
}
