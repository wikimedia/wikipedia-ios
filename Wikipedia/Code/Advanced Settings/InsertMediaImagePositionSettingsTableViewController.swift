final class InsertMediaImagePositionSettingsTableViewController: UITableViewController {
    private var theme = Theme.standard

    typealias ImagePosition = InsertMediaSettings.Advanced.ImagePosition

    var selectedImagePosition: ImagePosition {
        guard let selectedIndexPath = selectedIndexPath else {
            return .right
        }
        return viewModels[selectedIndexPath.row].imagePosition
    }

    struct ViewModel {
        let imagePosition: ImagePosition
        let title: String
        let isSelected: Bool

        init(imagePosition: ImagePosition, isSelected: Bool = false) {
            self.imagePosition = imagePosition
            self.title = imagePosition.displayTitle
            self.isSelected = isSelected
        }
    }

    private lazy var viewModels: [ViewModel] = {
        let rightViewModel = ViewModel(imagePosition: .right, isSelected: true)
        let leftViewModel = ViewModel(imagePosition: .left)
        let centerViewModel = ViewModel(imagePosition: .center)
        return [rightViewModel, leftViewModel, centerViewModel]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        tableView.separatorInset = .zero
        title = "Image position"
        apply(theme: theme)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier, for: indexPath)
        let viewModel = viewModels[indexPath.row]
        cell.textLabel?.text = viewModel.title
        cell.accessoryType = viewModel.isSelected ? .checkmark : .none
        if viewModel.isSelected {
            cell.accessoryType = .checkmark
            selectedIndexPath = indexPath
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    private var selectedIndexPath: IndexPath?

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard
            let selectedIndexPath = selectedIndexPath,
            let selectedCell = tableView.cellForRow(at: selectedIndexPath)
        else {
            return indexPath
        }
        selectedCell.accessoryType = .none
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)
        selectedCell?.accessoryType = .checkmark
        selectedIndexPath = indexPath
    }
}

// MARK: - Themeable

extension InsertMediaImagePositionSettingsTableViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        tableView.separatorColor = theme.colors.border
    }
}
