import UIKit

class FeedCardSettingsViewController: BaseExploreFeedSettingsViewController {
    private var contentGroupKind: WMFContentGroupKind = .unknown

    func configure(with title: String, dataStore: MWKDataStore?, contentGroupKind: WMFContentGroupKind, theme: Theme) {
        self.title = title
        self.dataStore = dataStore
        self.contentGroupKind = contentGroupKind
        self.theme = theme
    }

    override func isLanguageSwitchOn(for languageLink: MWKLanguageLink) -> Bool {
        return languageLink.isInFeed(for: contentGroupKind)
    }

    private var isMasterSwitchOn: Bool {
        guard let settingsCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? WMFSettingsTableViewCell else {
            return false
        }
         return settingsCell.disclosureSwitch.isOn
    }

    override var sections: [ExploreFeedSettingsSection] {
        let master = ExploreFeedSettingsMaster(title: "Show card", isOn: contentGroupKind.isInFeed)
        let main = ExploreFeedSettingsSection(headerTitle: nil, footerTitle: "Turning off the In the news card will turn the card off in all available languages.", items: [master])
        let languages = ExploreFeedSettingsSection(headerTitle: "Languages", footerTitle: "Additional languages can be added in the ‘My languages’ settings page. Turning off all available languages will turn off the In the news card.", items: self.languages)
        return [main, languages]
    }

    override func needsReloading(_ item: ExploreFeedSettingsItem) -> Bool {
        return item is ExploreFeedSettingsMaster
    }

    override var shouldReload: Bool {
        return isMasterSwitchOn != contentGroupKind.isInFeed
    }

}

// MARK: - WMFSettingsTableViewCellDelegate

extension FeedCardSettingsViewController {
    override func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        let controlTag = sender.tag
        guard let feedContentController = feedContentController else {
            assertionFailure("feedContentController is nil")
            return
        }
        guard controlTag != -1 else { // master switch
            feedContentController.toggleContentGroup(of: contentGroupKind, isOn: sender.isOn)
            return
        }
        guard let language = languages.first(where: { $0.controlTag == sender.tag }) else {
            assertionFailure("No language for a given control tag")
            return
        }
        feedContentController.toggleContentGroup(of: contentGroupKind, isOn: sender.isOn, forSiteURL: language.siteURL)
    }
}
