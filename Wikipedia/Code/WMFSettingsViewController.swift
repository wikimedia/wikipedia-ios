import Foundation
import WMF

@objc
internal class WMFSettingsViewController: ViewController, UITableViewDelegate, UITableViewDataSource, AccountViewControllerDelegate, WMFPreferredLanguagesViewControllerDelegate {

    private let kvo_WMFSettingsViewController_authManager_loggedInUsername: UnsafeMutableRawPointer? = nil

    // MARK: Static URLs

    // TODO: Change to https://foundation.m.wikimedia.org/wiki/Special:MyLanguage/Terms_of_Use?
    private let WMFSettingsURLTerms = "https://foundation.m.wikimedia.org/wiki/Terms_of_Use/en"
    private let WMFSettingsURLRate = "itms-apps://itunes.apple.com/app/id324715238"
    private let WMFSettingsURLDonation = "https://donate.wikimedia.org/?utm_medium=WikipediaApp&utm_campaign=iOS"
    
    private var dataStore: MWKDataStore?
    private var sections: NSMutableArray?
    @IBOutlet private var tableView: UITableView?
    
    override var scrollView: UIScrollView? {
        get {
            return tableView
        }
        set {
        }
    }
    
    override var title: String? {
        get {
            return CommonStrings.settingsTitle
        }
        set {
        }
    }
    
    private var authManager: WMFAuthenticationManager? {
        get {
            return _authManager
        }
        set(newAuthManager) {
            if (_authManager == newAuthManager) {
                return
            }
            _authManager?.removeObserver(self, forKeyPath: "loggedInUsername", context: kvo_WMFSettingsViewController_authManager_loggedInUsername)
            _authManager = newAuthManager
            _authManager?.addObserver(self, forKeyPath: "loggedInUsername", options: [.initial, .new], context: kvo_WMFSettingsViewController_authManager_loggedInUsername)
        }
    }
    private var _authManager: WMFAuthenticationManager?
    
    
    // MARK: Deinitializer
    
    deinit {
        authManager = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: Objective-C entrypoint
    
    @objc static func settingsViewController(dataStore: MWKDataStore) -> WMFSettingsViewController? {
        guard let vc = WMFSettingsViewController.wmf_initialViewControllerFromClassStoryboard() else {
            return nil
        }
        vc.dataStore = dataStore
        return vc
    }
    
    
    
    // MARK: Setup
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let tv = tableView else {
            return
        }
        tv.delegate = self
        tv.dataSource = self
        
        tv.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        
        tv.estimatedRowHeight = 52.0
        tv.rowHeight = UITableView.automaticDimension
        
        authManager = dataStore?.authenticationManager
        navigationBar.displayType = NavigationBarDisplayType.largeTitle
        
#if UI_TEST
        if (UserDefaults.standard.wmf_isFastlaneSnapshotInProgress()) {
            tv.decelerationRate = UIScrollViewDecelerationRate.fast
        }
#endif
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_settingsView())
    }

    public override func viewWillAppear(_ animated: Bool) {
        showCloseButton(shouldShowCloseButton: tabBarController == nil)
        navigationController?.isNavigationBarHidden = true
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
        loadSections()
    }
    
    private func configureBackButton() {
        if (navigationItem.rightBarButtonItem != nil) {
            return
        }
        let xButton = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(closeButtonPressed))
        navigationItem.rightBarButtonItem = xButton
    }
    
    private func showCloseButton(shouldShowCloseButton: Bool) {
        if (shouldShowCloseButton) {
            configureBackButton()
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc private func closeButtonPressed() {
        NavigationEventsFunnel.shared.logTappedSettingsCloseButton()
        dismiss(animated: true, completion: nil)
    }
    
    override public func accessibilityPerformEscape() -> Bool {
        closeButtonPressed()
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier, for: indexPath) as! WMFSettingsTableViewCell
        let menuItems = (sections?[indexPath.section] as! SettingsTableViewSection).getItems()
        let menuItem = menuItems[indexPath.item]
        
        cell.tag = Int(menuItem.type.rawValue)
        cell.title = menuItem.title
        cell.apply(theme)
        if (theme.colors.icon == nil) {
            cell.iconColor = .white
            cell.iconBackgroundColor = menuItem.iconColor
        }
        cell.iconName = menuItem.iconName
        cell.disclosureType = menuItem.disclosureType
        cell.disclosureText = menuItem.disclosureText
        cell.disclosureSwitch.setOn(menuItem.isSwitchOn, animated: false)
        cell.selectionStyle = (menuItem.disclosureType == .switch) ? .none : .default
        
        if (menuItem.disclosureType != .switch && menuItem.disclosureType != .none) {
            cell.accessibilityTraits = UIAccessibilityTraits.button
        } else {
            cell.accessibilityTraits = UIAccessibilityTraits.staticText
        }
        
        cell.disclosureSwitch.removeTarget(self, action: #selector(disclosureSwitchChanged), for: .valueChanged)
        cell.disclosureSwitch.tag = Int(menuItem.type.rawValue)
        cell.disclosureSwitch.addTarget(self, action: #selector(disclosureSwitchChanged), for: .valueChanged)
        
        return cell
    }
    
    @objc private func disclosureSwitchChanged(disclosureSwitch: UISwitch) {
        guard let type = WMFSettingsMenuItemType(rawValue: UInt(disclosureSwitch.tag)) else {
            return
        }
        updateStateForMenuItemType(type: type, isSwitchOnValue: disclosureSwitch.isOn)
        logNavigationEventsForMenuItemType(type: type)
        loadSections()
    }
    
    
    // MARK: Switch tap handling
    
    private func updateStateForMenuItemType(type: WMFSettingsMenuItemType, isSwitchOnValue isOn: Bool) {
        switch type {
        case .sendUsageReports:
            UserDefaults.standard.wmf_sendUsageReports = isOn
            if (isOn) {
                EventLoggingService.shared?.reset()
                EventPlatformClient.shared.reset()
                WMFDailyStatsLoggingFunnel.shared()?.logAppNumberOfDaysSinceInstall()
                SessionsFunnel.shared.logSessionStart()
                UserHistoryFunnel.shared.logStartingSnapshot()
                break
            } else {
                SessionsFunnel.shared.logSessionEnd()
                UserHistoryFunnel.shared.logSnapshot()
                EventLoggingService.shared?.reset()
                EventPlatformClient.shared.reset()
                break
            }
        default:
            break
        }
    }
    
    private func logNavigationEventsForMenuItemType(type: WMFSettingsMenuItemType) {
        switch type {
        case .loginAccount:
            NavigationEventsFunnel.shared.logTappedSettingsLoginLogout()
            break
        case .searchLanguage:
            NavigationEventsFunnel.shared.logTappedSettingsLanguages()
            break
        case .search:
            NavigationEventsFunnel.shared.logTappedSettingsSearch()
            break
        case .exploreFeed:
            NavigationEventsFunnel.shared.logTappedSettingsExploreFeed()
            break
        case .notifications:
            NavigationEventsFunnel.shared.logTappedSettingsNotifications()
            break
        case .appearance:
            NavigationEventsFunnel.shared.logTappedSettingsReadingPreferences()
            break
        case .storageAndSyncing:
            NavigationEventsFunnel.shared.logTappedSettingsArticleStorageAndSyncing()
            break
        case .storageAndSyncingDebug:
            NavigationEventsFunnel.shared.logTappedSettingsReadingListDangerZone()
            break
        case .support:
            NavigationEventsFunnel.shared.logTappedSettingsSupportWikipedia()
            break
        case .privacyPolicy:
            NavigationEventsFunnel.shared.logTappedSettingsPrivacyPolicy()
            break
        case .terms:
            NavigationEventsFunnel.shared.logTappedSettingsTermsOfUse()
            break
        case .rateApp:
            NavigationEventsFunnel.shared.logTappedSettingsRateTheApp()
            break
        case .sendFeedback:
            NavigationEventsFunnel.shared.logTappedSettingsHelp()
            break
        case .about:
            NavigationEventsFunnel.shared.logTappedSettingsAbout()
            break
        case .clearCache:
            NavigationEventsFunnel.shared.logTappedSettingsClearCachedData()
            break
        case .sendUsageReports:
            NavigationEventsFunnel.shared.logTappedSettingsSendUsageReports()
            break
        default:
            break
        }
    }
    
    
    // MARK: Cell tap handling
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath), let type = WMFSettingsMenuItemType(rawValue: UInt(cell.tag)) else {
            return
        }
        switch (type) {
        case .loginAccount:
            showLoginOrAccount()
            break
        case .searchLanguage:
            showLanguages()
            break
        case .search:
            showSearch()
            break
        case .exploreFeed:
            showExploreFeedSettings()
            break
        case .notifications:
            showNotifications()
            break
        case .appearance:
            showAppearance()
            break
        case .storageAndSyncing:
            showStorageAndSyncing()
            break
        case .storageAndSyncingDebug:
            showStorageAndSyncingDebug()
            break
        case .support:
            navigate(to: donationURL(), useSafari: true)
            break
        case .privacyPolicy:
            navigate(to: URL(string: CommonStrings.privacyPolicyURLString))
            break
        case .terms:
            navigate(to: URL(string: WMFSettingsURLTerms))
            break
        case .rateApp:
            navigate(to: URL(string: WMFSettingsURLRate), useSafari: true)
            break
        case .sendFeedback:
            guard let ds = dataStore, let vc = HelpViewController(dataStore: ds, theme: theme) else {
                break
            }
            navigationController?.pushViewController(vc, animated: true)
            break
        case .about:
            guard let vc = AboutViewController(theme: theme) else {
                break
            }
            navigationController?.pushViewController(vc, animated: true)
            break
        case .clearCache:
            showClearCacheActionSheet()
            break
        default:
            break
        }
        
        if (type != .sendUsageReports) { //logged elsewhere via disclosureSwitchChanged:
            logNavigationEventsForMenuItemType(type: type);
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // MARK: Dynamic URLs
    
    private func donationURL() -> URL {
        var url = WMFSettingsURLDonation
        if let appVersion = Bundle.main.wmf_debugVersion() {
            url += "&utm_source=\(appVersion)"
        }
        if let languageCode = MWKDataStore.shared().languageLinkController.appLanguage?.languageCode {
            url += "&uselang=\(languageCode)"
        }
        return URL(string: url)!
    }
    
    
    // MARK: Presentation
    
    private func presentViewControllerWrappedInNavigationController(viewController: UIViewController) {
        let themeableNavController = WMFThemeableNavigationController(rootViewController: viewController, theme: theme, style: .sheet)
        present(themeableNavController, animated: true, completion: nil)
    }
    
    
    // MARK: Log in and out
    
    private func showLoginOrAccount() {
        let userName = dataStore?.authenticationManager.loggedInUsername
        if userName != nil {
            let accountVC = AccountViewController()
            accountVC.dataStore = dataStore
            accountVC.delegate = self;
            accountVC.apply(theme: theme)
            navigationController?.pushViewController(accountVC, animated: true)
        } else {
            guard let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard() else {
                return
            }
            loginVC.apply(theme: theme)
            presentViewControllerWrappedInNavigationController(viewController: loginVC)
            LoginFunnel.shared.logLoginStartInSettings()
        }
    }
    
    
    // MARK: Clear cache
    
    private func showClearCacheActionSheet() {
        var message = WMFLocalizedStringWithDefaultValue("settings-clear-cache-are-you-sure-message", nil, nil, "Clearing cached data will free up about %1$@ of space. It will not delete your saved pages.", "Message for the confirmation presented to the user to verify they are sure they want to clear clear cached data. %1$@ is replaced with the approximate file size in bytes that will be made available. Also explains that the action will not delete their saved pages.")
        
        let bytesString = ByteCountFormatter.string(fromByteCount: Int64(URLCache.shared.currentDiskUsage), countStyle: .file)
        message = String.localizedStringWithFormat(message, bytesString)

        let sheet = UIAlertController(title: WMFLocalizedStringWithDefaultValue("settings-clear-cache-are-you-sure-title", nil, nil, "Clear cached data?", "Title for the confirmation presented to the user to verify they are sure they want to clear clear cached data."), message: message, preferredStyle: .alert)
        
        sheet.addAction(UIAlertAction(title: WMFLocalizedStringWithDefaultValue("settings-clear-cache-ok", nil, nil, "Clear cache", "Confirm action to clear cached data"), style: .destructive) { action in
            self.dataStore?.clearTemporaryCache()
        })
        
        sheet.addAction(UIAlertAction(title: WMFLocalizedStringWithDefaultValue("settings-clear-cache-cancel", nil, nil, "Cancel", "Cancel action to clear cached data {{Identical|Cancel}}"), style: .cancel, handler: nil))

        present(sheet, animated: true, completion: nil)
    }
    
    private func logout() {
        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: KeepSavedArticlesTrigger.logout, theme: theme) {
            self.dataStore?.authenticationManager.logout(initiatedBy: WMFAuthenticationManager.LogoutInitiator.user) {
                LoginFunnel.shared.logLogoutInSettings()
            }
        }
    }
    
    // MARK: Languages
    
    private func showLanguages() {
        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.showExploreFeedCustomizationSettings = true;
        languagesVC.delegate = self;
        languagesVC.apply(theme)
        presentViewControllerWrappedInNavigationController(viewController: languagesVC)
    }
    
    func languagesController(_ controller: WMFPreferredLanguagesViewController, didUpdatePreferredLanguages languages: Array<MWKLanguageLink>) {
        UserDefaults.standard.wmf_setShowSearchLanguageBar(languages.count > 1)
        loadSections()
    }
    
    // MARK: Search
    
    private func showSearch() {
        let searchSettingsViewController = SearchSettingsViewController()
        searchSettingsViewController.apply(theme: theme)
        navigationController?.pushViewController(searchSettingsViewController, animated: true)
    }
    
    // MARK: Feed
    
    private func showExploreFeedSettings() {
        let feedSettingsVC = ExploreFeedSettingsViewController()
        feedSettingsVC.dataStore = dataStore
        feedSettingsVC.apply(theme: theme)
        navigationController?.pushViewController(feedSettingsVC, animated: true)
    }
    
    // MARK: Notifications
    
    private func showNotifications() {
        let notificationSettingsVC = NotificationSettingsViewController()
        notificationSettingsVC.apply(theme: theme)
        navigationController?.pushViewController(notificationSettingsVC, animated: true)
    }
    
    // MARK: Appearance
    
    private func showAppearance() {
        let appearanceSettingsVC = AppearanceSettingsViewController()
        appearanceSettingsVC.apply(theme: theme)
        navigationController?.pushViewController(appearanceSettingsVC, animated: true)
    }
    
    // MARK: Storage and syncing
    
    private func showStorageAndSyncing() {
        let storageAndSyncingSettingsVC = StorageAndSyncingSettingsViewController()
        storageAndSyncingSettingsVC.dataStore = dataStore
        storageAndSyncingSettingsVC.apply(theme: theme)
        navigationController?.pushViewController(storageAndSyncingSettingsVC, animated: true)
    }
    
    private func showStorageAndSyncingDebug() {
#if DEBUG
        let vc = DebugReadingListsViewController(nibName: "DebugReadingListsViewController", bundle: nil)
        presentViewControllerWrappedInNavigationController(viewController: vc)
#endif
    }
    
    
    // MARK: Cell reloading
    
    private func indexPathForVisibleCellOfType(type: WMFSettingsMenuItemType) -> IndexPath? {
        guard let indexPaths = tableView?.indexPathsForVisibleRows as NSArray? else {
            return nil
        }
        return indexPaths.wmf_match { (rawIndexPath: Any) -> Bool in
            guard let indexPath = rawIndexPath as? IndexPath,
                  let cell = self.tableView?.cellForRow(at: indexPath),
                  let foundType = WMFSettingsMenuItemType(rawValue: UInt(cell.tag)) else {
                return false
            }
            return foundType == type
        } as? IndexPath
    }
    
    
    // MARK: Sections structure
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections != nil ? sections!.count : 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let _sections = sections else {
            return 0
        }
        let items = (_sections[section] as! SettingsTableViewSection).getItems()
        return items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let _sections = sections,
              let _section: Any? = _sections[section],
              let tableViewSection = _section as? SettingsTableViewSection else {
            return nil
        }
        return tableViewSection.getHeaderTitle()
    }
    
    @objc func loadSections() {
        sections = NSMutableArray()
        sections!.add(section1())
        sections!.add(section2())
        sections!.add(section3())
        sections!.add(section4())
        tableView?.reloadData()
    }
    
    
    // MARK: Section structure
    
    private func section1() -> SettingsTableViewSection {
        return SettingsTableViewSection(items: [WMFSettingsMenuItem(for: WMFSettingsMenuItemType.loginAccount),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.support)],
                                             headerTitle: nil,
                                             footerText: nil)
    }
    
    private func section2() -> SettingsTableViewSection {
#if DEBUG
        return SettingsTableViewSection(items: [WMFSettingsMenuItem(for: WMFSettingsMenuItemType.searchLanguage),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.search),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.exploreFeed),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.notifications),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.appearance),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.storageAndSyncing),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.storageAndSyncingDebug),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.clearCache)],
                                        headerTitle: nil,
                                        footerText: nil)
#endif
        return SettingsTableViewSection(items: [WMFSettingsMenuItem(for: WMFSettingsMenuItemType.searchLanguage),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.search),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.exploreFeed),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.notifications),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.appearance),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.storageAndSyncing),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.clearCache)],
                                        headerTitle: nil,
                                        footerText: nil)
    }
    
    private func section3() -> SettingsTableViewSection {
        let headerTitle = WMFLocalizedStringWithDefaultValue("main-menu-heading-legal", nil, nil, "Privacy and Terms", "Header text for the legal section of the menu. Consider using something informal, but feel free to use a more literal translation of \"Legal info\" if it seems more appropriate.")
        let footerText = WMFLocalizedStringWithDefaultValue("preference-summary-eventlogging-opt-in", nil, nil, "Allow Wikimedia Foundation to collect information about how you use the app to make the app better", "Description of preference that when checked enables data collection of user behavior.")
        return SettingsTableViewSection(items: [WMFSettingsMenuItem(for: WMFSettingsMenuItemType.privacyPolicy),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.terms),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.sendUsageReports)],
                                        headerTitle: headerTitle,
                                        footerText: footerText)
    }
    
    private func section4() -> SettingsTableViewSection {
        return SettingsTableViewSection(items: [WMFSettingsMenuItem(for: WMFSettingsMenuItemType.rateApp),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.sendFeedback),
                                                WMFSettingsMenuItem(for: WMFSettingsMenuItemType.about)],
                                             headerTitle: nil,
                                             footerText: nil)
    }
    
    
    // MARK: Scroll view
    
    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidScroll(scrollView)
    }

    public override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewWillBeginDragging(scrollView)
    }

    public override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        navigationBarHider.scrollViewWillEndDragging(scrollView, withVelocity: withVelocity, targetContentOffset: targetContentOffset)
    }

    public override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidEndDecelerating(scrollView)
    }

    public override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidEndScrollingAnimation(scrollView)
    }

    public override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        navigationBarHider.scrollViewWillScrollToTop(scrollView)
        return true;
    }

    public override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidScrollToTop(scrollView)
    }
    
    
    // MARK: KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (context == kvo_WMFSettingsViewController_authManager_loggedInUsername) {
            DispatchQueue.main.async {
                self.loadSections()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    
    // MARK: Themeable
    
    public override func apply(theme: Theme) {
        super.apply(theme: theme)
        if (viewIfLoaded == nil) {
            return
        }
        tableView?.backgroundColor = theme.colors.baseBackground;
        tableView?.indicatorStyle = theme.scrollIndicatorStyle;
        view.backgroundColor = theme.colors.baseBackground;
        loadSections()
    }
    

    // MARK: WMFAccountViewControllerDelegate
    
    func accountViewControllerDidTapLogout(_ accountViewController: AccountViewController) {
        logout()
        loadSections()
    }
    
}
