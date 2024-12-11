import UIKit

public protocol WMFNavigationBarStyling {
    
}

public enum WMFNavigationBarStyle {
    case standard
    case largeTitle
}


/// Title config for a navigation bar. If hideTitleView = false, this title will appear in the navigation bar and in the long press back button stack. If hideTitleView = true, this title will only appear in the long press back button stack
public struct WMFNavigationBarTitleConfig {
    let title: String
    let hideTitleView: Bool
    
    public init(title: String, hideTitleView: Bool) {
        self.title = title
        self.hideTitleView = hideTitleView
    }
}

/// Close button config for navigation bar
public struct WMFNavigationBarCloseButtonConfig {
    
    public enum Alignment {
        case leading
        case trailing
    }
    
    let accessibilityLabel: String
    let target: Any
    let action: Selector
    let alignment: Alignment
    
    public init(accessibilityLabel: String, target: Any, action: Selector, alignment: Alignment) {
        self.accessibilityLabel = accessibilityLabel
        self.target = target
        self.action = action
        self.alignment = alignment
    }
}

/// Profile button config for navigation bar
public struct WMFNavigationBarProfileButtonConfig {
    let accessibilityLabel: String
    let accessibilityHint: String
    let needsBadge: Bool
    let target: Any
    let action: Selector
    
    public init(accessibilityLabel: String, accessibilityHint: String, needsBadge: Bool, target: Any, action: Selector) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.needsBadge = needsBadge
        self.target = target
        self.action = action
    }
}

public extension WMFNavigationBarStyling where Self: UIViewController {
    
    /// Shared method to apply navigation bar styling on an individual view controller basis. Call within viewWillAppear. For common UINavigationBar styling that should be shared across the app, update WMFComponentNavigationController.
    /// - Parameters:
    ///   - style: A style enum for setting up the navigation bar.
    ///   - titleConfig: Config for title setup
    ///   - closeButtonConfig: Config for close button. If provided, a leading X button will be added to navigation bar, which will dismiss the view controller when tapped
    func setupNavigationBar(style: WMFNavigationBarStyle, titleConfig: WMFNavigationBarTitleConfig, closeButtonConfig: WMFNavigationBarCloseButtonConfig?, profileButtonConfig: WMFNavigationBarProfileButtonConfig?) {
        switch style {
        case .standard:
            navigationController?.setNavigationBarHidden(false, animated: true)
            navigationController?.hidesBarsOnSwipe = false
            navigationItem.largeTitleDisplayMode = .never
        case .largeTitle:
            navigationController?.setNavigationBarHidden(false, animated: true)
            navigationController?.hidesBarsOnSwipe = false
            navigationItem.largeTitleDisplayMode = .always
        }
        
        // Allows detection when performing long press popping
        navigationItem.title = titleConfig.title
        
        // Sets title in long press back contextual menu
        navigationItem.backButtonTitle = titleConfig.title
        
        // Enables back button to display only arrow
        navigationItem.backButtonDisplayMode = .minimal
        
        // Hides title display in navigation bar that previous line causes
        if titleConfig.hideTitleView {
            navigationItem.titleView = UIView()
        }
        
        // Setup close button if needed
        if let closeButtonConfig {
            let image = WMFSFSymbolIcon.for(symbol: .close)
            let closeButton = UIBarButtonItem(image: image, style: .plain, target: closeButtonConfig.target, action: closeButtonConfig.action)
            closeButton.accessibilityLabel = closeButtonConfig.accessibilityLabel
            
            switch closeButtonConfig.alignment {
            case .leading:
                navigationItem.leftBarButtonItem = closeButton
                navigationItem.leftBarButtonItem?.tintColor = WMFAppEnvironment.current.theme.inputAccessoryButtonTint
            case .trailing:
                navigationItem.rightBarButtonItem = closeButton
                navigationItem.rightBarButtonItem?.tintColor = WMFAppEnvironment.current.theme.inputAccessoryButtonTint
            }
        }
        
        // Setup profile button if needed
        if let profileButtonConfig {
            let image = profileButtonImage(theme: WMFAppEnvironment.current.theme, needsBadge: profileButtonConfig.needsBadge)
            let profileButton = UIBarButtonItem(image: image, style: .plain, target: profileButtonConfig.target, action: profileButtonConfig.action)
            profileButton.accessibilityLabel = profileButtonConfig.accessibilityLabel
            navigationItem.rightBarButtonItem = profileButton
        }
    }
    
    /// Call from any apply(theme:) or appEnvironmentDidChange() methods in your UIViewController, if it is was set up with a close button in setupNavigationBar.
    func updateNavBarCloseButtonTintColor(alignment: WMFNavigationBarCloseButtonConfig.Alignment) {
        switch alignment {
        case .leading:
            navigationItem.leftBarButtonItem?.tintColor = WMFAppEnvironment.current.theme.inputAccessoryButtonTint
        case .trailing:
            navigationItem.rightBarButtonItem?.tintColor = WMFAppEnvironment.current.theme.inputAccessoryButtonTint
        }
    }
    
    
    /// Call from view controller when theme changes, or when indicated badge needs to update
    /// - Parameter indicated: true if red dot needs to be applied to profile, false if not
    func updateProfileButton(needsBadge: Bool) {
        let image = profileButtonImage(theme: WMFAppEnvironment.current.theme, needsBadge: needsBadge)
        navigationItem.rightBarButtonItem?.image = image
    }
    
    private func profileButtonImage(theme: WMFTheme, needsBadge: Bool) -> UIImage? {
        let paletteColors: [UIColor]
        
        if needsBadge {
            paletteColors = [theme.destructive, theme.link]
        } else {
            paletteColors = [theme.link]
        }
        
        let symbol = WMFSFSymbolIcon.for(symbol: needsBadge ? .personCropCircleBadge : .personCropCircle, paletteColors: paletteColors)
        return symbol
    }
}
