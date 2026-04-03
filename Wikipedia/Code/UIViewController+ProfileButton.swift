import WMFComponents
import WMFData
import WMF

extension UIViewController {
    
    func tabsButtonConfig(target: Any, action: Selector, dataStore: MWKDataStore, leadingBarButtonItem: UIBarButtonItem? = nil, leadingBarButtonItemTitle: String? = nil, needsSeparateGlassContainer: Bool = false) -> WMFNavigationBarTabsButtonConfig {
        return WMFNavigationBarTabsButtonConfig(title: CommonStrings.tabsTitle, accessibilityLabel: CommonStrings.tabsButtonAccessibilityLabel, accessibilityHint: CommonStrings.tabsButtonAccessibilityHint, target: target, action: action, leadingBarButtonItem: leadingBarButtonItem, leadingBarButtonItemTitle: leadingBarButtonItemTitle, needsSeparateGlassContainer: needsSeparateGlassContainer)
    }
    
    func profileButtonConfig(target: Any, action: Selector, dataStore: MWKDataStore, yirDataController: WMFYearInReviewDataController?) -> WMFNavigationBarProfileButtonConfig {
        var hasUnreadNotifications: Bool = false
        
        let isTemporaryAccount = WMFTempAccountDataController.shared.primaryWikiHasTempAccountsEnabled && dataStore.authenticationManager.authStateIsTemporary
        
        if dataStore.authenticationManager.authStateIsPermanent || isTemporaryAccount {
            let numberOfUnreadNotifications = try? dataStore.remoteNotificationsController.numberOfUnreadNotifications()
            hasUnreadNotifications = (numberOfUnreadNotifications?.intValue ?? 0) != 0
        } else {
            hasUnreadNotifications = false
        }

        var needsYiRNotification = false
        if let yirDataController {
            needsYiRNotification = yirDataController.shouldShowYiRNotification(isLoggedOut: !dataStore.authenticationManager.authStateIsPermanent, isTemporaryAccount: isTemporaryAccount)
        }
        // do not override `hasUnreadNotifications` completely
        if needsYiRNotification {
            hasUnreadNotifications = true
        }
        
        let accessibilityHint = CommonStrings.profileButtonAccessibilityHint
        
        return WMFNavigationBarProfileButtonConfig(title: CommonStrings.account, accessibilityLabelNoNotifications: CommonStrings.profileButtonTitle, accessibilityLabelHasNotifications: CommonStrings.profileButtonBadgeTitle, accessibilityHint: accessibilityHint, needsBadge: hasUnreadNotifications, target: target, action: action)
    }
}
