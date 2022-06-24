import Foundation

extension NotificationsCenterDetailViewModel {
    var headerTitle: String {
            
        switch commonViewModel.notification.type {
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice:
            return CommonStrings.notificationsCenterAlert
        case .successfulMention,
                .failedMention:
            return WMFLocalizedString("notifications-center-type-item-description-mentions", value: "Mentions", comment: "Description of \"mention\" notification types, used on the notification detail view.")
        case .editMilestone,
             .translationMilestone:
            return commonViewModel.verboseTitle ?? commonViewModel.title
        case .welcome:
            return WMFLocalizedString("notifications-center-type-item-description-welcome-verbose", value: "Welcome message", comment: "Description of \"welcome\" notification types, used on the notification detail view.")
        default:
            break
        }

        if let agentName = commonViewModel.notification.agentName {
            return String.localizedStringWithFormat(CommonStrings.notificationsCenterAgentDescriptionFromFormat, agentName)
        }

        return commonViewModel.title
    }

    var headerSubtitle: String {
        return commonViewModel.project.projectName(shouldReturnCodedFormat: false)
    }

    var headerDate: String? {
        return commonViewModel.dateText
    }

    var contentTitle: String {
        return (commonViewModel.message != nil ? commonViewModel.verboseTitle : commonViewModel.title) ?? commonViewModel.title
    }

    var contentBody: String? {
        return commonViewModel.message ?? commonViewModel.verboseTitle
    }
}
