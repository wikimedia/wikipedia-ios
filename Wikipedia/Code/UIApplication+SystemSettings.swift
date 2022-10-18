import Foundation

extension UIApplication {
    
    @objc func wmf_openAppSpecificSystemSettings() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier, let settingsURL = URL(string: UIApplication.openSettingsURLString + bundleIdentifier) else {
            return
        }
        self.open(settingsURL as URL, options: [:], completionHandler: nil)
    }

    @objc func wmf_openGeneralSystemSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        self.open(settingsURL as URL, options: [:], completionHandler: nil)
    }

}
