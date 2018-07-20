import UIKit

@objc(WMFSearchSettingsViewController)
public class SearchSettingsViewController: UIViewController {
    private var theme = Theme.standard

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .grouped)
        view.wmf_addSubviewWithConstraintsToEdges(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    public override func viewDidLoad() {
        apply(theme: theme)
    }
}

extension SearchSettingsViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

extension SearchSettingsViewController: UITableViewDelegate {

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
