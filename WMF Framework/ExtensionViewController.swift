import UIKit

open class ExtensionViewController: UIViewController, Themeable {
    public final var theme: Theme?
    
    open func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        updateThemeFromTraitCollection()
    }
    
    private func updateThemeFromTraitCollection() {
        let compatibleTheme = Theme.widgetThemeCompatible(with: traitCollection)
        guard theme !== compatibleTheme else {
            return
        }
        apply(theme: compatibleTheme)
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateThemeFromTraitCollection()
    }
}
