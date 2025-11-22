import WMFComponents
import WMFData

@objc extension WMFSettingsViewController: WMFNavigationBarConfiguring, WMFNavigationBarHiding {

    @objc func configureNavigationBarFromObjC() {
        
        let numUnreadNotifications = (try? dataStore.remoteNotificationsController.numberOfUnreadNotifications().intValue) ?? 0
        let needsProfileBadge = numUnreadNotifications != 0
        
        var titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.settingsTitle, customView: nil, alignment: .leadingCompact)
        extendedLayoutIncludesOpaqueBars = false
        if #available(iOS 18, *) {
           if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
               titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.settingsTitle, customView: nil, alignment: .leadingLarge)
               extendedLayoutIncludesOpaqueBars = true
           }
        }

        let profileAccessibilityHint = CommonStrings.profileButtonAccessibilityHint
        
        let closeButtonConfig: WMFNavigationBarCloseButtonConfig?
        let profileButtonConfig: WMFNavigationBarProfileButtonConfig?
        
        // Indicates this is not embedded in the tab view and is presented as a modal. If so, show Close button instead of Profile.
        if self.tabBarController == nil {
            profileButtonConfig = nil
            closeButtonConfig = WMFNavigationBarCloseButtonConfig(text: CommonStrings.doneTitle, target: self, action: #selector(closeButtonPressed), alignment: .trailing)
        } else {
            closeButtonConfig = nil
            profileButtonConfig = WMFNavigationBarProfileButtonConfig(accessibilityLabelNoNotifications: CommonStrings.profileButtonTitle, accessibilityLabelHasNotifications: CommonStrings.profileButtonBadgeTitle, accessibilityHint: profileAccessibilityHint, needsBadge: needsProfileBadge, target: self, action: #selector(tappedProfile), leadingBarButtonItem: nil)
        }
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: profileButtonConfig, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: true)
    }
    
    @objc func updateProfileButtonFromObjC() {
        
        // Do NOT update if Settings is in modal display and does not have a profile button.
        guard self.tabBarController != nil else {
            return
        }
        
        let numUnreadNotifications = (try? dataStore.remoteNotificationsController.numberOfUnreadNotifications().intValue) ?? 0
        let needsBadge = numUnreadNotifications != 0
        
        updateNavigationBarProfileButton(needsBadge: needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }
    
    @objc func themeNavigationBarLeadingTitleViewFromObjC() {
        themeNavigationBarLeadingTitleView()
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
    
    @objc func setupTopSafeAreaOverlayFromObjC(scrollView: UIScrollView) {
        setupTopSafeAreaOverlay(scrollView: scrollView)
    }
    
    @objc func themeTopSafeAreaOverlayFromObjC(scrollView: UIScrollView) {
        themeTopSafeAreaOverlay()
    }
    
    @objc func calculateTopSafeAreaOverlayHeightFromObjC() {
        calculateTopSafeAreaOverlayHeight()
    }
    
    @objc func calculateNavigationBarHiddenStateFromObjC(scrollView: UIScrollView) {
        calculateNavigationBarHiddenState(scrollView: scrollView)
    }
    
    @objc func tappedDatabasePopulation() {
        let vc = DatabasePopulationHostingController()
        let navVC = WMFComponentNavigationController(rootViewController: vc, modalPresentationStyle: .pageSheet)
        present(navVC, animated: true)
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
