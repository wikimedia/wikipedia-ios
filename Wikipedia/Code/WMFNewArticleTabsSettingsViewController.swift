import UIKit
import WMF
import WMFData
import CocoaLumberjackSwift
import WMFComponents

fileprivate protocol NewArticleTabsSettingsItem {
    var title: String { get }
    var iconName: String { get }
    var iconColor: UIColor { get }
    var iconBackgroundColor: UIColor { get }
}

@objc
final class WMFNewArticleTabsSettingsViewController: SubSettingsViewController, WMFNavigationBarConfiguring {
    
    fileprivate struct NewArticleTabsSections {
        let headerText: String
        let items: [NewArticleTabsSettingsSwitchItem]
    }

    fileprivate struct NewArticleTabsSettingsSwitchItem: NewArticleTabsSettingsItem {
        let title: String
        let iconName: String
        let iconColor: UIColor
        let iconBackgroundColor: UIColor
        let tag: Int
        let valueChecker: () -> Bool
        let action: (Bool) -> Void
    }
    
    // MARK: - Properties

    private let dataStore: MWKDataStore
    
    private let dataController = WMFArticleTabsDataController()
    
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    
    private var sections: [NewArticleTabsSections] = []

    fileprivate let headerText = WMFLocalizedString("settings-new-article-tab-header-text", value: "New Tab Theme", comment: "Header title for the New Article Tabs settings to determine between preferences")

    // MARK: - Lifecycle
    
    @objc init(dataStore: MWKDataStore, theme: Theme) {
        self.dataStore = dataStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44
        self.apply(theme: theme)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateSections()
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.tabsPreferencesTitle, customView: nil, alignment: .centerCompact)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    private func setExclusiveToggle(selectedKey: String, deselectedKey: String) {
        try? userDefaultsStore?.save(key: selectedKey, value: true)
        try? userDefaultsStore?.save(key: deselectedKey, value: false)
    }
    
    private func updateSections() {
        let recommendationsItem = NewArticleTabsSettingsSwitchItem(
            title: WMFLocalizedString("new-article-tab-settings-recommendations", value: "Recommendations", comment: "Toggle for article recommendations / because you read"),
            iconName: "settings-star",
            iconColor: UIColor.white,
            iconBackgroundColor: UIColor.systemPurple,
            tag: 0,
            valueChecker: { [weak self] in
                return (try? self?.userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsBYR.rawValue)) ?? false
            },
            action: { [weak self] isOn in
                guard let self = self, let store = self.userDefaultsStore else { return }

                let currentValue = (try? store.load(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsBYR.rawValue)) ?? false
                if currentValue != isOn {
                    try? store.save(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsBYR.rawValue, value: isOn)
                }
                
            }
        )

        let didYouKnowItem = NewArticleTabsSettingsSwitchItem(
            title: WMFLocalizedString("new-article-tab-settings-did-you-know", value: "Did you know", comment: "Toggle for did you know"),
            iconName: "settings-lightbulb",
            iconColor: UIColor.white,
            iconBackgroundColor: UIColor.systemOrange,
            tag: 1,
            valueChecker: { [weak self] in
                return (try? self?.userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsDYK.rawValue)) ?? false
            },
            action: { [weak self] isOn in
                guard let self = self, let store = self.userDefaultsStore else { return }

                let currentValue = (try? store.load(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsDYK.rawValue)) ?? false
                if currentValue != isOn {
                    try? store.save(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsDYK.rawValue, value: isOn)
                }
            }
        )

        let section = NewArticleTabsSections(headerText: self.headerText, items: [recommendationsItem, didYouKnowItem])
        self.sections = [section]
        self.tableView.reloadData()
    }
    
    // MARK: - UITableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier, for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }

        let item = sections[indexPath.section].items[indexPath.item]
        cell.title = item.title
        cell.iconName = item.iconName
        cell.iconColor = item.iconColor
        cell.iconBackgroundColor = item.iconBackgroundColor
        
        if let iconBackgroundColor = theme.colors.iconBackground, let iconColor = theme.colors.icon {
            cell.iconBackgroundColor = iconColor
            cell.iconColor = iconBackgroundColor
        }

        if let themeableCell = cell as Themeable? {
            themeableCell.apply(theme: theme)
        }

        cell.disclosureType = .switch
        cell.disclosureSwitch.tag = item.tag
        cell.disclosureSwitch.isOn = item.valueChecker()
        cell.disclosureSwitch.addTarget(self, action: #selector(userDidTapSwitch(_:)), for: .valueChanged)

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = WMFTableHeaderFooterLabelView.wmf_viewFromClassNib() else {
            return nil
        }

        if let themeableHeader = header as Themeable? {
            themeableHeader.apply(theme: theme)
        }

        header.text = sections[section].headerText
        return header
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    // MARK: - UI Actions

    @objc func userDidTapSwitch(_ sender: UISwitch) {
        let items = sections.flatMap { $0.items }

        guard let toggledItem = items.first(where: { $0.tag == sender.tag }) else {
            return
        }

        toggledItem.action(sender.isOn)

        if sender.isOn {
            for item in items where item.tag != sender.tag {
                guard let currentValue: Bool = (try? userDefaultsStore?.load(key: tagToKey(item.tag))) ?? false, currentValue == true else {
                    continue
                }

                try? userDefaultsStore?.save(key: tagToKey(item.tag), value: false)

                if let indexPath = indexPath(forTag: item.tag),
                   let cell = tableView.cellForRow(at: indexPath) as? WMFSettingsTableViewCell {
                    cell.disclosureSwitch.setOn(false, animated: true)
                }
            }
        }
    }
    
    private func tagToKey(_ tag: Int) -> String {
        switch tag {
        case 0:
            return WMFUserDefaultsKey.developerSettingsMoreDynamicTabsBYR.rawValue
        case 1:
            return WMFUserDefaultsKey.developerSettingsMoreDynamicTabsDYK.rawValue
        default:
            return ""
        }
    }
    
    private func indexPath(forTag tag: Int) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            for (rowIndex, item) in section.items.enumerated() {
                if item.tag == tag {
                    return IndexPath(row: rowIndex, section: sectionIndex)
                }
            }
        }
        return nil
    }

    // MARK: - Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.baseBackground
        tableView.backgroundColor = theme.colors.baseBackground
        tableView.reloadData()
    }

}
