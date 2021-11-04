import Foundation

final class NotificationsCenterCellViewModel {

    // MARK: - Properties

    let notification: RemoteNotification
    let project: RemoteNotificationsProject
    private(set) var displayState: NotificationsCenterCellDisplayState = .defaultUnread

	// MARK: - Lifecycle

    init?(notification: RemoteNotification, languageLinkController: MWKLanguageLinkController) {
        
        //Validation - all notifications must have a recognized project for display (wikidata, commons, or app-supported language)
        guard let project = RemoteNotificationsProject(apiIdentifier: notification.wiki, languageLinkController: languageLinkController) else {
            return nil
        }
        
        self.notification = notification
        self.project = project
    }

    // MARK: - Public
    
    var notificationType: RemoteNotificationType? {
        return notification.type
    }
    
    func updateDisplayState(isEditing: Bool? = nil, isSelected: Bool) {
        
        //if isEditing = nil, base it on current display state
        let isInEditingMode: Bool
        if let isEditing = isEditing {
            isInEditingMode = isEditing
        } else {
            isInEditingMode = displayState.isEditing
        }
        
        switch (isInEditingMode, isSelected, notification.isRead) {
            case (false, _, true):
                displayState = .defaultRead
            case (false, _, false):
                displayState = .defaultUnread
            case (true, true, true):
                displayState = .editSelectedRead
            case (true, true, false):
                displayState = .editSelectedUnread
            case (true, false, true):
                displayState = .editUnselectedRead
            case (true, false, false):
                displayState = .editUnselectedUnread
        }
    }
    
}

extension NotificationsCenterCellViewModel: Equatable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(notification.key)
    }

    static func == (lhs: NotificationsCenterCellViewModel, rhs: NotificationsCenterCellViewModel) -> Bool {
        return lhs.notification.key == rhs.notification.key
    }
}
