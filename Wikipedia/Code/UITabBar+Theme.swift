import WMF
import UIKit

extension UITabBar: @retroactive Themeable {
    public func apply(theme: Theme) {
        if #available(iOS 26.0, *) {
            // Liquid Glass style: transparent background and shadowless chrome.
            isTranslucent = true
            let appearance = UITabBarAppearance.appearanceForTheme(theme)
            standardAppearance = appearance
            scrollEdgeAppearance = appearance
            backgroundImage = UIImage()
            shadowImage = UIImage()
            barTintColor = .clear
            backgroundColor = .clear
            layer.masksToBounds = false
        } else {
            // Preserve the opaque background for pre-iOS 26 to keep contrast.
            isTranslucent = false
            let appearance = UITabBarAppearance.appearanceForTheme(theme)
            standardAppearance = appearance
            scrollEdgeAppearance = appearance
            backgroundImage = nil
            shadowImage = nil
            barTintColor = nil
            backgroundColor = nil
        }
    }
}
