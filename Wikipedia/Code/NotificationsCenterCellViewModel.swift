import Foundation

final class NotificationsCenterCellViewModel {

    // MARK: - Properties

    let notification: RemoteNotification
    let project: RemoteNotificationsProject
    var displayState: NotificationsCenterCellDisplayState

	// MARK: - Lifecycle

    init?(notification: RemoteNotification, languageLinkController: MWKLanguageLinkController, editMode: Bool) {
        
        //Validation - all notifications must have a recognized project for display (wikidata, commons, or app-supported language)
        guard let project = RemoteNotificationsProject(apiIdentifier: notification.wiki, languageLinkController: languageLinkController) else {
            return nil
        }
        
        self.notification = notification
        self.project = project
        self.displayState = Self.displayStateForNotification(notification, editMode: editMode)
    }

    // MARK: - Public
    
    var notificationType: RemoteNotificationType? {
        return notification.type
    }
    
    func updateDisplayState(editMode: Bool) {
        
        //preserve selected state, unless params indicate edit mode has switched
        if (displayState.isEditing && editMode == false) ||
            (editMode == true && !displayState.isEditing) {
            displayState = Self.displayStateForNotification(notification, editMode: editMode)
        }
        
        //if read flag has flipped, update display state to reflect what it should be.
        switch (displayState, notification.isRead) {
        case (.defaultRead, false):
            displayState = .defaultUnread
        case (.defaultUnread, true):
            displayState = .defaultRead
        case (.editSelectedRead, false):
            displayState = .editSelectedUnread
        case (.editSelectedUnread, true):
            displayState = .editSelectedRead
        case (.editUnselectedRead, false):
            displayState = .editUnselectedUnread
        case (.editUnselectedUnread, true):
            displayState = .editUnselectedRead
        default:
            break
        }
    }
    
    func toggleCheckedStatus() {
        switch displayState {
        case .defaultUnread,
             .defaultRead:
            assertionFailure("This method shouldn't be called while in default state.")
            return
        case .editSelectedRead:
            displayState = .editUnselectedRead
        case .editSelectedUnread:
            displayState = .editUnselectedUnread
        case .editUnselectedUnread:
            displayState = .editSelectedUnread
        case .editUnselectedRead:
            displayState = .editSelectedRead
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

private extension NotificationsCenterCellViewModel {
    static func displayStateForNotification(_ notification: RemoteNotification, editMode: Bool) -> NotificationsCenterCellDisplayState {
        switch (editMode, notification.isRead) {
            case (false, true):
                return .defaultRead
            case (false, false):
                return .defaultUnread
            case (true, false):
                return .editUnselectedUnread
            case (true, true):
                return .editUnselectedRead
        }
    }
}
