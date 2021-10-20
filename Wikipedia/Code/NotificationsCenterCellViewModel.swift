import Foundation

final class NotificationsCenterCellViewModel {

    // MARK: - Properties

    let notification: RemoteNotification
    let project: RemoteNotificationsProject
    var displayState: NotificationsCenterCellDisplayState

	// MARK: - Lifecycle

    init?(notification: RemoteNotification, displayState: NotificationsCenterCellDisplayState = .defaultUnread, languageLinkController: MWKLanguageLinkController, editMode: Bool) {
        
        //Validation - all notifications must have a recognized project for display (wikidata, commons, or app-supported language)
        guard let project = RemoteNotificationsProject(apiIdentifier: notification.wiki, languageLinkController: languageLinkController) else {
            return nil
        }
        
        self.notification = notification
        self.project = project
        self.displayState = Self.displayStateForNotification(notification, editMode: editMode)
    }

    // MARK: - Public

    var isRead: Bool {
        return notification.isRead
    }
    
    var notificationType: RemoteNotificationType? {
        return notification.type
    }
    
    func copyAnyValuableNewDataFromNotification(_ notification: RemoteNotification, editMode: Bool) {
        
        //preserve selected state, unless params indicate edit mode has switched
        if (self.displayState.isEditing && editMode == false) ||
            (editMode == true && !self.displayState.isEditing) {
            self.displayState = Self.displayStateForNotification(notification, editMode: editMode)
        }
        
        //if read flag has flipped, update display state to reflect what it should be.
        switch (self.displayState, self.isRead) {
        case (.defaultRead, false):
            self.displayState = .defaultUnread
        case (.defaultUnread, true):
            self.displayState = .defaultRead
        case (.editSelectedRead, false):
            self.displayState = .editSelectedUnread
        case (.editSelectedUnread, true):
            self.displayState = .editSelectedRead
        case (.editUnselectedRead, false):
            self.displayState = .editUnselectedUnread
        case (.editUnselectedUnread, true):
            self.displayState = .editUnselectedRead
        default:
            break
        }
    }
    
    func toggleCheckedStatus() {
        switch self.displayState {
        case .defaultUnread,
             .defaultRead:
            assertionFailure("This method shouldn't be called while in default state.")
            return
        case .editSelectedRead:
            self.displayState = .editUnselectedRead
        case .editSelectedUnread:
            self.displayState = .editUnselectedUnread
        case .editUnselectedUnread:
            self.displayState = .editSelectedUnread
        case .editUnselectedRead:
            self.displayState = .editSelectedRead
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
