import WMF
import UIKit

extension UITabBar: Themeable {
    public func apply(theme: Theme) {
        isTranslucent = false
        let appearance = UITabBarAppearance.appearanceForTheme(theme)
        self.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            self.scrollEdgeAppearance = appearance
        } else {
            self.barTintColor = theme.colors.chromeBackground
        }
    }
}
