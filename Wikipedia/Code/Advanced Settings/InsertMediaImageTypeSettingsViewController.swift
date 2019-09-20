final class InsertMediaImageTypeSettingsViewController: ViewController {
    private let tableView = UITableView()
    private var selectedIndexPath: IndexPath?

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
        scrollView = tableView
        super.viewDidLoad()
        navigationBar.isBarHidingEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        view.wmf_addSubviewWithConstraintsToEdges(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        tableView.separatorInset = .zero
        autolayoutTableViewFooter = InsertMediaLabelTableFooterView(text: WMFLocalizedString("insert-media-image-type-settings-footer-title", value: "You can set how the media item appears on the page. This should be the thumbnail format to be consistent with other pages in almost all cases.", comment: "Footer for "))
        title = ImageType.displayTitle
        apply(theme: theme)
    }

    private var autolayoutTableViewFooter: UIView? {
        set {
            tableView.tableFooterView = newValue
            guard let footer = newValue else { return }
            footer.setNeedsLayout()
            footer.layoutIfNeeded()
            footer.frame.size =
                footer.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
           tableView.tableFooterView = footer
        }
        get {
            return tableView.tableFooterView
        }
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
        (autolayoutTableViewFooter as? Themeable)?.apply(theme: theme)
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension InsertMediaImageTypeSettingsViewController: UITableViewDataSource {
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

// MARK: - UITableViewDelegate

extension InsertMediaImageTypeSettingsViewController: UITableViewDelegate {
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

