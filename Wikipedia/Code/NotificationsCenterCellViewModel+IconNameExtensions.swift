
import Foundation

extension NotificationsCenterCellViewModel {
    
    typealias IconName = String
    
    //Use if you need to make the system (SFSymbols) vs custom distinction
    enum IconType: Equatable {
        case custom(IconName)
        case system(IconName)
        
        static var lock: IconType {
            return .system("lock")
        }
        
        static var link: IconType {
            return .system("link")
        }
        
        static var personFill: IconType {
            return .system("person.circle.fill")
        }
        
        static var documentFill: IconType {
            if #available(iOS 14, *) {
                return .system("doc.plaintext.fill")
            }
            return .system("doc.text.fill")
        }
        
        static var photo: IconType {
            return .system("photo")
        }
    }
        
    var projectIconName: IconName? {
        return project.projectIconName
    }
        
    var footerIconType: IconType? {
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
            //TODO: Should we include the other talk types?
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
