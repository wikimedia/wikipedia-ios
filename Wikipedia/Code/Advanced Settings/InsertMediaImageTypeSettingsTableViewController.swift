final class InsertMediaImageTypeSettingsTableViewController: UITableViewController {
    private let theme: Theme

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

    init(theme: Theme) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        if viewModel.isSelected {
            cell.accessoryType = .checkmark
            selectedIndexPath = indexPath
        } else {
            cell.accessoryType = .none
        }
        apply(theme: theme, to: cell)
        return cell
    }

    private func apply(theme: Theme, to cell: UITableViewCell) {
        cell.backgroundColor = theme.colors.paperBackground
        cell.contentView.backgroundColor = theme.colors.paperBackground
        cell.textLabel?.textColor = theme.colors.primaryText
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = theme.colors.midBackground
        cell.selectedBackgroundView = selectedBackgroundView
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
        (autolayoutTableViewFooter as? Themeable)?.apply(theme: theme)
    }
}

