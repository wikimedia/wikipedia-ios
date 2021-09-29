
import Foundation

extension NotificationsCenterCellViewModel.IconNames {
    
    init(project: RemoteNotificationsProject, notification: RemoteNotification) {
        self.project = Self.determineProjectIcon(project: project)
        self.footer = Self.determineFooterIcon(notification: notification)
    }
    
    private static func determineProjectIcon(project: RemoteNotificationsProject) -> String? {
        switch project {
        case .commons:
            return "notifications-project-commons"
        case .wikidata:
            return "notifications-project-wikidata"
        case .language:
            return nil
        }
    }
    
    private static func determineFooterIcon(notification: RemoteNotification) -> IconType? {
        
        switch notification.type {
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice:
            return .system("lock")
        case .unknownSystemAlert,
             .unknownSystemNotice,
             .unknownAlert,
             .unknownNotice,
             .unknown:
            return .system("link")
        default:
            break
        }
        
        guard let namespace = PageNamespace(rawValue: Int(notification.titleNamespaceKey)) else {
            return nil
        }
        
        switch namespace {
        case .talk,
             .userTalk:
            //TODO: Should we include the other talk types?
            return .system("person.circle.fill")
        case .main:
            //TODO: doc.plaintext.fill is iOS14+ only, add .custom for iOS13
            return .system("doc.plaintext.fill")
        case .file:
            return .system("photo")
        default:
            return nil
        }
    }
}
