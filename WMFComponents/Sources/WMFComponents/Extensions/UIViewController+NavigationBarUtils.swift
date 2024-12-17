// Common methods used for navigation bar display in the app
import UIKit

public protocol WMFNavigationBarConfiguring {
    
}

/// Title config for a navigation bar. If hideTitleView = false, this title will appear in the navigation bar and in the long press back button stack. If hideTitleView = true, this title will only appear in the long press back button stack
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
    
    public init(title: String, customView: UIView?, alignment: Alignment) {
        self.title = title
        self.customView = customView
        self.alignment = alignment
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
    public let needsBadge: Bool
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
    
    /// Shared method to apply navigation bar styling on an individual view controller basis. Call within viewWillAppear. For common UINavigationBar styling that should be shared across the app, update WMFComponentNavigationController.
    /// - Parameters:
    ///   - style: A style enum for setting up the navigation bar.
    ///   - titleConfig: Config for title setup
    ///   - closeButtonConfig: Config for close button. If provided, a leading X button will be added to navigation bar, which will dismiss the view controller when tapped
    func configureNavigationBar(titleConfig: WMFNavigationBarTitleConfig, closeButtonConfig: WMFNavigationBarCloseButtonConfig?, profileButtonConfig: WMFNavigationBarProfileButtonConfig?, searchBarConfig: WMFNavigationBarSearchConfig?, hideNavigationBarOnScroll: Bool) {
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.hidesBarsOnSwipe = hideNavigationBarOnScroll
        
        // Allows detection when performing long press popping
        navigationItem.title = titleConfig.title
        
        // Sets title in long press back contextual menu
        // navigationItem.backButtonTitle = titleConfig.title
        
        // Force full title to show in back button, not "Back"
//        let backBarButtonItem = UIBarButtonItem(title: titleConfig.title, style: .plain, target: nil, action: nil)
//        navigationItem.backBarButtonItem = backBarButtonItem
        
        // Enables back button to display only arrow
        // navigationItem.backButtonDisplayMode = .minimal 
        
        switch titleConfig.alignment {
        case .centerCompact:
            navigationItem.largeTitleDisplayMode = .never
            if let customTitleView = titleConfig.customView {
                navigationItem.titleView = customTitleView
                themeNavigationBarCustomCenteredTitleView()
            }
        case .leadingCompact:
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.titleView = UIView()
            if let customTitleView = titleConfig.customView {
                navigationItem.leftBarButtonItem = UIBarButtonItem(customView: customTitleView)
                themeNavigationBarLeadingTitleView()
            } else {
                let leadingTitleLabel = UILabel()
                leadingTitleLabel.font = WMFFont.for(.boldTitle1)
                leadingTitleLabel.text = titleConfig.title
                // may still need this
                // leadingTitleLabel.textColor = WMFAppEnvironment.current.theme.text
                
                navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leadingTitleLabel)
                
                themeNavigationBarLeadingTitleView()
            }
        case .leadingLarge:
            navigationItem.largeTitleDisplayMode = .always
            if let customTitleView = titleConfig.customView {
                navigationItem.titleView = customTitleView
            } else {
                navigationItem.titleView = nil
            }
            navigationItem.leftBarButtonItem = nil
        case .hidden:
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.titleView = UIView()
        }
        
        // Setup profile button if needed
        if let profileButtonConfig {
            let image = profileButtonImage(theme: WMFAppEnvironment.current.theme, needsBadge: profileButtonConfig.needsBadge)
            let profileButton = UIBarButtonItem(image: image, style: .plain, target: profileButtonConfig.target, action: profileButtonConfig.action)
            profileButton.accessibilityLabel = profileButtonConfig.accessibilityLabel
            navigationItem.rightBarButtonItem = profileButton
        }
        
        // Setup close button if needed
        if let closeButtonConfig {
            // let image = WMFSFSymbolIcon.for(symbol: .close)
            // TODO: Localize
            let closeButton = UIBarButtonItem(title: "Done", style: .done, target: closeButtonConfig.target, action: closeButtonConfig.action)
            
            switch closeButtonConfig.alignment {
            case .leading:
                navigationItem.leftBarButtonItem = closeButton
            case .trailing:
                navigationItem.rightBarButtonItem = closeButton
            }
            
            themeNavigationBarCloseButton(alignment: closeButtonConfig.alignment)
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
    
    /// Call from UIViewController when theme changes
    ///     - from apply(theme:) if legacy
    ///     - from appEnvironmentDidChange() if WMFComponents
    func themeNavigationBarCloseButton(alignment: WMFNavigationBarCloseButtonConfig.Alignment) {
        // Leaving as default tint for now, 
//        switch alignment {
//        case .leading:
//            navigationItem.leftBarButtonItem?.tintColor = WMFAppEnvironment.current.theme.inputAccessoryButtonTint
//        case .trailing:
//            navigationItem.rightBarButtonItem?.tintColor = WMFAppEnvironment.current.theme.inputAccessoryButtonTint
//        }
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
    
    /// Call from UIViewController when theme changes, or when badge needs to change
    ///     - from apply(theme:) if legacy
    ///     - from appEnvironmentDidChange() if WMFComponents
    ///     - whenever badge logic changes (YiR or unread notifications)
    ///     - Parameter needsBadge: true if red dot needs to be applied to profile button, false if not
    func updateNavigationBarProfileButton(needsBadge: Bool) {
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
