import Foundation

extension NSUserActivity {
    static func wikipediaActivity(with url: URL) throws -> NSUserActivity {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = url
        return activity
    }
}

@objc extension UIViewController {
    @objc(wmf_navigateToActivityWithURL:)
    public func navigateToActivity(with url: URL) {
        do {
            let activity = try NSUserActivity.wikipediaActivity(with: url)
            NotificationCenter.default.post(name: .WMFNavigateToActivity, object: activity)
        } catch let error {
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: false, dismissPreviousAlerts: false)
        }
    }
}

