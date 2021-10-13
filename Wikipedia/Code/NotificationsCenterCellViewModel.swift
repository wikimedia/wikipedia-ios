import Foundation

final class NotificationsCenterCellViewModel {

    // MARK: - Properties

    let notification: RemoteNotification
    let project: RemoteNotificationsProject
    var displayState: NotificationsCenterCellDisplayState

	// MARK: - Lifecycle

    init?(notification: RemoteNotification, displayState: NotificationsCenterCellDisplayState = .defaultUnread, languageLinkController: MWKLanguageLinkController) {
        
        //Validation - all notifications must have a recognized project for display (wikidata, commons, or app-supported language)
        guard let project = RemoteNotificationsProject(apiIdentifier: notification.wiki, languageLinkController: languageLinkController) else {
            return nil
        }
        
        self.notification = notification
        self.project = project
        self.displayState = displayState
    }

    // MARK: - Public

    var isRead: Bool {
        return notification.isRead
    }
    
    var notificationType: RemoteNotificationType? {
        return notification.type
    }
}
