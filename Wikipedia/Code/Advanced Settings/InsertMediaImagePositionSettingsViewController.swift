final class InsertMediaImagePositionSettingsViewController: ViewController {
    private let tableView = UITableView()
    private var selectedIndexPath: IndexPath?

    typealias ImagePosition = InsertMediaSettings.Advanced.ImagePosition

    func selectedImagePosition(isTextWrappingEnabled: Bool) -> ImagePosition {
        guard isTextWrappingEnabled else {
            return .none
        }
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
        scrollView = tableView
        super.viewDidLoad()
        navigationBar.isBarHidingEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        view.wmf_addSubviewWithConstraintsToEdges(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()
        title = ImagePosition.displayTitle
        apply(theme: theme)
    }

    private func apply(theme: Theme, to cell: UITableViewCell) {
        cell.backgroundColor = theme.colors.paperBackground
        cell.contentView.backgroundColor = theme.colors.paperBackground
        cell.textLabel?.textColor = theme.colors.primaryText
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = theme.colors.midBackground
        cell.selectedBackgroundView = selectedBackgroundView
    }

    // MARK: - Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorColor = theme.colors.border
        tableView.reloadData()
    }
}

extension InsertMediaImagePositionSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        apply(theme: theme, to: cell)
        return cell
    }
}

extension InsertMediaImagePositionSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard
            let selectedIndexPath = selectedIndexPath,
            let selectedCell = tableView.cellForRow(at: selectedIndexPath)
            else {
                return indexPath
        }
        selectedCell.accessoryType = .none
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)
        selectedCell?.accessoryType = .checkmark
        selectedIndexPath = indexPath
    }
}
