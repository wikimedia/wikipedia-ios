import UIKit
import SwiftUI
import WMF
import WMFComponents
import WMFData

@objc(WMFAccountViewControllerDelegate)
protocol AccountViewControllerDelegate: AnyObject {
    func accountViewControllerDidTapLogout(_ accountViewController: AccountViewController)
}

private enum ItemType {
    case talkPageAutoSignDiscussions
    case vanishAccount
    case informational
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

    private let donateDataController = WMFDonateDataController.shared

    private var sections: [Section] = []

    private func createSections() -> [Section] {
        let username = dataStore.authenticationManager.authStatePermanentUsername
        guard let username else {
            assertionFailure("Should not reach this screen if user isn't logged in.")
            return []
        }

        let userName = Item(
            title: username,
            subtitle: nil,
            iconName: "settings-user",
            iconColor: .white,
            iconBackgroundColor: WMFColor.orange600,
            type: .informational
        )

        let vanishAccount = Item(
            title: CommonStrings.vanishAccount,
            subtitle: nil,
            iconName: "vanish-account",
            iconColor: .white,
            iconBackgroundColor: .red,
            type: .vanishAccount
        )

        let account = Section(
            items: [userName, vanishAccount],
            headerTitle: WMFLocalizedString("account-group-title", value: "Your Account", comment: "Title for account group on account settings screen."),
            footerTitle: nil
        )

        let autoSignDiscussions = Item(
            title: WMFLocalizedString("account-talk-preferences-auto-sign-discussions", value: "Auto-sign discussions", comment: "Title for talk page preference that configures adding signature to new posts"),
            subtitle: nil,
            iconName: nil,
            iconColor: nil,
            iconBackgroundColor: nil,
            type: .talkPageAutoSignDiscussions
        )

        let talkPagePreferences = Section(
            items: [autoSignDiscussions],
            headerTitle: WMFLocalizedString("account-talk-preferences-title", value: "Talk page preferences", comment: "Title for talk page preference sections in account settings"),
            footerTitle: WMFLocalizedString("account-talk-preferences-auto-sign-discussions-setting-explanation", value: "Auto-signing of discussions will use the signature defined in Signature settings", comment: "Text explaining how setting the auto-signing of talk page discussions preference works")
        )

        return [account, talkPagePreferences]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.account
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        tableView.register(WMFTableHeaderFooterLabelView.wmf_classNib(), forHeaderFooterViewReuseIdentifier: WMFTableHeaderFooterLabelView.identifier)
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = 44
        tableView.layoutIfNeeded()

        sections = createSections()
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
        case .talkPageAutoSignDiscussions:
            cell.disclosureType = .switch
            cell.selectionStyle = .none
            cell.disclosureSwitch.isOn = UserDefaults.standard.autoSignTalkPageDiscussions
            cell.disclosureSwitch.addTarget(self, action: #selector(autoSignTalkPageDiscussions(_:)), for: .valueChanged)
        case .vanishAccount:
            cell.disclosureType = .viewController
            cell.accessibilityTraits = .button
        case .informational:
            cell.accessibilityTraits = .staticText
            cell.disclosureType = .none
            cell.isUserInteractionEnabled = false
            cell.selectionStyle = .none
            cell.accessoryType = .none
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
        case .vanishAccount:
            let warningViewController = VanishAccountWarningViewHostingViewController(theme: theme)
            warningViewController.delegate = self
            present(warningViewController, animated: true)
        default:
            break
        }
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
        guard presentVanishView else {
            return
        }
        
        guard let url = URL(string: "https://meta.wikimedia.org/wiki/Special:GlobalVanishRequest") else {
            return
        }
        
        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: false)
        let viewController = SinglePageWebViewController(configType: .standard(config), theme: theme)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
