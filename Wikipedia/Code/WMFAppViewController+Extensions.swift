import UIKit
import WMF

extension WMFAppViewController {

    // MARK: - Language Variant Migration Alerts
    
    @objc internal func presentLanguageVariantAlerts(completion: @escaping () -> Void) {
        
        guard shouldPresentLanguageVariantAlerts else {
            completion()
            return
        }
        
        let savedLibraryVersion = UserDefaults.standard.integer(forKey: WMFLanguageVariantAlertsLibraryVersion)
        guard savedLibraryVersion < MWKDataStore.currentLibraryVersion else {
            completion()
            return
        }
        
        let languageCodesNeedingAlerts = self.dataStore.languageCodesNeedingVariantAlerts(since: savedLibraryVersion)
        guard let firstCode = languageCodesNeedingAlerts.first else {
            completion()
            return
        }
        
        self.presentVariantAlert(for: firstCode, remainingCodes: Array(languageCodesNeedingAlerts.dropFirst()), completion: completion)
            
        UserDefaults.standard.set(MWKDataStore.currentLibraryVersion, forKey: WMFLanguageVariantAlertsLibraryVersion)
    }
    
    private func presentVariantAlert(for languageCode: String, remainingCodes: [String], completion: @escaping () -> Void) {
        
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler
        let secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?
                
        // If there are remaining codes
        if let nextCode = remainingCodes.first {
            
            // If more to show, primary button shows next variant alert
            primaryButtonTapHandler = { _ in
                self.dismiss(animated: true) {
                    self.presentVariantAlert(for: nextCode, remainingCodes: Array(remainingCodes.dropFirst()), completion: completion)
                }
            }
            // And no secondary button
            secondaryButtonTapHandler = nil
            
        } else {
            // If no more to show, primary button navigates to languge settings
            primaryButtonTapHandler = { _ in
                self.displayPreferredLanguageSettings(completion: completion)
            }

            // And secondary button dismisses
            secondaryButtonTapHandler = { _ in
                self.dismiss(animated: true, completion: completion)
            }
        }
                
        let alert = LanguageVariantEducationalPanelViewController(primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: nil, theme: self.theme, languageCode: languageCode)
        self.present(alert, animated: true, completion: nil)
    }
    
    // Don't present over modals or navigation stacks
    // The user is deep linking in these states and we don't want to interrupt them
    private var shouldPresentLanguageVariantAlerts: Bool {
        guard presentedViewController == nil,
              let navigationController = navigationController,
              navigationController.viewControllers.count == 1 &&
                navigationController.viewControllers[0] is WMFAppViewController else {
            return false
        }
        return true
    }

    private func displayPreferredLanguageSettings(completion: @escaping () -> Void) {
        self.dismissPresentedViewControllers()
        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.showExploreFeedCustomizationSettings = true
        languagesVC.userDismissalCompletionBlock = completion
        languagesVC.apply(self.theme)
        let navVC = WMFThemeableNavigationController(rootViewController: languagesVC, theme: theme)
        present(navVC, animated: true, completion: nil)
    }

}

//MARK: Notifications

extension WMFAppViewController: NotificationsCenterPresentationDelegate {

    /// Perform conditional presentation logic depending on origin `UIViewController`
    public func userDidTapNotificationsCenter(from viewController: UIViewController? = nil) {
        let viewModel = NotificationsCenterViewModel(remoteNotificationsController: dataStore.remoteNotificationsController, languageLinkController: self.dataStore.languageLinkController)
        let notificationsCenterViewController = NotificationsCenterViewController(theme: theme, viewModel: viewModel)
        navigationController?.pushViewController(notificationsCenterViewController, animated: true)
    }
}

extension WMFAppViewController {
    @objc func userDidTapPushNotification() {
        
        guard let topMostViewController = self.topMostViewController,
        !topMostViewController.isDisplayingNotificationsCenter else {
            return
        }

        let viewModel = NotificationsCenterViewModel(remoteNotificationsController: dataStore.remoteNotificationsController, languageLinkController: dataStore.languageLinkController)
        let notificationsCenterViewController = NotificationsCenterViewController(theme: theme, viewModel: viewModel)
        
        let dismissAndPushBlock = { [weak self] in
            self?.dismissPresentedViewControllers()
            self?.navigationController?.pushViewController(notificationsCenterViewController, animated: true)
        }

        guard editingFlowIsInHierarchy else {
            dismissAndPushBlock()
            return
        }
        
        presentEditorAlert(on: topMostViewController, confirmationBlock: dismissAndPushBlock)
    }
    
    private var editingFlowIsInHierarchy: Bool {
        var currentController: UIViewController? = navigationController

        while let presentedViewController = currentController?.presentedViewController {
            if let presentedNavigationController = (presentedViewController as? UINavigationController) {
                for viewController in presentedNavigationController.viewControllers {
                    if viewController.isPartOfEditorFlow {
                        return true
                    }
                }
            } else if presentedViewController.isPartOfEditorFlow {
                return true
            }
            
            currentController = presentedViewController
        }

        return false
    }
    
    private var topMostViewController: UIViewController? {
            
        var topViewController: UIViewController = navigationController ?? self

        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        return topViewController
    }
    
    private func presentEditorAlert(on viewController: UIViewController, confirmationBlock: @escaping () -> Void) {
        
        let title = WMFLocalizedString("notifications-push-tap-confirmation-editor-alert-title", value: "Go to Notifications Center?", comment: "Title of navigation to Notifications Center confirmation alert. Presented to the user when they tap a push notification while in an editor flow.")
        let message = WMFLocalizedString("notifications-push-tap-confirmation-editor-alert-message", value: "Are you sure you want to go to Notifications Center? You will lose your editing changes.", comment: "Message of navigation to Notifications Center confirmation alert. Presented to the user when they tap a push notification while in an editor flow.")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let yesAction = UIAlertAction(title: CommonStrings.yesActionTitle, style: .destructive) { _ in
            confirmationBlock()
        }
        let noAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        viewController.present(alertController, animated: true, completion: nil)
        
    }
}

fileprivate extension UIViewController {
    var isPartOfEditorFlow: Bool {
        return (self is SectionEditorViewController ||
                self is InsertLinkViewController ||
                self is InsertMediaViewController ||
                self is EditPreviewViewController ||
                self is InsertMediaSearchResultPreviewingViewController ||
                self is EditSaveViewController ||
                self is DescriptionEditViewController)
    }
    
    var isDisplayingNotificationsCenter: Bool {
        
        if let navigationController = (self as? UINavigationController),
           (navigationController.viewControllers.last as? NotificationsCenterViewController) != nil {
            return true
        }
        
        return false
    }
}
