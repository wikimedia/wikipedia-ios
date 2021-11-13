import Foundation
import UIKit

@objc extension UINavigationBarAppearance {
    @objc static func appearanceForTheme(_ theme: Theme, style: WMFThemeableNavigationControllerStyle) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = theme.colors.chromeBackground;
        appearance.titleTextAttributes = theme.navigationBarTitleTextAttributes
        let backgroundImage: UIImage?
        switch style {
            
        case .editor:
            backgroundImage = theme.editorNavigationBarBackgroundImage
        case .sheet:
            backgroundImage = theme.sheetNavigationBarBackgroundImage
        case .gallery:
            backgroundImage = nil
        default:
            backgroundImage = theme.navigationBarBackgroundImage
        }
        
        appearance.backgroundImage = backgroundImage
        
        return appearance
    }
}
