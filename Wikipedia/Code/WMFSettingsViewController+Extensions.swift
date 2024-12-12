import WMFComponents
import WMFData

@objc extension WMFSettingsViewController: WMFNavigationBarStyling {
    
    @objc func setupNavigationBar(shouldShowProfileBadge: Bool) {
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.settingsTitle, hideTitleView: false, customTitleView: nil)
        
        let profileAccessibilityLabel = shouldShowProfileBadge ? CommonStrings.profileButtonBadgeTitle : CommonStrings.profileButtonTitle
        let profileAccessibilityHint = CommonStrings.profileButtonAccessibilityHint
        
        let closeButtonConfig: WMFNavigationBarCloseButtonConfig?
        let profileButtonConfig: WMFNavigationBarProfileButtonConfig?
        
        // Indicates this is not embedded in the tab view and is presented as a modal. If so, show Close button instead of Profile.
        if self.tabBarController == nil {
            profileButtonConfig = nil
            closeButtonConfig = WMFNavigationBarCloseButtonConfig(accessibilityLabel: CommonStrings.closeButtonAccessibilityLabel, target: self, action: #selector(closeButtonPressed), alignment: .trailing)
        } else {
            closeButtonConfig = nil
            profileButtonConfig = WMFNavigationBarProfileButtonConfig(accessibilityLabel: profileAccessibilityLabel, accessibilityHint: profileAccessibilityHint, needsBadge: shouldShowProfileBadge, target: self, action: #selector(tappedProfile))
        }
        
        setupNavigationBar(style: .largeTitle, hidesBarsOnSwipe: false, titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: profileButtonConfig, searchBarConfig: nil)
    }
    
    @objc func updateProfileButtonObjCWrapper(needsBadge: Bool) {
        
        // Do NOT update if Settings is in modal display and does not have a profile button.
        guard self.tabBarController != nil else {
            return
        }
        
        updateNavBarProfileButton(needsBadge: needsBadge)
    }
    
    @objc func updateCloseButton() {
        updateNavBarCloseButtonTintColor(alignment: .trailing)
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
