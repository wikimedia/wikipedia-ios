import UIKit

open class ExtensionViewController: UIViewController, Themeable {
    public final var theme: Theme = Theme.widgetLight
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupTraitChangeObservation()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTraitChangeObservation()
    }
    
    private func setupTraitChangeObservation() {
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) { [weak self] (viewController: Self, previousTraitCollection: UITraitCollection) in
            guard let self else { return }
            self.updateThemeFromTraitCollection()
        }
    }
    
    open func apply(theme: Theme) {
        self.theme = theme
    }
    
    var isFirstLayout = true
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateThemeFromTraitCollection(force: isFirstLayout)
        isFirstLayout = false
    }
    
    private func updateThemeFromTraitCollection(force: Bool = false) {
        let compatibleTheme = Theme.widgetThemeCompatible(with: traitCollection)
        guard theme !== compatibleTheme else {
            if force {
                apply(theme: theme)
            }
            return
        }
        apply(theme: compatibleTheme)
    }
    
    public func openAppInActivity(with activityType: WMFUserActivityType) {
        self.extensionContext?.open(NSUserActivity.wmf_baseURLForActivity(of: activityType))
    }
    
    public func openApp(with url: URL?, fallback fallbackURL: URL? = nil) {
        guard let wikipediaSchemeURL = url?.replacingSchemeWithWikipediaScheme ?? fallbackURL else {
            openAppInActivity(with: .explore)
            return
        }
        self.extensionContext?.open(wikipediaSchemeURL)
    }
}
