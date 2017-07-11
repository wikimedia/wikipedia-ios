import UIKit

@objc(WMFThemeableNavigationController)
class ThemeableNavigationController: UINavigationController, Themeable {
    var theme: Theme = Theme.standard
    
    @objc(initWithRootViewController:theme:)
    public init(rootViewController: UIViewController, theme: Theme) {
        super.init(rootViewController: rootViewController)
        apply(theme: theme)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.preferredStatusBarStyle
    }
    
    public func apply(theme: Theme) {
        self.theme = theme
        setNeedsStatusBarAppearanceUpdate()
    }
}
