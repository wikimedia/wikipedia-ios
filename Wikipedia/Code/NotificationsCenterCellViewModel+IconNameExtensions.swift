
import Foundation

extension NotificationsCenterCellViewModel {
    
    typealias IconName = String
    
    //Use if you need to make the system (SFSymbols) vs custom distinction
    enum IconType {
        case custom(IconName)
        case system(IconName)
    }
        
    var projectIconName: IconName? {
        switch project {
        case .commons:
            return "notifications-project-commons"
        case .wikidata:
            return "notifications-project-wikidata"
        case .wikiquote:
            return "notifications-project-wikiquote"
        case .wikipedia:
            return nil
        case .wikibooks:
            return "notifications-project-wikibooks"
        case .wiktionary:
            return "notifications-project-wiktionary"
        case .wikisource:
            return "notifications-project-wikisource"
        case .wikinews:
            return "notifications-project-wikinews"
        case .wikiversity:
            return "notifications-project-wikiversity"
        case .wikivoyage:
            return "notifications-project-wikivoyage"
        case .mediawiki:
            return "notifications-project-mediawiki"
        case .wikispecies:
            return "notifications-project-wikispecies"
        }
    }
        
    var footerIconType: IconType? {
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
        
        guard let namespace = PageNamespace(rawValue: Int(notification.titleNamespaceKey)),
              notification.titleNamespace != nil else {
            return nil
        }
        
        switch namespace {
        case .talk,
             .userTalk,
             .user:
            //TODO: Should we include the other talk types?
            return .system("person.circle.fill")
        case .main:
            if #available(iOS 14, *) {
                return .system("doc.plaintext.fill")
            }
            return .system("doc.text.fill")
        case .file:
            return .system("photo")
        default:
            return nil
        }
    }
}
