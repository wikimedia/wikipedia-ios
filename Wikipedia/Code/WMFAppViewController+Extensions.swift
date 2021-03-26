import UIKit

extension WMFAppViewController {

    // MARK: - Language Variant Migration Alerts
    
    @objc public var presentLanguageVariantAlerts: () -> Void {
        {
            let savedLibraryVersion = UserDefaults.standard.integer(forKey: WMFLanguageVariantAlertsLibraryVersion)
            guard savedLibraryVersion < MWKDataStore.currentLibraryVersion else { return }
            
            let languageCodesNeedingAlerts = self.dataStore.languageCodesNeedingVariantAlerts(since: savedLibraryVersion)
            
            if let firstCode = languageCodesNeedingAlerts.first {
                self.presentVariantAlert(for: firstCode, remainingCodes: Array(languageCodesNeedingAlerts.dropFirst()))
            }
            UserDefaults.standard.set(MWKDataStore.currentLibraryVersion, forKey: WMFLanguageVariantAlertsLibraryVersion)
        }
    }
    
    private func presentVariantAlert(for languageCode: String, remainingCodes: [String]) {
        
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler
        let secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?
                
        // If there are remaining codes
        if let nextCode = remainingCodes.first {
            
            // If more to show, primary button shows next variant alert
            primaryButtonTapHandler = { _ in
                self.dismiss(animated: true) {
                    self.presentVariantAlert(for: nextCode, remainingCodes: Array(remainingCodes.dropFirst()))
                }
            }
            // And no secondary button
            secondaryButtonTapHandler = nil
            
        } else {
            // If no more to show, primary button navigates to languge settings
            primaryButtonTapHandler = { _ in
                self.displayPreferredLanguageSettings()
            }

            // And secondary button dismisses
            secondaryButtonTapHandler = { _ in
                self.dismiss(animated: true, completion: nil)
            }
        }
                
        let alert = LanguageVariantEducationalPanelViewController(primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: nil, theme: self.theme, languageCode: languageCode)
        self.present(alert, animated: true, completion: nil)
    }

    private func displayPreferredLanguageSettings() {
        self.dismissPresentedViewControllers()
        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.showExploreFeedCustomizationSettings = true
        languagesVC.apply(self.theme)
        let navVC = WMFThemeableNavigationController(rootViewController: languagesVC, theme: theme)
        present(navVC, animated: true, completion: nil)
    }

}
