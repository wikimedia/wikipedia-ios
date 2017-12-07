import Foundation

extension UIApplication {
    
    @objc func wmf_openAppSpecificSystemSettings() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier, let settingsURL = URL(string: UIApplicationOpenSettingsURLString + bundleIdentifier) else {
            return
        }
        self.open(settingsURL as URL, options: [:], completionHandler: nil)
    }
}
