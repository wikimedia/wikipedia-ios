import UIKit
import WMFComponents
import WMF
import WMFData

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

    @objc(profileButtonImageForTheme:indicated:)
    static func profileButtonImage(theme: Theme, indicated: Bool = false) -> UIImage? {
        let symbolName = indicated ? "person.crop.circle.badge" : "person.crop.circle"

        let symbolConfig: UIImage.SymbolConfiguration

        if indicated {
            symbolConfig = UIImage.SymbolConfiguration(paletteColors: [theme.colors.destructive, theme.colors.link])
        } else {
            symbolConfig = UIImage.SymbolConfiguration(paletteColors: [theme.colors.link])
        }

        return UIImage(systemName: symbolName, withConfiguration: symbolConfig)
    }
}

