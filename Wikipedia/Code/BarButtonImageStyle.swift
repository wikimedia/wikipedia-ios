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

    @objc(profileButtonImageForTheme:indicated:isExplore:)
    static func profileButtonImage(theme: Theme, indicated: Bool = false, isExplore: Bool = true) -> UIImage? {
        let paletteColors: [UIColor]
        
        if indicated {
            paletteColors = isExplore ? [theme.colors.destructive, theme.colors.link] : [theme.colors.destructive, theme.colors.primaryText]
        } else {
            paletteColors = isExplore ? [theme.colors.link] : [theme.colors.primaryText]
        }
        
        let symbol = WMFSFSymbolIcon.for(symbol: indicated ? .personCropCircleBadge : .personCropCircle, paletteColors: paletteColors)
        return symbol
    }
}

