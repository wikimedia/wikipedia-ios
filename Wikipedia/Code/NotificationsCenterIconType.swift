import Foundation

typealias NotificationsCenterIconName = String

//Use if you need to make the system (SFSymbols) vs custom distinction
enum NotificationsCenterIconType: Equatable {
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
        if #available(iOS 14, *) {
            return .system("doc.plaintext.fill")
        }
        return .system("doc.text.fill")
    }
    
    static var document: NotificationsCenterIconType {
        if #available(iOS 14, *) {
            return .system("doc.plaintext")
        }
        return .system("doc.text")
    }
    
    static var photo: NotificationsCenterIconType {
        return .system("photo")
    }
    
    static var diff: NotificationsCenterIconType {
        return .custom("notifications-icon-diff") //TODO: Need to add icon to project
    }
    
    static var wikidata: NotificationsCenterIconType {
        return .custom("notifications-project-wikidata")
    }
}
