import UIKit

class InsertMediaSettingsTableViewController: UITableViewController {
    private let image: UIImage
    private let imageInfo: MWKImageInfo

    private var theme = Theme.standard

    private lazy var imageView: InsertMediaSettingsImageView = {
        let imageView = InsertMediaSettingsImageView.wmf_viewFromClassNib()!
        imageView.image = image
        imageView.heading = "Uploaded image"
        imageView.title = "Yellow leaves in Brooklyn"
        imageView.autoresizingMask = []
        return imageView
    }()

    private lazy var buttonView = InsertMediaSettingsButtonView.wmf_viewFromClassNib()!

    private struct TextViewModel {
        let headerText: String
        let textFieldPlaceholderText: String
        let footerText: String
    }

    private lazy var viewModels: [TextViewModel] = {
        let captionViewModel = TextViewModel(headerText: "Caption", textFieldPlaceholderText: "How does this image relate to the article?", footerText: "Label that shows next to the item for all readers")
        let alternativeTextViewModel = TextViewModel(headerText: "Alternative text", textFieldPlaceholderText: "Describe this image", footerText: "Text description for readers who cannot see the image")
        return [captionViewModel, alternativeTextViewModel]
    }()

    init(image: UIImage, imageInfo: MWKImageInfo) {
        self.image = image
        self.imageInfo = imageInfo
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(InsertMediaSettingsTextTableViewCell.wmf_classNib(), forCellReuseIdentifier: InsertMediaSettingsTextTableViewCell.identifier)
        tableView.separatorStyle = .none
        tableView.tableHeaderView = imageView
        tableView.tableFooterView = buttonView
        apply(theme: theme)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let headerView = tableView.tableHeaderView else {
            return
        }
        let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        guard headerView.frame.size.height != height else {
            return
        }
        headerView.frame.size.height = height
        tableView.tableHeaderView = headerView
    }
}

// MARK: - Table view data source

extension InsertMediaSettingsTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InsertMediaSettingsTextTableViewCell.identifier, for: indexPath) as? InsertMediaSettingsTextTableViewCell else {
            return UITableViewCell()
        }
        let viewModel = viewModels[indexPath.row]
        cell.headerText = viewModel.headerText
        cell.textFieldPlaceholderText = viewModel.textFieldPlaceholderText
        cell.footerText = viewModel.footerText
        cell.apply(theme: theme)
        return cell
    }
}

// MARK: - Themeable

extension InsertMediaSettingsTableViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        imageView.apply(theme: theme)
        buttonView.apply(theme: theme)
    }
}
