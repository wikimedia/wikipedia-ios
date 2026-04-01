import UIKit
import WMFData
import SwiftUI

public protocol WMFNavigationBarConfiguring {
    
}

/// Title config for navigation bar
public struct WMFNavigationBarTitleConfig {
    
    public enum Alignment {
        case leadingLarge
        case centerCompact
        case hidden
        /// Large title pinned to the upper-leading edge of the bar, overlapping the area normally used by back buttons.
        /// Intended for root tab-bar view controllers and views that have no back button.
        case customLeadingLarge
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

public struct WMFNavigationBarBackButtonConfig {
    let needsCustomTruncateBackButtonTitle: Bool
    
    public init(needsCustomTruncateBackButtonTitle: Bool) {
        self.needsCustomTruncateBackButtonTitle = needsCustomTruncateBackButtonTitle
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
    
    public init(accessibilityLabelNoNotifications: String, accessibilityLabelHasNotifications: String, accessibilityHint: String, needsBadge: Bool, target: Any, action: Selector, leadingBarButtonItem: UIBarButtonItem?) {
        self.accessibilityLabelNoNotifications = accessibilityLabelNoNotifications
        self.accessibilityLabelHasNotifications = accessibilityLabelHasNotifications
        self.accessibilityHint = accessibilityHint
        self.needsBadge = needsBadge
        self.target = target
        self.action = action
        self.leadingBarButtonItem = leadingBarButtonItem
    }
}

public struct WMFNavigationBarTabsButtonConfig {
    public let accessibilityLabel: String
    public let accessibilityHint: String
    public let target: Any
    public let action: Selector
    public let leadingBarButtonItem: UIBarButtonItem?
    public let trailingBarButtonItem: UIBarButtonItem?
    public let needsSeparateGlassContainer: Bool
    
    public init(accessibilityLabel: String, accessibilityHint: String, target: Any, action: Selector, leadingBarButtonItem: UIBarButtonItem?, trailingBarButtonItem: UIBarButtonItem?, needsSeparateGlassContainer: Bool) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.target = target
        self.action = action
        self.leadingBarButtonItem = leadingBarButtonItem
        self.trailingBarButtonItem = trailingBarButtonItem
        self.needsSeparateGlassContainer = needsSeparateGlassContainer
    }
}

public struct WMFNavigationBarSearchButtonConfig {
    public let accessibilityLabel: String
    public let accessibilityHint: String
    public let target: Any
    public let action: Selector
    public let leadingBarButtonItem: UIBarButtonItem?
    public let trailingBarButtonItem: UIBarButtonItem?

    public init(accessibilityLabel: String, accessibilityHint: String, target: Any, action: Selector, leadingBarButtonItem: UIBarButtonItem?, trailingBarButtonItem: UIBarButtonItem?) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
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

// MARK: - Navigation Bar Configuring Extension

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
    func configureNavigationBar(titleConfig: WMFNavigationBarTitleConfig,
                                backButtonConfig: WMFNavigationBarBackButtonConfig? = nil,
                                closeButtonConfig: WMFLargeCloseButtonConfig?,
                                profileButtonConfig: WMFNavigationBarProfileButtonConfig?,
                                tabsButtonConfig: WMFNavigationBarTabsButtonConfig?,
                                searchButtonConfig: WMFNavigationBarSearchButtonConfig? = nil,
                                searchBarConfig: WMFNavigationBarSearchConfig?,
                                hideNavigationBarOnScroll: Bool) {
        
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
            removeUpperLeadingLargeTitleLabel()
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
            removeUpperLeadingLargeTitleLabel()
            
            if let customLargeTitleFont = titleConfig.customLargeTitleFont {
                customizeNavBarAppearance(customLargeTitleFont: customLargeTitleFont)
            }
        case .hidden:
            navigationItem.title = nil
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.backButtonTitle = titleConfig.title
            navigationItem.titleView = nil
            removeUpperLeadingLargeTitleLabel()
        case .customLeadingLarge:
            navigationItem.title = nil
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.titleView = nil
            navigationItem.leftBarButtonItem = nil
            // Fixes wrong placement in Places and Saved, due to segmented control attached view
            let pinToTop = searchBarConfig != nil
            addOrUpdateUpperLeadingLargeTitleLabel(title: titleConfig.title, pinToTop: pinToTop)
        }
        
        // Better back button naming for article tabs
        // TODO: Consider smarter prefix amounts, depending on screen size.
        if let backButtonConfig,
           backButtonConfig.needsCustomTruncateBackButtonTitle,
           !UIAccessibility.isVoiceOverRunning {
            if titleConfig.title.count > 10 {
                navigationItem.backButtonTitle = titleConfig.title.prefix(10) + "..."
            }
        }

        if let profileButtonConfig {

            var rightBarButtonItems: [UIBarButtonItem] = []

            let image = profileButtonImage(theme: WMFAppEnvironment.current.theme, needsBadge: profileButtonConfig.needsBadge)
            let profileButton = UIBarButtonItem(image: image, style: .plain, target: profileButtonConfig.target, action: profileButtonConfig.action)

            profileButton.accessibilityLabel = profileButtonAccessibilityStrings(config: profileButtonConfig)
            profileButton.accessibilityIdentifier = profileButtonAccessibilityID

            rightBarButtonItems.append(profileButton)

            if let tabsButtonConfig {

                let image = WMFSFSymbolIcon.for(symbol: .tabsIcon)
                let tabsButton = UIBarButtonItem(image: image, style: .plain, target: tabsButtonConfig.target, action: tabsButtonConfig.action)

                rightBarButtonItems.append(tabsButton)

                if let leadingBarButtonItem = tabsButtonConfig.leadingBarButtonItem {
                    if #available(iOS 26.0, *), tabsButtonConfig.needsSeparateGlassContainer {
                        leadingBarButtonItem.sharesBackground = false
                    }
                    rightBarButtonItems.append(leadingBarButtonItem)
                }
            }

            navigationItem.rightBarButtonItems = rightBarButtonItems
        }

        // Setup close button if needed
        if let closeButtonConfig {
            
            let closeButton = UIBarButtonItem.closeNavigationBarButtonItem(config: closeButtonConfig)
            
            switch closeButtonConfig.alignment {
            case .leading:
                navigationItem.leftBarButtonItem = closeButton
            case .trailing:
                navigationItem.rightBarButtonItem = closeButton
            }
        }
        
        if let searchButtonConfig {
            var rightBarButtonItems: [UIBarButtonItem] = []

            if let profileButtonConfig {
                let profileImage = profileButtonImage(theme: WMFAppEnvironment.current.theme, needsBadge: profileButtonConfig.needsBadge)
                let profileButton = UIBarButtonItem(image: profileImage, style: .plain, target: profileButtonConfig.target, action: profileButtonConfig.action)
                profileButton.accessibilityLabel = profileButtonAccessibilityStrings(config: profileButtonConfig)
                profileButton.accessibilityIdentifier = profileButtonAccessibilityID
                rightBarButtonItems.append(profileButton)
            }

            if let tabsButtonConfig {
                let tabsImage = WMFSFSymbolIcon.for(symbol: .tabsIcon)
                let tabsButton = UIBarButtonItem(image: tabsImage, style: .plain, target: tabsButtonConfig.target, action: tabsButtonConfig.action)
                tabsButton.accessibilityLabel = tabsButtonConfig.accessibilityLabel
                tabsButton.accessibilityHint = tabsButtonConfig.accessibilityHint
                rightBarButtonItems.append(tabsButton)
            }

            let image = WMFSFSymbolIcon.for(symbol: .magnifyingGlass)
            let searchButton = UIBarButtonItem(image: image, style: .plain, target: searchButtonConfig.target, action: searchButtonConfig.action)
            rightBarButtonItems.append(searchButton)

            if let leadingBarButtonItem = searchButtonConfig.leadingBarButtonItem {
                navigationItem.leftBarButtonItem = leadingBarButtonItem
            }
            if let trailingBarButtonItem = searchButtonConfig.trailingBarButtonItem {
                rightBarButtonItems.append(trailingBarButtonItem)
            }

            navigationItem.rightBarButtonItems = rightBarButtonItems
        }
        
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
                searchController.scopeBarActivation = .manual
                searchController.searchBar.scopeButtonTitles = searchBarConfig.scopeButtonTitles
            }

            navigationItem.hidesSearchBarWhenScrolling = false
            navigationItem.preferredSearchBarPlacement = .stacked
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
            paletteColors = [theme.destructive, theme.text]
        } else {
            paletteColors = [theme.text]
        }
        
        let symbol = WMFSFSymbolIcon.for(symbol: needsBadge ? .personCropCircleBadge : .personCropCircle, paletteColors: paletteColors)
        return symbol
    }

    func profileButtonAccessibilityStrings(config: WMFNavigationBarProfileButtonConfig) -> String {
        return config.needsBadge ? config.accessibilityLabelHasNotifications : config.accessibilityLabelNoNotifications
    }

    // MARK: - Upper-leading large title helpers

    private var upperLeadingLargeTitleTag: Int { 0x574D465F_5469746C }  // "WMF_Titl" as a stable tag

    /// Adds a large bold label pinned to the leading edge of the navigation bar, or updates its text/position if already present.
    /// - Parameters:
    ///   - title: The text to display.
    ///   - pinToTop: When `true` the label is pinned to the top of the bar (for use when a stacked search bar occupies the bottom).
    ///               When `false` (default) the label is pinned to the bottom, matching the standard large-title row position.
    private func addOrUpdateUpperLeadingLargeTitleLabel(title: String, pinToTop: Bool = false) {
        guard let navBar = navigationController?.navigationBar else { return }

        // Remove any existing label so constraints are rebuilt when pin direction changes.
        navBar.viewWithTag(upperLeadingLargeTitleTag)?.removeFromSuperview()

        let label = UILabel()
        label.tag = upperLeadingLargeTitleTag
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        navBar.addSubview(label)

        let verticalConstraint: NSLayoutConstraint
        if pinToTop {
            verticalConstraint = label.topAnchor.constraint(equalTo: navBar.topAnchor, constant: 8)
        } else {
            verticalConstraint = label.bottomAnchor.constraint(equalTo: navBar.bottomAnchor, constant: -8)
        }

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 16),
            verticalConstraint
        ])

        label.text = title
        label.textColor = WMFAppEnvironment.current.theme.text
    }

    /// Removes the upper-leading large title label from the navigation bar if present.
    private func removeUpperLeadingLargeTitleLabel() {
        navigationController?.navigationBar.viewWithTag(upperLeadingLargeTitleTag)?.removeFromSuperview()
    }

    /// Call from UIViewController when theme changes to re-apply the correct text color.
    ///     - from apply(theme:) if legacy
    ///     - from appEnvironmentDidChange() if WMFComponents
    func themeNavigationBarUpperLeadingLargeTitle() {
        let label = navigationController?.navigationBar.viewWithTag(upperLeadingLargeTitleTag) as? UILabel
        label?.textColor = WMFAppEnvironment.current.theme.text
    }
}
