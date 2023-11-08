import UIKit
import SwiftUI
import WMF
import Components
import WKData

@objc(WMFAccountViewControllerDelegate)
protocol AccountViewControllerDelegate: AnyObject {
    func accountViewControllerDidTapLogout(_ accountViewController: AccountViewController)
}

extension Notification.Name {
    static let seatOnboardingDidTapLearnMore = Notification.Name("WMFSEATOnboardingDidTapLearnMoreForeground")
    static let seatOnboardingDidTapViewExamples = Notification.Name("WMFSEATOnboardingDidTapViewExamples")
}

private enum ItemType {
    case logout
    case talkPage
    case talkPageAutoSignDiscussions
    case watchlist
    case suggestedEdits
    case vanishAccount
}

private struct Section {
    let items: [Item]
    let headerTitle: String?
    let footerTitle: String?
}

private struct Item {
    let title: String
    let subtitle: String?
    let iconName: String?
    let iconColor: UIColor?
    let iconBackgroundColor: UIColor?
    let type: ItemType
}

@objc(WMFAccountViewController)
class AccountViewController: SubSettingsViewController {
    
    @objc var dataStore: MWKDataStore!
    @objc weak var delegate: AccountViewControllerDelegate?
    
    var isPresentingSuggestedEdits = false

    private lazy var sections: [Section] = {
        
        guard let username = dataStore.authenticationManager.loggedInUsername else {
            assertionFailure("Should not reach this screen if user isn't logged in.")
            return []
        }
        
        let logout = Item(title: username, subtitle: CommonStrings.logoutTitle, iconName: "settings-user", iconColor: .white, iconBackgroundColor: UIColor.orange600, type: .logout)
        let talkPage = Item(title: WMFLocalizedString("account-talk-page-title", value: "Your talk page", comment: "Title for button and page letting user view their account page."), subtitle: nil, iconName: "settings-talk-page", iconColor: .white, iconBackgroundColor: .blue600 , type: .talkPage)
        let watchlist = Item(title: CommonStrings.watchlist, subtitle: nil, iconName: "watchlist", iconColor: .white, iconBackgroundColor: .yellow600, type: .watchlist)

        let seatTitle = WMFLocalizedString("seat-title", value: "Suggested edits", comment: "Title of suggested edits feature.")

        let suggestedEdits = Item(title: seatTitle, subtitle: nil, iconName: "se-pencil", iconColor: .white, iconBackgroundColor: .green600, type: .suggestedEdits)

        let vanishAccount = Item(title: CommonStrings.vanishAccount, subtitle: nil, iconName: "vanish-account", iconColor: .white, iconBackgroundColor: .red, type: .vanishAccount)

        let sectionItems: [Item]
        if FeatureFlags.suggestedEditsAltTextEnabled {
            sectionItems = [logout, talkPage, watchlist, suggestedEdits, vanishAccount]
        } else {
            sectionItems = [logout, talkPage, watchlist, vanishAccount]
        }

        let account = Section(items: sectionItems, headerTitle: WMFLocalizedString("account-group-title", value: "Your Account", comment: "Title for account group on account settings screen."), footerTitle: nil)

        let autoSignDiscussions = Item(title: WMFLocalizedString("account-talk-preferences-auto-sign-discussions", value: "Auto-sign discussions", comment: "Title for talk page preference that configures adding signature to new posts"), subtitle: nil, iconName: nil, iconColor: nil, iconBackgroundColor: nil, type: .talkPageAutoSignDiscussions)
        let talkPagePreferences = Section(items: [autoSignDiscussions], headerTitle: WMFLocalizedString("account-talk-preferences-title", value: "Talk page preferences", comment: "Title for talk page preference sections in account settings"), footerTitle: WMFLocalizedString("account-talk-preferences-auto-sign-discussions-setting-explanation", value: "Auto-signing of discussions will use the signature defined in Signature settings", comment: "Text explaining how setting the auto-signing of talk page discussions preference works"))

        return [account, talkPagePreferences]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.account
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        tableView.register(WMFTableHeaderFooterLabelView.wmf_classNib(), forHeaderFooterViewReuseIdentifier: WMFTableHeaderFooterLabelView.identifier)
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = 44
        
        NotificationCenter.default.addObserver(self, selector: #selector(didTapSEATOnboardingLearnMore), name: .seatOnboardingDidTapLearnMore, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didTapSEATOnboardingViewExamples), name: .seatOnboardingDidTapViewExamples, object: nil)
    }
    
    @objc private func didTapSEATOnboardingLearnMore() {
        guard let url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_Suggested_edits") else {
            return
        }
        
        SEATFunnel.shared.logSEATLearnMoreWebViewImpression()
        navigationController?.navigate(to: url, useSafari: true)
    }

    @objc private func didTapSEATOnboardingViewExamples() {
        guard let url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_Suggested_edits#Alt_Text_Examples") else {
            return
        }

        SEATFunnel.shared.logSEATLearnMoreWebViewImpression()
        navigationController?.navigate(to: url, useSafari: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[safeIndex: section]?.items.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier, for: indexPath) as? WMFSettingsTableViewCell,
            let item = sections[safeIndex: indexPath.section]?.items[safeIndex: indexPath.row] else {
                return UITableViewCell()
        }
        
        cell.iconName = item.iconName
        cell.iconColor = item.iconColor
        cell.iconBackgroundColor = item.iconBackgroundColor
        cell.title = item.title
        
        switch item.type {
        case .logout:
            cell.disclosureType = .viewControllerWithDisclosureText
            cell.disclosureText = item.type == .logout ? CommonStrings.logoutTitle : nil
            cell.accessibilityTraits = .button
        case .talkPage:
            cell.disclosureType = .viewController
            cell.disclosureText = nil
            cell.accessibilityTraits = .button
        case .talkPageAutoSignDiscussions:
            cell.disclosureType = .switch
            cell.selectionStyle = .none
            cell.disclosureSwitch.isOn = UserDefaults.standard.autoSignTalkPageDiscussions
            cell.disclosureSwitch.addTarget(self, action: #selector(autoSignTalkPageDiscussions(_:)), for: .valueChanged)
        case .watchlist:
            cell.disclosureType = .viewController
            cell.accessibilityTraits = .button
        case .suggestedEdits:
            cell.disclosureType = .viewController
            cell.accessibilityTraits = .button
        case .vanishAccount:
            cell.disclosureType = .viewController
            cell.accessibilityTraits = .button
        }
        
        cell.apply(theme)
        
        return cell
    }

    @objc private func autoSignTalkPageDiscussions(_ sender: UISwitch) {
        UserDefaults.standard.autoSignTalkPageDiscussions = sender.isOn
    }
    
    @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        guard let item = sections[safeIndex: indexPath.section]?.items[safeIndex: indexPath.row] else {
            return
        }
        switch item.type {
        case .logout:
            showLogoutAlert()
        case .talkPage:
            guard let username = dataStore.authenticationManager.loggedInUsername,
                  let siteURL = dataStore.primarySiteURL else {
                return
            }
            
            let title = TalkPageType.user.titleWithCanonicalNamespacePrefix(title: username, siteURL: siteURL)

                if let viewModel = TalkPageViewModel(pageType: .user, pageTitle: title, siteURL: siteURL, source: .account, articleSummaryController: dataStore.articleSummaryController, authenticationManager: dataStore.authenticationManager, languageLinkController: dataStore.languageLinkController) {
                    let newTalkPage = TalkPageViewController(theme: theme, viewModel: viewModel)
                    self.navigationController?.pushViewController(newTalkPage, animated: true)
                }
        case .watchlist:
            WatchlistFunnel.shared.logOpenWatchlistFromAccount()
            goToWatchlist()

        case .suggestedEdits:
            
            SEATFunnel.shared.logSettingsDidTapSEAT()
            
            let dataController = WKSEATDataController.shared
            guard let appLanguageSiteURL = dataStore.languageLinkController.appLanguage?.siteURL,
               let project = WikimediaProject(siteURL: appLanguageSiteURL),
                  let wkProject = project.wkProject else {
                return
            }
            
            if dataController.isLoading,
               let cell = tableView.cellForRow(at: indexPath) as? WMFSettingsTableViewCell {
                cell.isLoading = true
            }

            switch wkProject {
            case .wikipedia(let wKLanguage):
                switch wKLanguage.languageCode {
                case "en":
                    SEATSampleData.shared.surveyURL = .en
                    SEATSampleData.shared.privacyURL = .en
                case "es":
                    SEATSampleData.shared.surveyURL = .es
                    SEATSampleData.shared.privacyURL = .es
                case "pt":
                    SEATSampleData.shared.surveyURL = .pt
                    SEATSampleData.shared.privacyURL = .pt
                default:
                    SEATSampleData.shared.surveyURL = .en
                    SEATSampleData.shared.privacyURL = .en
                }
            default:
                SEATSampleData.shared.surveyURL = .en
                SEATSampleData.shared.privacyURL = .en
            }

            dataController.generateSampleData(project: wkProject) { [weak self] in
                
                guard let self else {
                    return
                }
                
                guard let sampleData = dataController.sampleData[wkProject] else {
                    return
                }
                
                let viewModels: [SEATItemViewModel] = sampleData.compactMap { wkItem in
                    
                    guard let articleSummary = wkItem.articleSummary,
                          let imageWikitext = wkItem.imageWikitext,
                          let imageWikitextFilename = wkItem.imageWikitextFileName,
                          let imageCommonsFileName = wkItem.imageCommonsFileName,
                          let imageWikitextLocation = wkItem.imageWikitextLocation,
                          let articleURL = wkItem.articleURL,
                          let imageDetailsURL = wkItem.imageDetailsURL else {
                        return nil
                    }
                    
                    // filter out gifs for now, animated gifs fail to load
                    if imageWikitextFilename.contains(".gif") {
                        return nil
                    }
                    
                    return SEATItemViewModel(project: wkItem.project, articleTitle: wkItem.articleTitle, articleWikitext: wkItem.articleWikitext, articleDescription: wkItem.articleDescription, articleSummary: articleSummary, imageWikitext: imageWikitext, imageWikitextFilename: imageWikitextFilename, imageCommonsFilename: imageCommonsFileName, imageThumbnailURLs: wkItem.imageThumbnailURLs, imageWikitextLocation: imageWikitextLocation, imageDetailsURL: imageDetailsURL, articleURL: articleURL)
                }
                
                SEATSampleData.shared.availableTasks = viewModels
                
                if let cell = self.tableView.cellForRow(at: indexPath) as? WMFSettingsTableViewCell {
                    cell.isLoading = false
                }
                
                if !UserDefaults.standard.wmf_userHasOnboardedToSEAT {
                    self.showSEATOnboarding()
                } else {
                    self.goToSEAT()
                }
            }
        case .vanishAccount:
            let warningViewController = VanishAccountWarningViewHostingViewController(theme: theme)
            warningViewController.delegate = self
            present(warningViewController, animated: true)
        default:
            break
        }
    }
    
    func showSEATOnboarding() {
        let item1 = WKOnboardingViewModel.WKOnboardingCellViewModel(icon: UIImage(named: "SEAT/seat-onboarding-1"), title: CommonStrings.seatOnboardingItem1Header, subtitle: CommonStrings.seatOnboardingItem1Body)

        let item2 = WKOnboardingViewModel.WKOnboardingCellViewModel(icon: UIImage(named: "SEAT/seat-onboarding-2"), title: CommonStrings.seatOnboardingItem2Header, subtitle: CommonStrings.seatOnboardingItem2Body)

        let item3 = WKOnboardingViewModel.WKOnboardingCellViewModel(icon: UIImage(named: "SEAT/seat-onboarding-3"), title: CommonStrings.seatOnboardingItem3Header, subtitle: CommonStrings.seatOnboardingItem3Body)

        let item4 = WKOnboardingViewModel.WKOnboardingCellViewModel(icon: UIImage(named: "SEAT/seat-onboarding-4"), title: CommonStrings.seatOnboardingItem4Header, subtitle: CommonStrings.seatOnboardingItem4Body)

        let item5 = WKOnboardingViewModel.WKOnboardingCellViewModel(icon: UIImage(named: "SEAT/seat-onboarding-5"), title: CommonStrings.seatOnboardingItem5Header, subtitle: CommonStrings.seatOnboardingItem5Body)

        let viewModel = WKOnboardingViewModel(title: CommonStrings.seatOnboardingTitle, cells: [item1, item2, item3, item4, item5], primaryButtonTitle: CommonStrings.continueButton, secondaryButtonTitle: CommonStrings.seatOnboardingLearnMore)

        let viewController = WKOnboardingViewController(viewModel: viewModel)
        viewController.hostingController.delegate = self

        navigationController?.present(viewController, animated: true) {
            UserDefaults.standard.wmf_userHasOnboardedToSEAT = true
        }
    }
    
    private func goToSEAT() {
        isPresentingSuggestedEdits = true
        let hostingViewController = UIHostingController(rootView: SEATNavigationView(onboardingModalAction: { [weak self] in
            self?.showSEATOnboarding()
        }))
        self.push(hostingViewController)
    }

    @objc func goToWatchlist() {
        
        guard let linkURL = dataStore.primarySiteURL?.wmf_URL(withTitle: "Special:Watchlist"),
        let userActivity = NSUserActivity.wmf_activity(for: linkURL) else {
            return
        }
        
        NSUserActivity.wmf_navigate(to: userActivity)
    }
    
    @objc func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    @objc func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let text = sections[safeIndex: section]?.headerTitle
        return WMFTableHeaderFooterLabelView.headerFooterViewForTableView(tableView, text: text, type: .header, theme: theme)
    }
    
    @objc func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        guard let text = sections[safeIndex: section]?.footerTitle,
              !text.isEmpty else {
          return 0
        }

        return UITableView.automaticDimension
   }

   @objc func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {

       let text = sections[safeIndex: section]?.footerTitle
       return WMFTableHeaderFooterLabelView.headerFooterViewForTableView(tableView, text: text, type: .footer, theme: theme)
   }
    
    private func showLogoutAlert() {
        let alertController = UIAlertController(title: WMFLocalizedString("main-menu-account-logout-are-you-sure", value: "Are you sure you want to log out?", comment: "Header asking if user is sure they wish to log out."), message: WMFLocalizedString("main-menu-account-logout-are-you-sure-message", value: "Logging out will delete your locally stored account data (notifications and messages), but your account data will still be available on the web and will be re-downloaded if you log back in.", comment: "Message explaining what happens to local data when logging out."), preferredStyle: .alert)
        let logoutAction = UIAlertAction(title: CommonStrings.logoutTitle, style: .destructive) { [weak self] (action) in
            guard let self = self else {
                return
            }
            self.delegate?.accountViewControllerDidTapLogout(self)
            self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: WMFLocalizedString("main-menu-account-logout-cancel", value: "Cancel", comment: "Button text for hiding the log out menu. {{Identical|Cancel}}"), style: .cancel, handler: nil)
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        tableView.backgroundColor = theme.colors.baseBackground
    }
}

extension AccountViewController: VanishAccountWarningViewDelegate {

    func userDidDismissVanishAccountWarningView(presentVanishView: Bool) {
        guard presentVanishView, let username = dataStore.authenticationManager.loggedInUsername else {
            return
        }

        let viewController = VanishAccountContainerViewController(title: CommonStrings.vanishAccount.localizedCapitalized, theme: theme, username: username)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension AccountViewController: WKOnboardingViewDelegate {
    func didClickPrimaryButton() {
        SEATFunnel.shared.logSEATOnboardingDidTapContinue()
        if let presentedViewController = navigationController?.presentedViewController {
            presentedViewController.dismiss(animated: true) { [weak self] in
                if !(self?.isPresentingSuggestedEdits ?? true) {
                    self?.goToSEAT()
                }
            }
        }
    }
    
    func didClickSecondaryButton() {
        SEATFunnel.shared.logSEATOnboardingDidTapLearnMore()
        NotificationCenter.default.post(name: .seatOnboardingDidTapLearnMore, object: nil)
    }
    
}
