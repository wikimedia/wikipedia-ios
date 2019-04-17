import UIKit

class InsertMediaAdvancedSettingsTableViewController: UITableViewController {
    private let theme: Theme

    struct ViewModel {
        let title: String
        let detailText: String?
        let accessoryView: UIView?
        let accessoryType: UITableViewCell.AccessoryType
        let selectionStyle: UITableViewCell.SelectionStyle

        init(title: String, detailText: String? = nil, accessoryView: UIView? = nil, accessoryType: UITableViewCell.AccessoryType = .disclosureIndicator, selectionStyle: UITableViewCell.SelectionStyle = .default) {
            self.title = title
            self.detailText = detailText
            self.accessoryView = accessoryView
            self.accessoryType = accessoryType
            self.selectionStyle = selectionStyle
        }
    }

    private lazy var viewModels: [ViewModel] = {
        let textWrappingSwitch = UISwitch()
        let textWrappingViewModel = ViewModel(title: "Wrap text around image", accessoryView: textWrappingSwitch, accessoryType: .none, selectionStyle: .none)
        let imagePositionViewModel = ViewModel(title: "Image position", detailText: "Right")
        let imageTypeViewModel = ViewModel(title: "Image type", detailText: "Thumbnail")
        let imageSizeViewModel = ViewModel(title: "Image size", detailText: "Default")
        return [textWrappingViewModel, imagePositionViewModel, imageTypeViewModel, imageSizeViewModel]
    }()

    init(theme: Theme) {
        self.theme = theme
        super.init(style: .plain)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()
        apply(theme: theme)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier) ?? UITableViewCell(style: .value1, reuseIdentifier: UITableViewCell.identifier)
        let viewModel = viewModels[indexPath.row]
        cell.textLabel?.text = viewModel.title
        cell.accessoryView = viewModel.accessoryView
        cell.accessoryType = viewModel.accessoryType
        cell.detailTextLabel?.textAlignment = .right
        cell.detailTextLabel?.text = viewModel.detailText
        cell.selectionStyle = viewModel.selectionStyle
        return cell
    }
}

// MARK: - Themeable

extension InsertMediaAdvancedSettingsTableViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        tableView.separatorColor = theme.colors.border
    }
}
