import WMFComponents
import WMFData

@objc extension WMFSettingsViewController: WMFNavigationBarStyling {
    
    @objc func styleNavigationBar(shouldShowCloseButton: Bool, shouldShowProfileBadge: Bool) {
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.settingsTitle, hideTitleView: false)
        
        var closeButtonConfig: WMFNavigationBarCloseButtonConfig? = nil
        if shouldShowCloseButton {
            closeButtonConfig = WMFNavigationBarCloseButtonConfig(accessibilityLabel: CommonStrings.closeButtonAccessibilityLabel, target: self, action: #selector(closeButtonPressed), alignment: .trailing)
        }
        
        let profileAccessibilityLabel = shouldShowProfileBadge ? CommonStrings.profileButtonBadgeTitle : CommonStrings.profileButtonTitle
        let profileAccessibilityHint = CommonStrings.profileButtonAccessibilityHint
        let profileButtonConfig = WMFNavigationBarProfileButtonConfig(accessibilityLabel: profileAccessibilityLabel, accessibilityHint: profileAccessibilityHint, needsBadge: shouldShowProfileBadge, target: self, action: #selector(tappedProfile))
        
        setupNavigationBar(style: .largeTitle, titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: profileButtonConfig)
    }
    
    @objc func updateProfileButtonObjCWrapper(needsBadge: Bool) {
        updateProfileButton(needsBadge: needsBadge)
    }
    
    @objc func closeButtonPressed() {
        NavigationEventsFunnel.shared.logTappedSettingsCloseButton()
        dismiss(animated: true)
    }
    
    @objc private func tappedProfile() {
        
        guard let yirDataController = try? WMFYearInReviewDataController(),
        let navigationController else {
            return
        }
        
        let yirCoorrdinator = YearInReviewCoordinator(navigationController: navigationController, theme: self.theme, dataStore: dataStore, dataController: yirDataController)
        let profileCoordinator = ProfileCoordinator(navigationController: navigationController, theme: self.theme, dataStore: dataStore, donateSouce: .settingsProfile, logoutDelegate: self, sourcePage: .exploreOptOut, yirCoordinator: yirCoorrdinator)
        
        let metricsID = DonateCoordinator.metricsID(for: .settingsProfile, languageCode: dataStore.languageLinkController.appLanguage?.languageCode)
        
        if let metricsID {
            DonateFunnel.shared.logExploreOptOutProfileClick(metricsID: metricsID)
        }
        
        self.profileCoordinator = profileCoordinator
        profileCoordinator.start()
    }
}

extension WMFSettingsViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {
        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: self.theme) { [weak self] in
            self?.dataStore.authenticationManager.logout(initiatedBy: .user, completion: {
                // no-op
            })
        }
    }
}
