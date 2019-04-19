final class InsertMediaImageTypeSettingsTableViewController: UITableViewController {
    private var theme = Theme.standard

    typealias ImageType = InsertMediaSettings.Advanced.ImageType

    var selectedImageType: ImageType {
        guard let selectedIndexPath = selectedIndexPath else {
            return .thumbnail
        }
        return viewModels[selectedIndexPath.row].imageType
    }

    struct ViewModel {
        let imageType: ImageType
        let title: String
        let isSelected: Bool

        init(imageType: ImageType, isSelected: Bool = false) {
            self.imageType = imageType
            self.title = imageType.displayTitle
            self.isSelected = isSelected
        }
    }

    private lazy var viewModels: [ViewModel] = {
        let thumbnailViewModel = ViewModel(imageType: .thumbnail, isSelected: true)
        let framelessViewModel = ViewModel(imageType: .frameless)
        let frameViewModel = ViewModel(imageType: .frame)
        let basicViewModel = ViewModel(imageType: .basic)
        return [thumbnailViewModel, framelessViewModel, frameViewModel, basicViewModel]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        tableView.separatorInset = .zero
        title = "Image type"
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

extension InsertMediaImageTypeSettingsTableViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        tableView.separatorColor = theme.colors.border
    }
}

