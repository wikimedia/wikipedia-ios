
import UserNotifications
import WMF
import CocoaLumberjackSwift

//TODO: Implement a real language provider, which will involve sharing a cache of preferred languages with the main app
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
        
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }
        
        let defaultString = WMFLocalizedString("push-notifications-default-body", value: "New activity on Wikipedia", comment: "Generic body text for a new push notification whose details cannot be determined.")
        bestAttemptContent.body = defaultString
        self.bestAttemptContent = bestAttemptContent
        
        remoteNotificationsController.fetchNewPushNotifications {result in
            
            switch result {
            case .success(let newNotifications):
                
                switch newNotifications.count {
                case 1:
                    let newNotification = newNotifications.first!
                    bestAttemptContent.body = newNotification.pushContentString ?? defaultString
                    
                default:
                    bestAttemptContent.body = defaultString
                }
                
            case .failure(let error):
                bestAttemptContent.body = defaultString
                DDLogError("Failure fetching new push notifications: \(error).")
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        guard let contentHandler = contentHandler,
           let bestAttemptContent =  bestAttemptContent else {
            return
        }
        
        contentHandler(bestAttemptContent)
    }

}
