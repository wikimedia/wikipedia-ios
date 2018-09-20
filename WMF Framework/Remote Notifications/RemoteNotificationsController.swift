// @objc facing object that facilitates communication between RemoteNotificationsFetcher and RemoteNotificationsModelController.
@objc public final class RemoteNotificationsController: NSObject {
    let modelController: RemoteNotificationsModelController?
    let fetcher: RemoteNotificationsFetcher

    public override init() {
        modelController = RemoteNotificationsModelController()
        fetcher = RemoteNotificationsFetcher()
        super.init()
    }

    public func getAllNotifications() {
        //fetcher.request(Query.allNotifications)
    }

    public func getAllUnreadNotifications() {
        //fetcher.request(Query.allUnreadNotifications)
    }
}
