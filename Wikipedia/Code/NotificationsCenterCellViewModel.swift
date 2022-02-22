import Foundation

final class NotificationsCenterCellViewModel {

    // MARK: - Properties

    let notification: RemoteNotification
    let key: String
    let project: RemoteNotificationsProject
    private(set) var displayState: NotificationsCenterCellDisplayState

	// MARK: - Lifecycle

    init?(notification: RemoteNotification, languageLinkController: MWKLanguageLinkController, isEditing: Bool) {
        
        //Validation - all notifications must have a recognized project for display (wikidata, commons, or app-supported language)
        guard let wiki = notification.wiki,
              let key = notification.key,
              let project = RemoteNotificationsProject(apiIdentifier: wiki, languageLinkController: languageLinkController) else {
            return nil
        }
        
        self.notification = notification
        self.key = key
        self.project = project
        
        self.displayState = Self.displayStateFor(isEditing: isEditing, isSelected: false, isRead: notification.isRead)
    }

    // MARK: - Public
    
    var notificationType: RemoteNotificationType? {
        return notification.type
    }
    
    var isRead: Bool {
        return notification.isRead
    }
    
    func updateDisplayState(isEditing: Bool? = nil, isSelected: Bool? = nil) {
        
        //preserve current values for isEditing and isSelected if not specified
        let newIsEditingState = isEditing ?? displayState.isEditing
        let newIsSelectedState = isSelected ?? displayState.isSelected
        
        self.displayState = Self.displayStateFor(isEditing: newIsEditingState, isSelected: newIsSelectedState, isRead: isRead)
        
    }
    
    static func displayStateFor(isEditing: Bool, isSelected: Bool, isRead: Bool) -> NotificationsCenterCellDisplayState {

        switch (isEditing, isSelected, isRead) {
            case (false, _, true):
                return .defaultRead
            case (false, _, false):
                return .defaultUnread
            case (true, true, true):
                return .editSelectedRead
            case (true, true, false):
                return .editSelectedUnread
            case (true, false, true):
                return .editUnselectedRead
            case (true, false, false):
                return .editUnselectedUnread
        }
    }
    
}

extension NotificationsCenterCellViewModel: Equatable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    static func == (lhs: NotificationsCenterCellViewModel, rhs: NotificationsCenterCellViewModel) -> Bool {
        return lhs.key == rhs.key
    }
}
