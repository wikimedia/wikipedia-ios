import Foundation

final class NotificationsCenterCellViewModel {

    // MARK: - Properties

    let notification: RemoteNotification
    let key: String
    let project: WikimediaProject
    private(set) var displayState: NotificationsCenterCellDisplayState
    let configuration: Configuration
    let commonViewModel: NotificationsCenterCommonViewModel

	// MARK: - Lifecycle

    init?(notification: RemoteNotification, languageLinkController: MWKLanguageLinkController, isEditing: Bool, configuration: Configuration) {
        
        // Validation - all notifications must have a recognized project for display (wikidata, commons, or app-supported language)
        guard let wiki = notification.wiki,
              let key = notification.key,
              let project = WikimediaProject(notificationsApiIdentifier: wiki, languageLinkController: languageLinkController) else {
            return nil
        }
        
        self.notification = notification
        self.key = key
        self.project = project
        self.configuration = configuration
        
        self.commonViewModel = NotificationsCenterCommonViewModel(configuration: configuration, notification: notification, project: project)
        
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
        
        // preserve current values for isEditing and isSelected if not specified
        let newIsEditingState = isEditing ?? displayState.isEditing
        let newIsSelectedState = isSelected ?? displayState.isSelected
        
        self.displayState = Self.displayStateFor(isEditing: newIsEditingState, isSelected: newIsSelectedState, isRead: isRead)
        
    }
    
    var accessibilityText: String? {
        let readAccessibilityText = CommonStrings.readStatusAccessibilityLabel
        let unreadAccessibilityText = CommonStrings.unreadStatusAccessibilityLabel
        let readStatus = isRead ? readAccessibilityText : unreadAccessibilityText

        let notificationFormat = WMFLocalizedString("notifications-center-cell-notification-type-accessibility-label-format", value: "%1$@ notification", comment: "Accessibility label for Notifications Center cell's notification text. %1$@ is replaced with a description of the type of notification, which may be a single noun (e.g. Thanks, Welcome) or a short phrase (e.g. Talk page message, Edit milestone). The first letter should be capitalized.")
        let notificationTypeTitle = notification.type.title
        let notificationString = String.localizedStringWithFormat(notificationFormat, notificationTypeTitle)
        let projectName = project.projectName(shouldReturnCodedFormat: false)
        let messageContent = headerText
        let accessibilityLabel = "\(notificationString).  \(projectName). \(messageContent ?? String()). \(readStatus)"
        return accessibilityLabel
        
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
