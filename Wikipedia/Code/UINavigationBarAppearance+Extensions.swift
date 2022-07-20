import Foundation
import UIKit

@objc extension UINavigationBarAppearance {
    @objc static func appearanceForTheme(_ theme: Theme, style: WMFThemeableNavigationControllerStyle) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = theme.colors.chromeBackground
        appearance.titleTextAttributes = theme.navigationBarTitleTextAttributes
        switch style {
        case .editor:
            appearance.backgroundImage = theme.editorNavigationBarBackgroundImage
        case .sheet:
            appearance.backgroundImage = theme.sheetNavigationBarBackgroundImage
        case .gallery:
            appearance.backgroundImage = nil
        default:
            appearance.backgroundImage = theme.navigationBarBackgroundImage
        }
        
        return appearance
    }
}
