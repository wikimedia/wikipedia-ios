import Foundation

extension Notification.Name {
    static let pushNotificationBannerDidDisplayInForeground = Notification.Name("WMFPushNotificationBannerDidDisplayInForeground")
}

@objc extension NSNotification {
    public static let pushNotificationBannerDidDisplayInForeground = Notification.Name.pushNotificationBannerDidDisplayInForeground
}
