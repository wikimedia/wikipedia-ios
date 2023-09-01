import Foundation

extension Notification.Name {
    static let pushNotificationBannerDidDisplayInForeground = Notification.Name("WMFPushNotificationBannerDidDisplayInForeground")
    static let databaseHousekeeperDidComplete = Notification.Name("WMFDatabaseHousekeeperDidComplete")
}

@objc extension NSNotification {
    public static let pushNotificationBannerDidDisplayInForeground = Notification.Name.pushNotificationBannerDidDisplayInForeground
    public static let databaseHousekeeperDidComplete = Notification.Name.databaseHousekeeperDidComplete
}
