import WMFComponents
import WMFData

extension UIViewController {
    
    func profileButtonConfig(target: Any, action: Selector, dataStore: MWKDataStore, yirDataController: WMFYearInReviewDataController?, leadingBarButtonItem: UIBarButtonItem?, trailingBarButtonItem: UIBarButtonItem?) -> WMFNavigationBarProfileButtonConfig {
        var hasUnreadNotifications: Bool = false
        if dataStore.authenticationManager.authStateIsPermanent {
            let numberOfUnreadNotifications = try? dataStore.remoteNotificationsController.numberOfUnreadNotifications()
            hasUnreadNotifications = (numberOfUnreadNotifications?.intValue ?? 0) != 0
        } else {
            hasUnreadNotifications = false
        }

        var needsYiRNotification = false
        if let yirDataController,  let appLanguage = dataStore.languageLinkController.appLanguage {
            let project = WMFProject.wikipedia(WMFLanguage(languageCode: appLanguage.languageCode, languageVariantCode: appLanguage.languageVariantCode))
            needsYiRNotification = yirDataController.shouldShowYiRNotification(primaryAppLanguageProject: project, isLoggedOut: !dataStore.authenticationManager.authStateIsPermanent)
        }
        // do not override `hasUnreadNotifications` completely
        if needsYiRNotification {
            hasUnreadNotifications = true
        }
        
        let accessibilityHint = CommonStrings.profileButtonAccessibilityHint
        
        return WMFNavigationBarProfileButtonConfig(accessibilityLabelNoNotifications: CommonStrings.profileButtonTitle, accessibilityLabelHasNotifications: CommonStrings.profileButtonBadgeTitle, accessibilityHint: accessibilityHint, needsBadge: hasUnreadNotifications, target: target, action: action, leadingBarButtonItem: leadingBarButtonItem, trailingBarButtonItem: trailingBarButtonItem)
    }
}
