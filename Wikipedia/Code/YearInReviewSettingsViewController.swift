import UIKit
import WMF
import WMFData
import CocoaLumberjackSwift

fileprivate protocol YearInReviewSettingsItem {
    var title: String { get }
    var iconName: String { get }
    var iconColor: UIColor { get }
    var iconBackgroundColor: UIColor { get }
}

@objc(WMFYearInReviewSettingsViewController)
final class YearInReviewSettingsViewController: SubSettingsViewController {

    // MARK: - Nested Types

    fileprivate struct YearInReviewSettingsSection {
        let headerText: String
        let items: [YearInReviewSettingsItem]
    }

    fileprivate struct YearInReviewSettingsSwitchItem: YearInReviewSettingsItem {
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
    private var sections: [YearInReviewSettingsSection] = []
    private let dataController = try? WMFYearInReviewDataController()

    fileprivate let headerText = WMFLocalizedString("settings-year-in-review-header", value: "Turning off Year in Review will clear all stored personalized insights and hide the Year in Review.", comment: "Text informing user of benefits of hiding the year in review feature.") + "\n"

    // MARK: - Lifecycle
    
    @objc init(dataStore: MWKDataStore, theme: Theme) {
        self.dataStore = dataStore
        super.init(theme: theme)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.yirTitle

        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44
        self.apply(theme: theme)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSections()
    }

    // MARK: - UITableView Data

    private func updateSections() {
        
        let switchItem = YearInReviewSettingsSwitchItem(title: CommonStrings.yirTitle, iconName: "settings-calendar", iconColor: UIColor.white, iconBackgroundColor: UIColor.wmf_blue_600, tag: 0, valueChecker: { [weak self] in
            
            guard let isEnabled = self?.dataController?.yearInReviewSettingsIsEnabled else {
                return false
            }
            
            return isEnabled
        }, action: { [weak self] isOn in
            self?.dataController?.yearInReviewSettingsIsEnabled = isOn
            if !isOn {
                Task {
                    do {
                        try await WMFYearInReviewDataController().deleteAllYearInReviewReports()
                    } catch {
                        DDLogError("Error deleting year in review reports: \(error)")
                    }
                }
            } else {
                self?.populateYearInReviewReportData()
            }
        })
        
        let section = YearInReviewSettingsSection(headerText: self.headerText, items: [switchItem])
        self.sections = [section]

        self.tableView.reloadData()
    }
    
    private func populateYearInReviewReportData() {
        guard let language  = dataStore.languageLinkController.appLanguage?.languageCode,
              let countryCode = Locale.current.region?.identifier
        else { return }
        let wmfLanguage = WMFLanguage(languageCode: language, languageVariantCode: nil)
        let project = WMFProject.wikipedia(wmfLanguage)

        Task {
            do {
                let yirDataController = try WMFYearInReviewDataController()
                try await yirDataController.populateYearInReviewReportData(
                    for: WMFYearInReviewDataController.targetYear,
                    countryCode: countryCode,
                    primaryAppLanguageProject: project,
                    username: dataStore.authenticationManager.authStatePermanentUsername)
            } catch {
                DDLogError("Failure populating year in review report: \(error)")
            }
        }
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

        if let switchItem = item as? YearInReviewSettingsSwitchItem {
            cell.disclosureType = .switch
            cell.disclosureSwitch.tag = switchItem.tag
            cell.disclosureSwitch.isOn = switchItem.valueChecker()
            cell.disclosureSwitch.addTarget(self, action: #selector(userDidTapSwitch(_:)), for: .valueChanged)
        }

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
        let items = sections.flatMap { section in section.items }.compactMap { item in item as? YearInReviewSettingsSwitchItem }
        if let tappedSwitchItem = items.first(where: { item in item.tag == sender.tag }) {
            tappedSwitchItem.action(sender.isOn)
        }
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
