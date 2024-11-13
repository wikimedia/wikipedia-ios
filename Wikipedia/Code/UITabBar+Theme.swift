import WMF
import UIKit

extension UITabBar: @retroactive Themeable {
    public func apply(theme: Theme) {
        isTranslucent = false
        let appearance = UITabBarAppearance.appearanceForTheme(theme)
        self.standardAppearance = appearance
        self.scrollEdgeAppearance = appearance
    }
}
