import Foundation
import WMF

extension NotificationsCenterCellViewModel {
    
    var sheetActions: [NotificationsCenterAction] {
        
        var sheetActions: [NotificationsCenterAction] = []
        let markAsReadText = CommonStrings.notificationsCenterMarkAsReadSwipe
        let markAsUnreadText = CommonStrings.notificationsCenterMarkAsUnreadSwipe
        let markAsReadOrUnreadText = isRead ? markAsUnreadText : markAsReadText
        let markAsReadOrUnreadAction: NotificationsCenterActionData.LoggingLabel = isRead ? .markUnread : .markRead
        let markAsReadOrUnreadActionData = NotificationsCenterActionData(text: markAsReadOrUnreadText, url: nil, iconType: nil, destinationText: nil, actionType: markAsReadOrUnreadAction)
        sheetActions.append(.markAsReadOrUnread(markAsReadOrUnreadActionData))
        
        switch notification.type {
        case .userTalkPageMessage:
            sheetActions.append(contentsOf: userTalkPageActions)
        case .mentionInTalkPage:
            sheetActions.append(contentsOf: mentionInTalkPageActions)
        case .editReverted:
            sheetActions.append(contentsOf: editRevertedActions)
        case .mentionInEditSummary:
            sheetActions.append(contentsOf: mentionInEditSummaryActions)
        case .successfulMention,
             .failedMention:
            sheetActions.append(contentsOf: successfulAndFailedMentionActions)
        case .userRightsChange:
            sheetActions.append(contentsOf: userGroupRightsActions)
        case .pageReviewed:
            sheetActions.append(contentsOf: pageReviewedActions)
        case .pageLinked:
            sheetActions.append(contentsOf: pageLinkActions)
        case .connectionWithWikidata:
            sheetActions.append(contentsOf: connectionWithWikidataActions)
        case .emailFromOtherUser:
            sheetActions.append(contentsOf: emailFromOtherUserActions)
        case .thanks:
            sheetActions.append(contentsOf: thanksActions)
        case .translationMilestone,
             .editMilestone,
             .welcome:
            break
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice:
            sheetActions.append(contentsOf: loginActions)

        case .unknownAlert,
             .unknownSystemAlert:
            sheetActions.append(contentsOf: genericAlertActions)

        case .unknownSystemNotice,
             .unknownNotice,
             .unknown:
            sheetActions.append(contentsOf: genericActions)

        }
        
        let notificationSubscriptionSettingsText = WMFLocalizedString("notifications-center-notifications-settings", value: "Notification settings", comment: "Button text in Notifications Center that automatically routes to the notifications settings screen.")
        let notificationSettingsActionData = NotificationsCenterActionData(text: notificationSubscriptionSettingsText, url: nil, iconType: nil, destinationText: nil, actionType: .settings)
        sheetActions.append(.notificationSubscriptionSettings(notificationSettingsActionData))
        
        return NSOrderedSet(array: sheetActions).compactMap { $0 as? NotificationsCenterAction }
    }
}

// MARK: Private Helpers - Aggregate Swipe Action methods

private extension NotificationsCenterCellViewModel {
    var userTalkPageActions: [NotificationsCenterAction] {
        var sheetActions: [NotificationsCenterAction] = []

        if let talkPageAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: false) {
            sheetActions.append(talkPageAction)
        }

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            sheetActions.append(agentUserPageAction)
        }

        if let diffAction = commonViewModel.diffAction {
            sheetActions.append(diffAction)
        }

        return sheetActions
    }

    var mentionInTalkPageActions: [NotificationsCenterAction] {
        var sheetActions: [NotificationsCenterAction] = []

        if let titleTalkPageAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: false) {
            sheetActions.append(titleTalkPageAction)
        }

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            sheetActions.append(agentUserPageAction)
        }

        if let diffAction = commonViewModel.diffAction {
            sheetActions.append(diffAction)
        }

        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: true, simplified: false) {
            sheetActions.append(titleAction)
        }

        return sheetActions
    }
    
    var editRevertedActions: [NotificationsCenterAction] {
        var sheetActions: [NotificationsCenterAction] = []

        if let diffAction = commonViewModel.diffAction {
            sheetActions.append(diffAction)
        }

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            sheetActions.append(agentUserPageAction)
        }

        if let titleTalkPageAction = commonViewModel.titleAction(needsConvertToOrFromTalk: true, simplified: false) {
            sheetActions.append(titleTalkPageAction)
        }

        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: false) {
            sheetActions.append(titleAction)
        }

        return sheetActions
    }

    var mentionInEditSummaryActions: [NotificationsCenterAction] {
        var sheetActions: [NotificationsCenterAction] = []

        if let diffAction = commonViewModel.diffAction {
            sheetActions.append(diffAction)
        }

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            sheetActions.append(agentUserPageAction)
        }

        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: false) {
            sheetActions.append(titleAction)
        }

        return sheetActions
    }

    var successfulAndFailedMentionActions: [NotificationsCenterAction] {
        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: false) {
            return [titleAction]
        }

        return []
    }

    var userGroupRightsActions: [NotificationsCenterAction] {
        var sheetActions: [NotificationsCenterAction] = []

        if let userGroupRightsAction = commonViewModel.userGroupRightsAction {
            sheetActions.append(userGroupRightsAction)
        }

        if let specificUserGroupRightsAction = commonViewModel.specificUserGroupRightsAction {
            sheetActions.append(specificUserGroupRightsAction)
        }

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            sheetActions.append(agentUserPageAction)
        }

        return sheetActions
    }

    var pageReviewedActions: [NotificationsCenterAction] {
        var sheetActions: [NotificationsCenterAction] = []

        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: false) {
            sheetActions.append(titleAction)
        }

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            sheetActions.append(agentUserPageAction)
        }

        return sheetActions
    }

    var pageLinkActions: [NotificationsCenterAction] {
        var sheetActions: [NotificationsCenterAction] = []

        // Article where link was made
        if let pageLinkFromAction = commonViewModel.pageLinkFromAction {
            sheetActions.append(pageLinkFromAction)
        }

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            sheetActions.append(agentUserPageAction)
        }

        // Article you edited
        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: false) {
            sheetActions.append(titleAction)
        }

        if let diffAction = commonViewModel.diffAction {
            sheetActions.append(diffAction)
        }

        return sheetActions
    }

    var connectionWithWikidataActions: [NotificationsCenterAction] {
        var sheetActions: [NotificationsCenterAction] = []

        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: false) {
            sheetActions.append(titleAction)
        }

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            sheetActions.append(agentUserPageAction)
        }

        if let wikidataItemAction = commonViewModel.wikidataItemAction {
            sheetActions.append(wikidataItemAction)
        }

        return sheetActions
    }

    var emailFromOtherUserActions: [NotificationsCenterAction] {
        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            return [agentUserPageAction]
        }

        return []
    }

    var thanksActions: [NotificationsCenterAction] {
        var sheetActions: [NotificationsCenterAction] = []

        if let diffAction = commonViewModel.diffAction {
            sheetActions.append(diffAction)
        }

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            sheetActions.append(agentUserPageAction)
        }

        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: false) {
            sheetActions.append(titleAction)
        }

        return sheetActions
    }

    var loginActions: [NotificationsCenterAction] {
        var sheetActions: [NotificationsCenterAction] = []

        if let changePasswordSheetAction = commonViewModel.changePasswordAction {
            sheetActions.append(changePasswordSheetAction)
        }

        if let loginHelpAction = commonViewModel.loginNotificationsAction {
            sheetActions.append(loginHelpAction)
        }

        return sheetActions
    }

    var genericAlertActions: [NotificationsCenterAction] {
        var sheetActions: [NotificationsCenterAction] = []

        if let primaryLink = notification.primaryLink,
           let primarySheetAction = commonViewModel.actionForGenericLink(link: primaryLink) {
            sheetActions.append(primarySheetAction)
        }

        if let secondaryLinks = notification.secondaryLinks {
            let secondarySheetActions = secondaryLinks.compactMap { commonViewModel.actionForGenericLink(link:$0) }
            sheetActions.append(contentsOf: secondarySheetActions)
        }

        if let diffAction = commonViewModel.diffAction {
            sheetActions.append(diffAction)
        }

        return sheetActions
    }

    var genericActions: [NotificationsCenterAction] {
        var sheetActions: [NotificationsCenterAction] = []

        if let primaryLink = notification.primaryLink,
           let primarySheetAction = commonViewModel.actionForGenericLink(link: primaryLink) {
            sheetActions.append(primarySheetAction)
        }

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            sheetActions.append(agentUserPageAction)
        }

        if let diffAction = commonViewModel.diffAction {
            sheetActions.append(diffAction)
        }

        return sheetActions
    }
}
