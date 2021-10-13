import Foundation

final class NotificationsCenterCellViewModel {
    
    struct Text {
        let header: String
        let subheader: String?
        let body: String?
        let footer: String?
        let date: String?
        let project: String? //nil if it's a commons or wikidata project type
    }

	// MARK: - Properties

	let notification: RemoteNotification
    let project: RemoteNotificationsProject
	var displayState: NotificationsCenterCellDisplayState
    let text: Text

	// MARK: - Lifecycle

    init?(notification: RemoteNotification, displayState: NotificationsCenterCellDisplayState = .defaultUnread, languageLinkController: MWKLanguageLinkController) {
        
        //Validation - all notifications must have a recognized project for display (wikidata, commons, or app-supported language)
        guard let project = RemoteNotificationsProject(apiIdentifier: notification.wiki, languageLinkController: languageLinkController) else {
            return nil
        }
        
		self.notification = notification
        self.project = project
		self.displayState = displayState
        
        self.text = Text(project: project, notification: notification)
	}

	// MARK: - Public

	var isRead: Bool {
		return notification.isRead
	}
    
    var notificationType: RemoteNotificationType? {
        return notification.type
    }
}
