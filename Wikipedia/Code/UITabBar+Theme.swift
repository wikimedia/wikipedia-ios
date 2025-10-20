import WMF
import UIKit

extension UITabBar: @retroactive Themeable {
    public func apply(theme: Theme) {
        // CHANGE: Make tab bar fully transparent (no gray slab) and rely on underlying view background.
        isTranslucent = true // Previous: false (forced opaque background)
        let appearance = UITabBarAppearance.appearanceForTheme(theme)
        self.standardAppearance = appearance
        self.scrollEdgeAppearance = appearance
        // Fallback for iOS < 15 (still safe to call): remove legacy background & shadow.
        self.backgroundImage = UIImage()
        self.shadowImage = UIImage()
        self.barTintColor = .clear
        self.backgroundColor = .clear
        layer.masksToBounds = false
    }
}
