import UIKit
import SwiftUI
import WMF

@objc(WMFAccountViewControllerDelegate)
protocol AccountViewControllerDelegate: AnyObject {
    func accountViewControllerDidTapLogout(_ accountViewController: AccountViewController)
}

private enum ItemType {
    case logout
    case talkPage
    case talkPageAutoSignDiscussions
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
    
    private lazy var sections: [Section] = {
        
        guard let username = dataStore.authenticationManager.loggedInUsername else {
            assertionFailure("Should not reach this screen if user isn't logged in.")
            return []
        }
        
        let logout = Item(title: username, subtitle: CommonStrings.logoutTitle, iconName: "settings-user", iconColor: .white, iconBackgroundColor: UIColor.wmf_colorWithHex(0xFF8E2B), type: .logout)
        let talkPage = Item(title: WMFLocalizedString("account-talk-page-title", value: "Your talk page", comment: "Title for button and page letting user view their account page."), subtitle: nil, iconName: "settings-talk-page", iconColor: .white, iconBackgroundColor: UIColor(red: 51/255, green: 102/255, blue: 204/255, alpha: 1) , type: .talkPage)
        let vanishAccount = Item(title: CommonStrings.vanishAccount, subtitle: nil, iconName: "vanish-account", iconColor: .white, iconBackgroundColor: .red, type: .vanishAccount)
        let account = Section(items: [logout, talkPage, vanishAccount], headerTitle: WMFLocalizedString("account-group-title", value: "Your Account", comment: "Title for account group on account settings screen."), footerTitle: nil)

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
            
            let title = OldTalkPageType.user.titleWithCanonicalNamespacePrefix(title: username, siteURL: siteURL)
            
            if FeatureFlags.needsNewTalkPage {
                if let viewModel = TalkPageViewModel(pageType: .user, pageTitle: title, siteURL: siteURL, source: .account, articleSummaryController: dataStore.articleSummaryController, authenticationManager: dataStore.authenticationManager, languageLinkController: dataStore.languageLinkController) {
                    let newTalkPage = TalkPageViewController(theme: theme, viewModel: viewModel)
                    self.navigationController?.pushViewController(newTalkPage, animated: true)
                }
            } else {
                let title = OldTalkPageType.user.titleWithCanonicalNamespacePrefix(title: username, siteURL: siteURL)
                let loadingFlowController = TalkPageContainerViewController.talkPageContainer(title: title, siteURL: siteURL,  type: .user, dataStore: dataStore, theme: theme)
                self.navigationController?.pushViewController(loadingFlowController, animated: true)
            }
            
        case .vanishAccount:
            let warningViewController = VanishAccountWarningViewHostingViewController(theme: theme)
            warningViewController.delegate = self
            present(warningViewController, animated: true)
        default:
            break
        }
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
