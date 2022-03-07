import UIKit

@objc class BarButtonImageStyle: NSObject {

    @objc(notificationsButtonImageForTheme:indicated:)
    static func notificationsButtonImage(theme: Theme, indicated: Bool = false) -> UIImage? {
        switch theme {
        case .dark, .black:
            return UIImage(named: indicated ? "notifications-bell-dark-black-indicated" : "notifications-bell-dark-black")
        case .sepia:
            return UIImage(named: indicated ? "notifications-bell-sepia-indicated" : "notifications-bell-sepia")
        default:
            return UIImage(named: indicated ? "notifications-bell-light-indicated" : "notifications-bell-light")
        }
    }

    @objc(settingsButtonImageForTheme:)
    static func settingsButtonImage(theme: Theme) -> UIImage? {
        switch theme {
        case .dark, .black:
            return UIImage(named: "settings-gear-dark-black")
        default:
            return UIImage(named: "settings-gear-light-sepia")
        }
    }

}

