
import UserNotifications
import WMF

class FakeLangProvider: WMFPreferredLanguageInfoProvider {
    func getPreferredContentLanguageCodes(_ completion: @escaping ([String]) -> Void) {
        completion(["en"])
    }

    func getPreferredLanguageCodes(_ completion: @escaping ([String]) -> Void) {
        completion(["en"])
    }


}

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    lazy var remoteNotificationsController: RemoteNotificationsController = {
        let configuration = Configuration.current
        let session = Session(configuration: configuration)
        let fakeProvider = FakeLangProvider()
        let controller = RemoteNotificationsController(session: session, configuration: configuration, preferredLanguageCodesProvider: fakeProvider)
        return controller
    }()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...

            remoteNotificationsController.fetchFirstPageNotifications {
                bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
