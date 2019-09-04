import UIKit

open class ExtensionViewController: UIViewController, Themeable {
    public final var theme: Theme = Theme.widgetLight
    
    open func apply(theme: Theme) {
        self.theme = theme
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        updateThemeFromTraitCollection(force: true)
        apply(theme: theme)
    }
    
    private func updateThemeFromTraitCollection(force: Bool = false) {
        let compatibleTheme = Theme.widgetThemeCompatible(with: traitCollection)
        guard theme !== compatibleTheme else {
            if (force) {
                apply(theme: theme)
            }
            return
        }
        apply(theme: compatibleTheme)
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateThemeFromTraitCollection()
    }
}
