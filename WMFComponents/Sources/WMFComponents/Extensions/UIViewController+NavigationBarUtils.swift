// Common methods used for navigation bar display in the app
import UIKit

// MARK: WMFNavigationBarConfiguring

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
    public let accessibilityLabel: String
    public let accessibilityHint: String
    public let needsBadge: Bool
    public let target: Any
    public let action: Selector
    
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
        
        navigationItem.title = titleConfig.title
 
        switch titleConfig.alignment {
        case .centerCompact:
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            if let customTitleView = titleConfig.customView {
                navigationItem.titleView = customTitleView
                themeNavigationBarCustomCenteredTitleView()
            }
        case .leadingCompact:
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.titleView = UIView()
            if let customTitleView = titleConfig.customView {
                navigationItem.leftBarButtonItem = UIBarButtonItem(customView: customTitleView)
                themeNavigationBarLeadingTitleView()
            } else {
                let leadingTitleLabel = UILabel()
                leadingTitleLabel.font = WMFFont.navigationBarLeadingCompactTitleFont
                leadingTitleLabel.text = titleConfig.title
                
                navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leadingTitleLabel)
                
                themeNavigationBarLeadingTitleView()
            }
        case .leadingLarge:
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .always
            if let customTitleView = titleConfig.customView {
                navigationItem.titleView = customTitleView
            } else {
                navigationItem.titleView = nil
            }
            navigationItem.leftBarButtonItem = nil
            
            if let customLargeTitleFont = titleConfig.customLargeTitleFont {
                let appearance = UINavigationBarAppearance()
                appearance.largeTitleTextAttributes = [.font: customLargeTitleFont]
                
                appearance.configureWithOpaqueBackground()
                
                appearance.backgroundColor = WMFAppEnvironment.current.theme.paperBackground
                let backgroundImage = UIImage.roundedRectImage(with: WMFAppEnvironment.current.theme.paperBackground, cornerRadius: 1)
                appearance.backgroundImage = backgroundImage
                
                appearance.shadowImage = UIImage()
                appearance.shadowColor = .clear
                
                navigationController?.navigationBar.tintColor = WMFAppEnvironment.current.theme.navigationBarTintColor
                
                navigationController?.navigationBar.standardAppearance = appearance
                navigationController?.navigationBar.scrollEdgeAppearance = appearance
                navigationController?.navigationBar.compactAppearance = appearance
                
            } else {
                let appearance = UINavigationBarAppearance()
                appearance.largeTitleTextAttributes = [.font: WMFFont.navigationBarLeadingLargeTitleFont]
                navigationController?.navigationBar.standardAppearance = appearance
                navigationController?.navigationBar.scrollEdgeAppearance = appearance
                navigationController?.navigationBar.compactAppearance = appearance
            }
        case .hidden:
            navigationController?.navigationBar.prefersLargeTitles = false
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
    
    func profileButtonImage(theme: WMFTheme, needsBadge: Bool) -> UIImage? {
        let paletteColors: [UIColor]
        
        if needsBadge {
            paletteColors = [theme.destructive, theme.navigationBarTintColor]
        } else {
            paletteColors = [theme.navigationBarTintColor]
        }
        
        let symbol = WMFSFSymbolIcon.for(symbol: needsBadge ? .personCropCircleBadge : .personCropCircle, paletteColors: paletteColors)
        return symbol
    }
}

// MARK: WMFNavigationBarHiding

// Protocol that provides some default helper methods to add a transparent top safe area overlay and prevent the navigation bar from sticking in a hidden state when scrolled to the top.
public protocol WMFNavigationBarHiding: AnyObject {
    var topSafeAreaOverlayView: UIView? { get set }
    var topSafeAreaOverlayHeightConstraint: NSLayoutConstraint? { get set }
}

public extension WMFNavigationBarHiding where Self:UIViewController {
    
    /// Call from UIViewController's viewDidLoad
    func setupTopSafeAreaOverlay(scrollView: UIScrollView) {
        
        // Insert UIView covering below navigation bar, but above scroll view of content. This hides content beneath top transparent background as it scrolls

        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(overlayView, aboveSubview: scrollView)
        
        let overlayHeightConstraint = overlayView.heightAnchor.constraint(equalToConstant: 0)
        topSafeAreaOverlayHeightConstraint = overlayHeightConstraint
        calculateTopSafeAreaOverlayHeight()
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: overlayView.topAnchor),
            view.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor),
            overlayHeightConstraint
        ])
        
        topSafeAreaOverlayView = overlayView
        themeTopSafeAreaOverlay()
    }
    
    /// Call from UIViewController when theme changes
    ///     - from apply(theme:) if legacy
    ///     - from appEnvironmentDidChange() if WMFComponents
    func themeTopSafeAreaOverlay() {
        topSafeAreaOverlayView?.backgroundColor =   WMFAppEnvironment.current.theme.paperBackground
        topSafeAreaOverlayView?.alpha = 0.95
    }
    
    /// Call from UIViewController when the status bar height might change (like upon rotation)
    func calculateTopSafeAreaOverlayHeight() {
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        topSafeAreaOverlayHeightConstraint?.constant = statusBarHeight
    }
    
    /// Call from a UIViewController's scrollViewDidScroll method to unstick a hidden navigation bar when scrolled to the top.
    func calculateNavigationBarHiddenState(scrollView: UIScrollView) {
        let finalOffset = scrollView.contentOffset.y + scrollView.safeAreaInsets.top
        if finalOffset < 5 && (navigationController?.navigationBar.isHidden ?? true) {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
}

public extension WMFFont {
    static var navigationBarDoneButtonFont: UIFont {
        return WMFFont.for(.semiboldHeadline)
    }
    
    static var navigationBarLeadingCompactTitleFont: UIFont {
        return WMFFont.for(.boldTitle1)
    }
    
    static var navigationBarLeadingLargeTitleFont: UIFont {
        return WMFFont.for(.boldTitle1)
    }
}

public extension WMFTheme {
    var navigationBarTintColor: UIColor {
        return self.link
    }
}

private extension UIApplication {
    var keyWindow: UIWindow? {
        return UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }
    }
    
    var statusBarFrame: CGRect {
        keyWindow?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
    }

}
