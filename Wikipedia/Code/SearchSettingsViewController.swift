import UIKit

private struct Section {
    let items: [Item]
    let footerTitle: String
}

private struct Item {
    let title: String
    let isOn: Bool
}

@objc(WMFSearchSettingsViewController)
public final class SearchSettingsViewController: UIViewController {
    private var theme = Theme.standard

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .grouped)
        view.wmf_addSubviewWithConstraintsToEdges(tableView)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        return tableView
    }()

    public override func viewDidLoad() {
        title = CommonStrings.searchTitle
        apply(theme: theme)
    }

    private lazy var sections: [Section] = {
        let showLanguagesOnSearch = Item(title: WMFLocalizedString("settings-language-bar", value: "Show languages on search", comment: "Title in Settings for toggling the display the language bar in the search view"), isOn: true)
        let openAppOnSearchTab = Item(title: "Open app on Search tab", isOn: true)
        let items = [showLanguagesOnSearch, openAppOnSearchTab]
        let sections = [Section(items: items, footerTitle: "Set the app to open to the Search tab instead of the Explore tab")]
        return sections
    }()

    private func getSection(at index: Int) -> Section {
        assert(sections.indices.contains(index), "Section at index \(index) doesn't exist")
        return sections[index]
    }

    private func getItem(at indexPath: IndexPath) -> Item {
        let items = getSection(at: indexPath.section).items
        assert(items.indices.contains(indexPath.row), "Item at indexPath \(indexPath) doesn't exist")
        return items[indexPath.row]
    }
}

extension SearchSettingsViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = getSection(at: section)
        return section.items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier, for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        let item = getItem(at: indexPath)
        cell.disclosureType = .switch
        cell.iconName = nil
        cell.title = item.title
        cell.apply(theme)
        return cell
    }
}

extension SearchSettingsViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return getSection(at: section).footerTitle
    }
}

extension SearchSettingsViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.baseBackground
        tableView.backgroundColor = theme.colors.baseBackground
    }
}
