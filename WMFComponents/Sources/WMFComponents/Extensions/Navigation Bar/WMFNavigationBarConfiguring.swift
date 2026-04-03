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
    public let title: String
    public let accessibilityLabelNoNotifications: String
    public let accessibilityLabelHasNotifications: String
    public let accessibilityHint: String
    public let needsBadge: Bool
    public let target: Any
    public let action: Selector
    
    public init(title: String, accessibilityLabelNoNotifications: String, accessibilityLabelHasNotifications: String, accessibilityHint: String, needsBadge: Bool, target: Any, action: Selector) {
        self.title = title
        self.accessibilityLabelNoNotifications = accessibilityLabelNoNotifications
        self.accessibilityLabelHasNotifications = accessibilityLabelHasNotifications
        self.accessibilityHint = accessibilityHint
        self.needsBadge = needsBadge
        self.target = target
        self.action = action
    }
}

public struct WMFNavigationBarTabsButtonConfig {
    public let title: String
    public let accessibilityLabel: String
    public let accessibilityHint: String
    public let target: Any
    public let action: Selector
    public let leadingBarButtonItem: UIBarButtonItem?
    public let leadingBarButtonItemTitle: String?
    
    public init(title: String, accessibilityLabel: String, accessibilityHint: String, target: Any, action: Selector, leadingBarButtonItem: UIBarButtonItem?, leadingBarButtonItemTitle: String? = nil) {
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.target = target
        self.action = action
        self.leadingBarButtonItem = leadingBarButtonItem
        self.leadingBarButtonItemTitle = leadingBarButtonItemTitle
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
            removeCustomLeadingLargeTitleLabel()
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
            removeCustomLeadingLargeTitleLabel()
            
            if let customLargeTitleFont = titleConfig.customLargeTitleFont {
                customizeNavBarAppearance(customLargeTitleFont: customLargeTitleFont)
            }
        case .hidden:
            navigationItem.title = nil
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.backButtonTitle = titleConfig.title
            navigationItem.titleView = nil
            removeCustomLeadingLargeTitleLabel()
        case .customLeadingLarge:
            navigationItem.title = nil
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.titleView = nil
            navigationItem.leftBarButtonItem = nil

            addOrUpdateUpperLeadingLargeTitleLabel(title: titleConfig.title)
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

            var trailingBarButtonItems: [UIBarButtonItem] = []
            var specificMenu: UIMenu? = nil
            var globalCollapsedActions: [UIAction] = []
            
            if let tabsButtonConfig {

                let image = WMFSFSymbolIcon.for(symbol: .tabsIcon)
                let tabsButton = UIBarButtonItem(image: image, style: .plain, target: tabsButtonConfig.target, action: tabsButtonConfig.action)

                if let leadingBarButtonItem = tabsButtonConfig.leadingBarButtonItem {
                    trailingBarButtonItems.append(leadingBarButtonItem)
                    if let menu = leadingBarButtonItem.menu {
                        specificMenu = menu
                    } else {
                        specificMenu = UIMenu(title: "", options: .displayInline, children: [
                            UIAction(title: leadingBarButtonItem.title ?? tabsButtonConfig.leadingBarButtonItemTitle ?? "", image: leadingBarButtonItem.image) { _ in
                                
                                if let target = leadingBarButtonItem.target,
                                   let action = leadingBarButtonItem.action {
                                    UIApplication.shared.sendAction(action, to: target, from: nil, for: nil)
                                }
                                
                                
                            }
                        ])
                    }
                    
                }
                
                trailingBarButtonItems.append(tabsButton)
                globalCollapsedActions.append(UIAction(title: tabsButtonConfig.title, image: tabsButton.image) { _ in
                    
                    let target = tabsButtonConfig.target
                    let action = tabsButtonConfig.action
                    
                    UIApplication.shared.sendAction(action, to: target, from: nil, for: nil)
                })
            }

            let image = profileButtonImage(theme: WMFAppEnvironment.current.theme, needsBadge: profileButtonConfig.needsBadge)
            let profileButton = UIBarButtonItem(image: image, style: .plain, target: profileButtonConfig.target, action: profileButtonConfig.action)

            profileButton.accessibilityLabel = profileButtonAccessibilityStrings(config: profileButtonConfig)
            profileButton.accessibilityIdentifier = profileButtonAccessibilityID

            trailingBarButtonItems.append(profileButton)
            globalCollapsedActions.append(UIAction(title: profileButtonConfig.title, image: image) { _ in
                
                let target = profileButtonConfig.target
                let action = profileButtonConfig.action
                
                UIApplication.shared.sendAction(action, to: target, from: nil, for: nil)
            })
            
            var menuChildren: [UIMenu] = [ UIMenu(title: "", options: .displayInline, children: globalCollapsedActions) ]
            if let specificMenu {
                menuChildren.insert(specificMenu, at: 0)
            }
            
            let collapsedMenu = UIMenu(title: "", children: menuChildren)
            
            let representativeItem = UIBarButtonItem(title: nil, image: WMFSFSymbolIcon.for(symbol: .ellipsis), primaryAction: nil, menu: collapsedMenu)

            let group = UIBarButtonItemGroup.optionalGroup(
                customizationIdentifier: "trailing",
                representativeItem: representativeItem,
                items: trailingBarButtonItems
            )

            navigationItem.trailingItemGroups = [group]
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

    private func addOrUpdateUpperLeadingLargeTitleLabel(title: String) {
        guard let navBar = navigationController?.navigationBar else { return }
        
        // No need to add custom title if floating tab bar title is displaying nearby.
        
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && UITraitCollection.current.horizontalSizeClass == .regular {
                removeCustomLeadingLargeTitleLabel()
                return
            }
        }

        // Remove any existing label so constraints are rebuilt when pin direction changes.
        navBar.viewWithTag(upperLeadingLargeTitleTag)?.removeFromSuperview()

        let label = UILabel()
        label.tag = upperLeadingLargeTitleTag
        label.font = WMFFont.navigationBarCustomLeadingLargeTitleFont
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = false
        navBar.addSubview(label)
        
        var leadingPadding = CGFloat(16)
        if #available(iOS 26, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && UITraitCollection.current.horizontalSizeClass == .compact {
                // Add a little more for window close/minimize/expand buttons
                leadingPadding = CGFloat(80)
            }
        }

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: leadingPadding),
            label.topAnchor.constraint(equalTo: navBar.topAnchor, constant: 7)
        ])

        label.text = title
        label.textColor = WMFAppEnvironment.current.theme.text
    }

    private func removeCustomLeadingLargeTitleLabel() {
        navigationController?.navigationBar.viewWithTag(upperLeadingLargeTitleTag)?.removeFromSuperview()
    }

    func themeNavigationBarCustomLeadingLargeTitle() {
        let label = navigationController?.navigationBar.viewWithTag(upperLeadingLargeTitleTag) as? UILabel
        label?.textColor = WMFAppEnvironment.current.theme.text
    }

    func hideCustomLeadingLargeTitleLabel() {
        guard let label = navigationController?.navigationBar.viewWithTag(upperLeadingLargeTitleTag) as? UILabel else { return }
        UIView.animate(withDuration: 0.2) { label.isHidden = true }
    }

    func showCustomLeadingLargeTitleLabel() {
        guard let label = navigationController?.navigationBar.viewWithTag(upperLeadingLargeTitleTag) as? UILabel else { return }
        UIView.animate(withDuration: 0.2) { label.isHidden = false }
    }
}

