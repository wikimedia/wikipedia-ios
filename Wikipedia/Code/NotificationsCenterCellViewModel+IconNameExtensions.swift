import Foundation

extension NotificationsCenterCellViewModel {
        
    var projectIconName: NotificationsCenterIconName? {
        return project.projectIconName
    }
        
    var footerIconType: NotificationsCenterIconType? {
        switch notification.type {
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice:
            return .lock
        case .unknownSystemAlert,
             .unknownSystemNotice,
             .unknownAlert,
             .unknownNotice,
             .unknown:
            return .link
        default:
            break
        }
        
        guard let namespace = PageNamespace(rawValue: Int(notification.titleNamespaceKey)),
              notification.titleNamespace != nil else {
            return nil
        }
        
        switch namespace {
        case .talk,
             .userTalk,
             .user:
            return .personFill
        case .main:
            return .documentFill
        case .file:
            return .photo
        default:
            return nil
        }
    }
}
