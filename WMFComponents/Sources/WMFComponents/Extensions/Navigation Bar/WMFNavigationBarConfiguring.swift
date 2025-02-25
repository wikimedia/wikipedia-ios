import UIKit

public protocol WMFNavigationBarConfiguring {
    
}

/// Title config for navigation bar
public struct WMFNavigationBarTitleConfig {
    
    public enum Alignment {
        case leadingCompact
        case leadingLarge
        case centerCompact
        case hidden
    }
    
    let title: String
    let customView: UIView?
    let alignment: Alignment
    let customLargeTitleFont: UIFont?
    
    public init(title: String, customView: UIView?, alignment: Alignment, customLargeTitleFont: UIFont? = nil) {
        self.title = title
        self.customView = customView
        self.alignment = alignment
        self.customLargeTitleFont = customLargeTitleFont
    }
}

/// Close button config for navigation bar
public struct WMFNavigationBarCloseButtonConfig {
    
    public enum Alignment {
        case leading
        case trailing
    }
    
    let text: String
    let target: Any
    let action: Selector
    let alignment: Alignment
    
    public init(text: String, target: Any, action: Selector, alignment: Alignment) {
        self.text = text
        self.target = target
        self.action = action
        self.alignment = alignment
    }
}

/// Profile button config for navigation bar
public struct WMFNavigationBarProfileButtonConfig {
    public let accessibilityLabelNoNotifications: String
    public let accessibilityLabelHasNotifications: String
    public let accessibilityHint: String
    public let needsBadge: Bool
    public let target: Any
    public let action: Selector
    public let leadingBarButtonItem: UIBarButtonItem?
    public let trailingBarButtonItem: UIBarButtonItem?
    
    public init(accessibilityLabelNoNotifications: String, accessibilityLabelHasNotifications: String, accessibilityHint: String, needsBadge: Bool, target: Any, action: Selector, leadingBarButtonItem: UIBarButtonItem?, trailingBarButtonItem: UIBarButtonItem?) {
        self.accessibilityLabelNoNotifications = accessibilityLabelNoNotifications
        self.accessibilityLabelHasNotifications = accessibilityLabelHasNotifications
        self.accessibilityHint = accessibilityHint
        self.needsBadge = needsBadge
        self.target = target
        self.action = action
        self.leadingBarButtonItem = leadingBarButtonItem
        self.trailingBarButtonItem = trailingBarButtonItem
    }
}

/// Search config for navigation bar
public struct WMFNavigationBarSearchConfig {
    let searchResultsController: UIViewController?
    let searchControllerDelegate: UISearchControllerDelegate?
    let searchResultsUpdater: UISearchResultsUpdating?
    let searchBarDelegate: UISearchBarDelegate?
    let searchBarPlaceholder: String
    let showsScopeBar: Bool
    let scopeButtonTitles: [String]?
    
    public init(searchResultsController: UIViewController?, searchControllerDelegate: UISearchControllerDelegate?, searchResultsUpdater: UISearchResultsUpdating?, searchBarDelegate: UISearchBarDelegate?, searchBarPlaceholder: String, showsScopeBar: Bool, scopeButtonTitles: [String]?) {
        self.searchResultsController = searchResultsController
        self.searchControllerDelegate = searchControllerDelegate
        self.searchResultsUpdater = searchResultsUpdater
        self.searchBarDelegate = searchBarDelegate
        self.searchBarPlaceholder = searchBarPlaceholder
        self.showsScopeBar = showsScopeBar
        self.scopeButtonTitles = scopeButtonTitles
    }
}

public extension WMFNavigationBarConfiguring where Self: UIViewController {
    
    private var profileButtonAccessibilityID: String {
        "profile-button"
    }
    
    /// Shared method to apply navigation bar styling on an individual view controller basis. Call within viewWillAppear. For common UINavigationBar styling that should be shared across the app, update WMFComponentNavigationController.
    /// - Parameters:
    ///   - titleConfig: Config for title setup
    ///   - closeButtonConfig: Config for close button
    ///   - profileButtonConfig: Config for profile button
    ///   - searchBarConfig: Config for search bar
    ///   - hideNavigationBarOnScroll: If true, will hide the navigation bar when the user scrolls
    func configureNavigationBar(titleConfig: WMFNavigationBarTitleConfig, closeButtonConfig: WMFNavigationBarCloseButtonConfig?, profileButtonConfig: WMFNavigationBarProfileButtonConfig?, searchBarConfig: WMFNavigationBarSearchConfig?, hideNavigationBarOnScroll: Bool) {
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.hidesBarsOnSwipe = hideNavigationBarOnScroll
        
        if hideNavigationBarOnScroll && !(self is WMFNavigationBarHiding) {
            debugPrint("Consider conforming to WMFNavigationBarHiding, which has helper methods ensuring the system navigation bar has a proper top safe area overlay and does not stick in a hidden state when scrolled to the top.")
        }
 
        switch titleConfig.alignment {
        case .centerCompact:
            navigationItem.title = titleConfig.title
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            if let customTitleView = titleConfig.customView {
                navigationItem.titleView = customTitleView
                themeNavigationBarCustomCenteredTitleView()
            }
        case .leadingCompact:
            navigationItem.title = titleConfig.title
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.titleView = UIView()
            if let customTitleView = titleConfig.customView {
                let button = UIBarButtonItem(customView: customTitleView)
                button.accessibilityTraits = .staticText
                navigationItem.leftBarButtonItem = button
                themeNavigationBarLeadingTitleView()
            } else {
                let leadingTitleLabel = UILabel()
                leadingTitleLabel.font = WMFFont.navigationBarLeadingCompactTitleFont
                leadingTitleLabel.text = titleConfig.title
                
                navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leadingTitleLabel)
                
                themeNavigationBarLeadingTitleView()
            }
        case .leadingLarge:
            navigationItem.title = titleConfig.title
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .always
            if let customTitleView = titleConfig.customView {
                navigationItem.titleView = customTitleView
            } else {
                navigationItem.titleView = nil
            }
            navigationItem.leftBarButtonItem = nil
            
            if let customLargeTitleFont = titleConfig.customLargeTitleFont {
                customizeNavBarAppearance(customLargeTitleFont: customLargeTitleFont)
            }
        case .hidden:
            navigationItem.title = nil
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.backButtonTitle = titleConfig.title
            navigationItem.titleView = nil
        }
        
        // Setup profile button if needed
        if let profileButtonConfig {
            let image = profileButtonImage(theme: WMFAppEnvironment.current.theme, needsBadge: profileButtonConfig.needsBadge)
            
            let profileButton = UIBarButtonItem(image: image, style: .plain, target: profileButtonConfig.target, action: profileButtonConfig.action)
            
            profileButton.accessibilityLabel = profileButtonAccessibilityStrings(config: profileButtonConfig)
            profileButton.accessibilityIdentifier = profileButtonAccessibilityID
            
            var rightBarButtonItems: [UIBarButtonItem] = [profileButton]
            if let leadingBarButtonItem = profileButtonConfig.leadingBarButtonItem {
                rightBarButtonItems.append(leadingBarButtonItem)
            }
            
            if let trailingBarButtonItem = profileButtonConfig.trailingBarButtonItem {
                rightBarButtonItems.insert(trailingBarButtonItem, at: 0)
            }
            
            navigationItem.rightBarButtonItems = rightBarButtonItems
        }
        
        // Setup close button if needed
        if let closeButtonConfig {
            let closeButton = UIBarButtonItem(title: closeButtonConfig.text, style: .done, target: closeButtonConfig.target, action: closeButtonConfig.action)
            closeButton.setTitleTextAttributes([.font: WMFFont.navigationBarDoneButtonFont], for: .normal)
            
            switch closeButtonConfig.alignment {
            case .leading:
                navigationItem.leftBarButtonItem = closeButton
            case .trailing:
                navigationItem.rightBarButtonItem = closeButton
            }
        }
        
        // Setup search bar if needed
        if let searchBarConfig,
           navigationItem.searchController == nil {
            let searchController = UISearchController(searchResultsController: searchBarConfig.searchResultsController)
            searchController.delegate = searchBarConfig.searchControllerDelegate
            searchController.searchResultsUpdater = searchBarConfig.searchResultsUpdater
            searchController.searchBar.delegate = searchBarConfig.searchBarDelegate
            searchController.searchBar.searchBarStyle = .minimal
            searchController.searchBar.placeholder = searchBarConfig.searchBarPlaceholder
            searchController.showsSearchResultsController = true
            
            if searchBarConfig.showsScopeBar {
                searchController.searchBar.showsScopeBar = searchBarConfig.showsScopeBar
                
                if #available(iOS 16.0, *) {
                    searchController.scopeBarActivation = .manual
                } else {
                    // Fallback on earlier versions
                }
                
                searchController.searchBar.scopeButtonTitles = searchBarConfig.scopeButtonTitles
            }
            
            navigationItem.hidesSearchBarWhenScrolling = false
            
            if #available(iOS 16.0, *) {
                navigationItem.preferredSearchBarPlacement = .stacked
            } else {
                // Fallback on earlier versions
            }
            
            navigationItem.searchController = searchController
        }
    }
    
    func customizeNavBarAppearance(customLargeTitleFont: UIFont) {
        guard let navVC = navigationController,
        let componentNavVC = navVC as? WMFComponentNavigationController else {
            return
        }
        
        componentNavVC.setBarAppearance(customLargeTitleFont: customLargeTitleFont)
    }
    
    
    /// Call on viewWillDisappear(), IF navigation bar large title was set with a custom font.
    func resetNavBarAppearance() {
        
        guard let navVC = navigationController,
        let componentNavVC = navVC as? WMFComponentNavigationController else {
            return
        }
        
        componentNavVC.setBarAppearance(customLargeTitleFont: nil)
    }
    
    /// Call from UIViewController when theme changes
    ///     - from apply(theme:) if legacy
    ///     - from appEnvironmentDidChange() if WMFComponents
    func themeNavigationBarLeadingTitleView() {
        navigationItem.leftBarButtonItem?.tintColor = WMFAppEnvironment.current.theme.text
        navigationItem.leftBarButtonItem?.customView?.tintColor = WMFAppEnvironment.current.theme.text
    }
    
    /// Call from UIViewController when theme changes
    ///     - from apply(theme:) if legacy
    ///     - from appEnvironmentDidChange() if WMFComponents
    func themeNavigationBarCustomCenteredTitleView() {
        navigationItem.titleView?.tintColor = WMFAppEnvironment.current.theme.text
    }
    
    var currentProfileBarButtonItem: UIBarButtonItem? {
        return navigationItem.rightBarButtonItems?.filter { $0.accessibilityIdentifier == profileButtonAccessibilityID }.first
    }
    
    /// Call from UIViewController when theme changes, or when badge needs to change
    ///     - from apply(theme:) if legacy
    ///     - from appEnvironmentDidChange() if WMFComponents
    ///     - whenever badge logic changes (YiR or unread notifications)
    ///     - Parameter needsBadge: true if red dot needs to be applied to profile button, false if not
    func updateNavigationBarProfileButton(needsBadge: Bool, needsBadgeLabel: String, noBadgeLabel: String) {
        let image = profileButtonImage(theme: WMFAppEnvironment.current.theme, needsBadge: needsBadge)
        if let currentProfileBarButtonItem {
            currentProfileBarButtonItem.image = image
            currentProfileBarButtonItem.accessibilityLabel = needsBadge ? needsBadgeLabel : noBadgeLabel
        }
    }
    
    private func profileButtonImage(theme: WMFTheme, needsBadge: Bool) -> UIImage? {
        let paletteColors: [UIColor]
        
        if needsBadge {
            paletteColors = [theme.destructive, theme.navigationBarTintColor]
        } else {
            paletteColors = [theme.navigationBarTintColor]
        }
        
        let symbol = WMFSFSymbolIcon.for(symbol: needsBadge ? .personCropCircleBadge : .personCropCircle, paletteColors: paletteColors)
        return symbol
    }

    func profileButtonAccessibilityStrings(config: WMFNavigationBarProfileButtonConfig) -> String {
        return config.needsBadge ? config.accessibilityLabelHasNotifications : config.accessibilityLabelNoNotifications
    }
}
