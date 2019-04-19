final fileprivate class FooterView: SetupView, Themeable {
    private let label = UILabel()
    private let separator = UIView()

    override func setup() {
        super.setup()
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)
        let separatorLeadingConstraint = separator.leadingAnchor.constraint(equalTo: leadingAnchor)
        let separatorTrailingConstraint = separator.trailingAnchor.constraint(equalTo: trailingAnchor)
        let separatorTopConstraint = separator.topAnchor.constraint(equalTo: topAnchor)
        let separatorHeightConstraint = separator.heightAnchor.constraint(equalToConstant: 0.5)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "You can set how the media item appears on the page. This should be the thumbnail format to be consistent with other pages in almost all cases."
        addSubview(label)
        let labelLeadingConstraint = label.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15)
        let labelTrailingConstraint = label.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15)
        let labelBottomConstraint = label.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 15)
        let labelTopConstraint = label.topAnchor.constraint(equalTo: topAnchor, constant: 12)
        NSLayoutConstraint.activate([separatorLeadingConstraint, separatorTrailingConstraint, separatorTopConstraint, separatorHeightConstraint, labelLeadingConstraint, labelTrailingConstraint, labelBottomConstraint, labelTopConstraint])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        label.font  = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
    }

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        label.backgroundColor = backgroundColor
        label.textColor = theme.colors.secondaryText
        separator.backgroundColor = theme.colors.border
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.preferredMaxLayoutWidth = label.bounds.width
    }
}

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

