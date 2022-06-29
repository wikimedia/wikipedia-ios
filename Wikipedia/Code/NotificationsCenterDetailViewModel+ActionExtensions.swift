import Foundation

extension NotificationsCenterDetailViewModel {
    var primaryAction: NotificationsCenterAction? {
        switch commonViewModel.notification.type {
        case .userTalkPageMessage:
            if let talkPageAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: true) {
                return talkPageAction
            }
        case .mentionInTalkPage:
            if let titleTalkPageAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: true) {
                return titleTalkPageAction
            }
        case .editReverted,
                .mentionInEditSummary:
            if let diffAction = commonViewModel.diffAction {
                return diffAction
            }
        case .successfulMention,
                .failedMention,
                .pageReviewed,
                .editMilestone:
            if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: true) {
                return titleAction
            }
        case .userRightsChange:
            if let userGroupRightsAction = commonViewModel.userGroupRightsAction {
                return userGroupRightsAction
            }
        case .pageLinked:
            if let pageLinkFromAction = commonViewModel.pageLinkFromAction {
                return pageLinkFromAction
            }
        case .connectionWithWikidata:
            if let wikidataItemAction = commonViewModel.wikidataItemAction {
                return wikidataItemAction
            }
        case .emailFromOtherUser:
            if let agentUserPageAction = commonViewModel.agentUserPageAction {
                return agentUserPageAction
            }
        case .thanks:
            if let diffAction = commonViewModel.diffAction {
                return diffAction
            }
        case .translationMilestone:
            return nil
        case .welcome:
            if let gettingStartedAction = commonViewModel.gettingStartedAction {
                return gettingStartedAction
            }
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice:
            if let changePasswordAction = commonViewModel.changePasswordAction {
                return changePasswordAction
            }

        case .unknownAlert,
             .unknownSystemAlert:
            if let primaryLink = commonViewModel.notification.primaryLink,
               let primaryAction = commonViewModel.actionForGenericLink(link: primaryLink) {
                return primaryAction
            }

        case .unknownSystemNotice,
             .unknownNotice,
             .unknown:
            if let primaryLink = commonViewModel.notification.primaryLink,
               let primaryAction = commonViewModel.actionForGenericLink(link: primaryLink) {
                return primaryAction
            }
        }

        return nil
    }

    var secondaryActions: [NotificationsCenterAction] {
        var secondaryActions: [NotificationsCenterAction] = []

        switch commonViewModel.notification.type {
        case .userTalkPageMessage:
            secondaryActions.append(contentsOf: userTalkPageActions)
        case .mentionInTalkPage:
            secondaryActions.append(contentsOf: mentionInTalkPageActions)
        case .editReverted:
            secondaryActions.append(contentsOf: editRevertedActions)
        case .mentionInEditSummary:
            secondaryActions.append(contentsOf: mentionInEditSummaryActions)
        case .successfulMention,
             .failedMention:
            secondaryActions.append(contentsOf: successfulAndFailedMentionActions)
        case .userRightsChange:
            secondaryActions.append(contentsOf: userGroupRightsActions)
        case .pageReviewed:
            secondaryActions.append(contentsOf: pageReviewedActions)
        case .pageLinked:
            secondaryActions.append(contentsOf: pageLinkActions)
        case .connectionWithWikidata:
            secondaryActions.append(contentsOf: connectionWithWikidataActions)
        case .emailFromOtherUser:
            secondaryActions.append(contentsOf: emailFromOtherUserActions)
        case .thanks:
            secondaryActions.append(contentsOf: thanksActions)
        case .translationMilestone,
             .editMilestone,
             .welcome:
            break
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice:
            secondaryActions.append(contentsOf: loginActions)

        case .unknownAlert,
             .unknownSystemAlert:
            secondaryActions.append(contentsOf: genericAlertActions)

        case .unknownSystemNotice,
             .unknownNotice,
             .unknown:
            secondaryActions.append(contentsOf: genericActions)

        }
        return secondaryActions
    }

    /// Do not include secondary action if its destination is the same as the primary action or any other secondary action
    var uniqueSecondaryActions: [NotificationsCenterAction] {
        guard let primaryActionURL = primaryAction?.actionData?.url else {
            return secondaryActions
        }

        let filteredArray = secondaryActions.filter({ action in
            action.actionData?.url != primaryActionURL
        })

        return NSOrderedSet(array: filteredArray).compactMap { $0 as? NotificationsCenterAction }
    }

}

// MARK: Private Helpers - Aggregate Swipe Action methods

private extension NotificationsCenterDetailViewModel {
    var userTalkPageActions: [NotificationsCenterAction] {
        var actions: [NotificationsCenterAction] = []

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            actions.append(agentUserPageAction)
        }

        if let diffAction = commonViewModel.diffAction {
            actions.append(diffAction)
        }

        return actions
    }

    var mentionInTalkPageActions: [NotificationsCenterAction] {
        var actions: [NotificationsCenterAction] = []

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            actions.append(agentUserPageAction)
        }

        if let diffAction = commonViewModel.diffAction {
            actions.append(diffAction)
        }

        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: true, simplified: true) {
            actions.append(titleAction)
        }

        return actions
    }

    var mentionInEditSummaryActions: [NotificationsCenterAction] {
        var actions: [NotificationsCenterAction] = []

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            actions.append(agentUserPageAction)
        }

        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: true) {
            actions.append(titleAction)
        }

        return actions
    }

    var successfulAndFailedMentionActions: [NotificationsCenterAction] {
        return []
    }

    var editRevertedActions: [NotificationsCenterAction] {
        var actions: [NotificationsCenterAction] = []

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            actions.append(agentUserPageAction)
        }

        if let talkTitleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: true, simplified: true) {
            actions.append(talkTitleAction)
        }

        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: true) {
            actions.append(titleAction)
        }

        return actions
    }

    var userGroupRightsActions: [NotificationsCenterAction] {
        var actions: [NotificationsCenterAction] = []

        if let specificUserGroupRightsAction = commonViewModel.specificUserGroupRightsAction {
            actions.append(specificUserGroupRightsAction)
        }

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            actions.append(agentUserPageAction)
        }

        return actions
    }

    var pageReviewedActions: [NotificationsCenterAction] {
        var actions: [NotificationsCenterAction] = []

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            actions.append(agentUserPageAction)
        }

        return actions
    }

    var pageLinkActions: [NotificationsCenterAction] {
        var actions: [NotificationsCenterAction] = []

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            actions.append(agentUserPageAction)
        }

        // Article you edited
        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: false) {
            actions.append(titleAction)
        }

        if let diffAction = commonViewModel.diffAction {
            actions.append(diffAction)
        }

        return actions
    }

    var connectionWithWikidataActions: [NotificationsCenterAction] {
        var actions: [NotificationsCenterAction] = []

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            actions.append(agentUserPageAction)
        }

        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: true) {
            actions.append(titleAction)
        }

        return actions
    }

    var emailFromOtherUserActions: [NotificationsCenterAction] {
        return []
    }

    var thanksActions: [NotificationsCenterAction] {
        var actions: [NotificationsCenterAction] = []

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            actions.append(agentUserPageAction)
        }

        if let titleAction = commonViewModel.titleAction(needsConvertToOrFromTalk: false, simplified: true) {
            actions.append(titleAction)
        }

        return actions
    }

    var loginActions: [NotificationsCenterAction] {
        var actions: [NotificationsCenterAction] = []

        if let loginHelpAction = commonViewModel.loginNotificationsGoToAction {
            actions.append(loginHelpAction)
        }

        return actions
    }

    var genericAlertActions: [NotificationsCenterAction] {
        var actions: [NotificationsCenterAction] = []

        if let secondaryLinks = commonViewModel.notification.secondaryLinks {
            let secondaryActions = secondaryLinks.compactMap { commonViewModel.actionForGenericLink(link:$0) }
            actions.append(contentsOf: secondaryActions)
        }

        if let diffAction = commonViewModel.diffAction {
            actions.append(diffAction)
        }

        return actions
    }

    var genericActions: [NotificationsCenterAction] {
        var actions: [NotificationsCenterAction] = []

        if let agentUserPageAction = commonViewModel.agentUserPageAction {
            actions.append(agentUserPageAction)
        }

        if let diffAction = commonViewModel.diffAction {
            actions.append(diffAction)
        }

        return actions
    }
}
