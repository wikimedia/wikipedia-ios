import UIKit

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

extension WMFAppViewController: NotificationsCenterPresentationDelegate {

    /// Perform conditional presentation logic depending on origin `UIViewController`
    public func userDidTapNotificationsCenter(from viewController: UIViewController? = nil) {
        let viewModel = NotificationsCenterViewModel(remoteNotificationsController: dataStore.remoteNotificationsController, languageLinkController: self.dataStore.languageLinkController)
        let notificationsCenterViewController = NotificationsCenterViewController(theme: theme, viewModel: viewModel)
        navigationController?.pushViewController(notificationsCenterViewController, animated: true)
    }
}

extension WMFAppViewController {
    
    @objc func willPresentNotification(completion: (UNNotificationPresentationOptions) -> Void) {
        
        if alreadyDisplayingNotificationsCenter() {
            self.dataStore.remoteNotificationsController.loadNotifications(force: true, completion: nil)
            completion(.alert)
            return
        }
        
        let pushTapDebugChoice = UserDefaults.standard.integer(forKey: PushNotificationsTapDebugViewController.key)
        
        switch pushTapDebugChoice {
        case 6:
            if presentedEditorFlowVC() != nil {
                completion([])
                return
            }
        default:
            break
        }
        
        completion(.alert)
    }
    
    func alreadyDisplayingNotificationsCenter() -> Bool {
        if let topMostController = topMostController(),
           let navVC = topMostController.navigationController ?? (topMostController as? UINavigationController),
           let _ = (navVC.viewControllers.last as? NotificationsCenterViewController) {
            return true
        }
        
        return false
    }
    
    @objc func userDidTapPushNotification() {
        
        if alreadyDisplayingNotificationsCenter() {
            return
        }
        
        let pushTapDebugChoice = UserDefaults.standard.integer(forKey: PushNotificationsTapDebugViewController.key)
        
        let viewModel = NotificationsCenterViewModel(remoteNotificationsController: dataStore.remoteNotificationsController, languageLinkController: dataStore.languageLinkController)
        let notificationsCenterViewController = NotificationsCenterViewController(theme: theme, viewModel: viewModel)
        
        switch pushTapDebugChoice {
        case 0:
            let topMostController = topMostController()
            let navVC = (topMostController as? UINavigationController) ?? topMostController?.navigationController ?? self.navigationController
            //TODO: maybe confirm this isn't something small like AlertVCs or our little panel modals
            //This also might require an audit of other modals to make sure they are wrapped up in navigation controllers to be pushed onto.
            navVC?.isNavigationBarHidden = true
            navVC?.pushViewController(notificationsCenterViewController, animated: true)
        case 1:
            let navigationController = WMFThemeableNavigationController(rootViewController: notificationsCenterViewController, theme: theme, style: .sheet)
            navigationController.isNavigationBarHidden = true
            let vcToPresent = topMostController() ?? self
            //TODO: maybe confirm this isn't something small like AlertVCs or our little panel modals
            vcToPresent.present(navigationController, animated: true, completion: nil)
        case 2:
            dismissPresentedViewControllers()
            navigationController?.pushViewController(notificationsCenterViewController, animated: true)
        case 3:
            dismissPresentedViewControllers()
            navigationController?.popToRootViewController(animated: false)
            navigationController?.pushViewController(notificationsCenterViewController, animated: true)
        case 4:
            presentEditorAlertIfNecessary {
                self.dismissPresentedViewControllers()
                self.navigationController?.pushViewController(notificationsCenterViewController, animated: true)
            }
            
        case 5:
            presentEditorAlertIfNecessary {
                self.dismissPresentedViewControllers()
                self.navigationController?.popToRootViewController(animated: false)
                self.navigationController?.pushViewController(notificationsCenterViewController, animated: true)
            }
        case 6:
            dismissPresentedViewControllers()
            navigationController?.popToRootViewController(animated: false)
            navigationController?.pushViewController(notificationsCenterViewController, animated: true)
        default:
            break
        }
    }
    
    func presentEditorAlertIfNecessary(confirmationBlock: @escaping () -> Void) {
        
        if let presentedEditorFlowVC = presentedEditorFlowVC() {
            let ac = UIAlertController(title: "Go to notifications center?", message: "Are you sure you want to go to Notification Center? You will lose your editing changes.", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
                confirmationBlock()
            }
            let noAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                print("tapped cancel")
            }
            
            ac.addAction(yesAction)
            ac.addAction(noAction)
            
            presentedEditorFlowVC.present(ac, animated: true, completion: nil)
            return
        }
        
        confirmationBlock()
    }
    
    func presentedEditorFlowVC() -> UIViewController? {
        
        guard let topMostController = topMostController() else {
            return nil
        }
        
        var loopingTopMostController: UIViewController? = topMostController
        
        while loopingTopMostController != nil {
            
            if let topNavController = ((loopingTopMostController as? UINavigationController) ?? loopingTopMostController?.navigationController) {
                for vc in topNavController.viewControllers.reversed() {
                    if (vc.isPartOfEditorFlow) {
                        return vc
                    }
                }
            }
            
            if (loopingTopMostController?.isPartOfEditorFlow ?? false) {
                return loopingTopMostController
            }
            
            loopingTopMostController = loopingTopMostController?.presentingViewController
        }

        return nil
    }
    
    func topMostController() -> UIViewController? {
        
        var topController: UIViewController = navigationController ?? self

        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }

        return topController
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
}
