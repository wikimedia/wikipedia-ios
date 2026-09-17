import WMF
import UIKit

extension UITabBar: @retroactive Themeable {
    public func apply(theme: Theme) {

        // Resolve system-drawn materials against the app's theme rather than the device appearance.
        // On iOS 26 the bar keeps no background of its own - it is transparent with no background
        // effect - so its Liquid Glass is drawn by the system and picks up the trait collection.
        // Without this, a light app theme on a device in dark mode gets a dark tinted tab bar.
        overrideUserInterfaceStyle = theme.isDark ? .dark : .light

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
