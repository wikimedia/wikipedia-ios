import UIKit

/**
 *  Mock application delegate for use in unit testing. This is used for 2 reasons:
 *
 *  1. Visual tests require that the application has a @c keyWindow, and we don't pass the regular application delegate to
 *  prevent unintended side effects from regular application code when testing.
 *
 *  2. Stubbed networking tests can fail if unexpected network operations are triggered by the application.
 */
class MockAppDelegate: UIResponder, UIApplicationDelegate {
    
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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
        return true
    }
    
}
