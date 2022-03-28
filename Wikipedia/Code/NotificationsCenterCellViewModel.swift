import Foundation

final class NotificationsCenterCellViewModel {

    // MARK: - Properties

    let notification: RemoteNotification
    let key: String
    let project: RemoteNotificationsProject
    private(set) var displayState: NotificationsCenterCellDisplayState
    let configuration: Configuration
    let commonViewModel: NotificationsCenterCommonViewModel

	// MARK: - Lifecycle

    init?(notification: RemoteNotification, languageLinkController: MWKLanguageLinkController, isEditing: Bool, configuration: Configuration) {
        
        //Validation - all notifications must have a recognized project for display (wikidata, commons, or app-supported language)
        guard let wiki = notification.wiki,
              let key = notification.key,
              let project = RemoteNotificationsProject(apiIdentifier: wiki, languageLinkController: languageLinkController) else {
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
        
        //preserve current values for isEditing and isSelected if not specified
        let newIsEditingState = isEditing ?? displayState.isEditing
        let newIsSelectedState = isSelected ?? displayState.isSelected
        
        self.displayState = Self.displayStateFor(isEditing: newIsEditingState, isSelected: newIsSelectedState, isRead: isRead)
        
    }
    
    var accessibilityText: NSAttributedString? {
        let readAccessibilityText = WMFLocalizedString("notifications-center-cell-read-accessibility-label", value: "Read", comment: "Accessibility text for indicating that a notification's contents have been read.")
        let unreadAccessibilityText = WMFLocalizedString("notifications-center-cell-unread-accessibility-label", value: "Unread", comment: "Accessibility text for indicating that a notification's contents have not been read.")
        let readPronounciationAccessibilityAttribute = WMFLocalizedString("notifications-center-cell-read-ipa-accessibility-attribute", value: "rɛd", comment: "Accessibility ipa pronounciation for indicating that a notification's contents have been read.")
        let unreadPronounciationAccessibilityAttribute = WMFLocalizedString("notifications-center-cell-unread-ipa-accessibility-attribute", value: "ʌnˈrɛd", comment: "Accessibility ipa pronounciation for indicating that a notification's contents have not been read.")
        let notificationAcessibilityText = WMFLocalizedString("notifications-center-cell-accessibility-label", value: "notification from", comment: "Acessibility text for the notifications center cell, indicates where the notification is from")
        let readAccessibilityAttributedString = NSAttributedString(string: readAccessibilityText, attributes: [NSAttributedString.Key.accessibilitySpeechIPANotation: readPronounciationAccessibilityAttribute])
        let unreadAccessibilityAttributedString = NSAttributedString(string: unreadAccessibilityText, attributes: [NSAttributedString.Key.accessibilitySpeechIPANotation: unreadPronounciationAccessibilityAttribute])
        let readUnreadAccessibilityAttributedString = isRead ? readAccessibilityAttributedString : unreadAccessibilityAttributedString
        
        let mutableAttributedString = NSMutableAttributedString(attributedString: readUnreadAccessibilityAttributedString)
        let accessibilityTextAttributedString = NSAttributedString(string: "\(notification.type.filterTitle ?? String()) \(notificationAcessibilityText) \(project.projectName(shouldReturnCodedFormat: false)). \(headerText ?? String()). ")
        
        mutableAttributedString.insert(accessibilityTextAttributedString, at: 0)
        
        return mutableAttributedString.copy() as? NSAttributedString
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
