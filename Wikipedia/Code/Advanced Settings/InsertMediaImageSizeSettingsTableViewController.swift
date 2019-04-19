fileprivate protocol ViewModel {
    var title: String { get }
}

final class InsertMediaImageSizeSettingsTableViewController: UITableViewController {
    private var theme = Theme.standard

    typealias ImageSize = InsertMediaSettings.Advanced.ImageSize

//    var selectedImageSize: ImageSize {
//        guard let selectedIndexPath = selectedIndexPath else {
//            return .default
//        }
//        return viewModels[selectedIndexPath.row].imageSize
//    }

    struct TitleCellViewModel: ViewModel {
        let title: String
        let accessoryView: UIView
    }

    struct TextFieldCellViewModel: ViewModel {
        let title: String
        let textFieldText: String
        let textFieldLabelText: String
    }

    private lazy var customSwitch: UISwitch = {
        let customSwitch = UISwitch()
        customSwitch.addTarget(self, action: #selector(reloadData), for: .valueChanged)
        return customSwitch
    }()

    @objc private func reloadData() {
        tableView.reloadData()
    }

    private lazy var viewModels: [ViewModel] = {
        let customViewModel = TitleCellViewModel(title: ImageSize.custom(width: 220, height: 124).displayTitle, accessoryView: customSwitch)
        let tf = UITextField()
        tf.placeholder = "220 px"
        let widthViewModel = TextFieldCellViewModel(title: "Width", textFieldText: "220", textFieldLabelText: "px")
        let heightViewModel = TextFieldCellViewModel(title: "Height", textFieldText: "124", textFieldLabelText: "px")
        return [customViewModel, widthViewModel, heightViewModel]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        tableView.register(InsertMediaCustomImageSizeSettingTableViewCell.wmf_classNib(), forCellReuseIdentifier: InsertMediaCustomImageSizeSettingTableViewCell.identifier)
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()
        title = "Image size"
        apply(theme: theme)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = viewModels[indexPath.row]
        switch viewModel {
        case let titleCellViewModel as TitleCellViewModel:
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier, for: indexPath)
            cell.textLabel?.text = titleCellViewModel.title
            cell.accessoryView = titleCellViewModel.accessoryView
            cell.selectionStyle = .none
            return cell
        case let textFieldCellViewModel as TextFieldCellViewModel:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: InsertMediaCustomImageSizeSettingTableViewCell.identifier, for: indexPath) as? InsertMediaCustomImageSizeSettingTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(title: textFieldCellViewModel.title, textFieldLabelText: textFieldCellViewModel.textFieldLabelText, textFieldText: textFieldCellViewModel.textFieldText, theme: theme)
            cell.selectionStyle = .none
            cell.isUserInteractionEnabled = customSwitch.isOn
            return cell
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - Themeable

extension InsertMediaImageSizeSettingsTableViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        tableView.separatorColor = theme.colors.border
    }
}
