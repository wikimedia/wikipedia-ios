import UIKit
import BackgroundTasks
import CocoaLumberjackSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        registerUserDefaults()
        
#if DEBUG
        print("\nSimulator container directory:\n\t\(FileManager.default.wmf_containerPath())\n")
#endif
        UserDefaults.standard.wmf_migrateFontSizeMultiplier()
        UserDefaults.standard.shouldRestoreNavigationStackOnResume = shouldRestoreNavigationStackOnResumeAfterBecomingActive()
        
        UIApplication.shared.registerForRemoteNotifications()
        
        updateDynamicIconShortcutItems()
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        updateDynamicIconShortcutItems()
    }
    
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return true
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
    
    
    // MARK: Notifications
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        DDLogError("Remote notification registration failure: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        appViewController?.setRemoteNotificationRegistrationStatusWithDeviceToken(deviceToken, error: nil)
    }

    // MARK: Private
    
    private var appViewController: WMFAppViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first,
           let sceneDelegate = (scene.delegate as? SceneDelegate) else {
            return nil
        }
        
        return sceneDelegate.appViewController
    }
    
    private func registerUserDefaults() {
        UserDefaults.standard.register(defaults: ["WMFAutoSignTalkPageDiscussions": true])
    }
    
    private func shouldRestoreNavigationStackOnResumeAfterBecomingActive() -> Bool {
        let shouldOpenAppOnSearchTab = UserDefaults.standard.wmf_openAppOnSearchTab
        return !shouldOpenAppOnSearchTab
    }
}
