import UIKit

@objc(WMFThemeableNavigationController)
class ThemeableNavigationController: UINavigationController, Themeable {
    var theme: Theme = Theme.standard
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.preferredStatusBarStyle
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        setNeedsStatusBarAppearanceUpdate()
    }
}
