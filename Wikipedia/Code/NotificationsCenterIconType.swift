import Foundation

typealias NotificationsCenterIconName = String

// Use if you need to make the system (SFSymbols) vs custom distinction
enum NotificationsCenterIconType: Hashable {
    case custom(NotificationsCenterIconName)
    case system(NotificationsCenterIconName)
    
    static var lock: NotificationsCenterIconType {
        return .system("lock")
    }
    
    static var link: NotificationsCenterIconType {
        return .system("link")
    }
    
    static var personFill: NotificationsCenterIconType {
        return .system("person.circle.fill")
    }
    
    static var person: NotificationsCenterIconType {
        return .system("person")
    }
    
    static var documentFill: NotificationsCenterIconType {
        return .system("doc.plaintext.fill")
    }
    
    static var document: NotificationsCenterIconType {
        return .system("doc.plaintext")
    }
    
    static var photo: NotificationsCenterIconType {
        return .system("photo")
    }
    
    static var diff: NotificationsCenterIconType {
        if #available(iOS 15, *) {
            return .system("chevron.left.forwardslash.chevron.right")
        } else {
            return .system("chevron.left.slash.chevron.right")
        }
    }
    
    static var wikidata: NotificationsCenterIconType {
        return .custom("wikimedia-project-wikidata")
    }
}
