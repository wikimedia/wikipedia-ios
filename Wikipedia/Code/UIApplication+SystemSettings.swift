import Foundation

extension UIApplication {
    
    func wmf_openAppSpecificSystemSettings() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier, let settingsURL = URL(string: UIApplicationOpenSettingsURLString + bundleIdentifier) else {
            return
        }
        self.openURL(settingsURL as URL)
    }
}
