import UIKit

typealias InsertMediaSettings = InsertMediaSettingsTableViewController.Settings

class InsertMediaSettingsTableViewController: UITableViewController {
    private let image: UIImage
    let searchResult: InsertMediaSearchResult

    private var textViewHeightDelta: (value: CGFloat, row: Int)?
    private var textViewsGroupedByType = [TextViewType: UITextView]()

    private var theme = Theme.standard

    struct Settings {
        let caption: String?
        let alternativeText: String?
        let advanced: Advanced

        struct Advanced {
            let wrapTextAroundImage: Bool
            let imagePosition: ImagePosition
            let imageType: ImageType
            let imageSize: ImageSize

            enum ImagePosition: String {
                case right
                case left
                case center

                var displayTitle: String {
                    switch self {
                    case .right:
                        return "Right"
                    case .left:
                        return "Left"
                    case .center:
                        return "Center"
                    }
                }
            }

            enum ImageType: String {
                case thumbnail = "thumb"
                case frameless
                case frame
                case basic

                var displayTitle: String {
                    switch self {
                    case .thumbnail:
                        return "Thumbnail"
                    case .frameless:
                        return "Frameless"
                    case .frame:
                        return "Frame"
                    case .basic:
                        return "Basic"
                    }
                }
            }

            enum ImageSize {
                case `default`
                case custom(width: Int, height: Int)

                var displayTitle: String {
                    switch self {
                    case .default:
                        return "Default"
                    case .custom:
                        return "Custom"
                    }
                }

                var rawValue: String {
                    switch self {
                    case .default:
                        return "upright"
                    case .custom(let width, let height):
                        return "\(width)x\(height)px"
                    }
                }
            }

            init(wrapTextAroundImage: Bool = false, imagePosition: ImagePosition = .right, imageType: ImageType = .thumbnail, imageSize: ImageSize = .default) {
                self.wrapTextAroundImage = wrapTextAroundImage
                self.imagePosition = imagePosition
                self.imageType = imageType
                self.imageSize = imageSize
            }
        }

        init(caption: String?, alternativeText: String?, advanced: Advanced = Advanced()) {
            self.caption = caption
            self.alternativeText = alternativeText
            self.advanced = advanced
        }
    }

    var settings: Settings? {
        let captionTextView = textViewsGroupedByType[.caption]
        let alternativeTextTextView = textViewsGroupedByType[.alternativeText]
        return Settings(caption: captionTextView?.text, alternativeText: alternativeTextTextView?.text, advanced: insertMediaAdvancedSettingsTableViewController.advancedSettings)
    }

    private lazy var imageView: InsertMediaSettingsImageView = {
        let imageView = InsertMediaSettingsImageView.wmf_viewFromClassNib()!
        imageView.image = image
        imageView.heading = "Uploaded image"
        
        imageView.title = searchResult.displayTitle
        imageView.autoresizingMask = []
        return imageView
    }()

    private lazy var insertMediaAdvancedSettingsTableViewController: InsertMediaAdvancedSettingsTableViewController = {
        return InsertMediaAdvancedSettingsTableViewController(theme: theme)
    }()

    private lazy var buttonView: InsertMediaSettingsButtonView = {
        let buttonView = InsertMediaSettingsButtonView.wmf_viewFromClassNib()!
        let isRTL = view.traitCollection.layoutDirection == .rightToLeft
        let buttonTitleWithoutChevron = "Advanced settings"
        let buttonTitleWithChevron = view.traitCollection.layoutDirection == .rightToLeft ? "< \(buttonTitleWithoutChevron)" : "\(buttonTitleWithoutChevron) >"
        buttonView.buttonTitle = buttonTitleWithChevron
        buttonView.buttonAction = { _ in
            self.navigationController?.pushViewController(self.insertMediaAdvancedSettingsTableViewController, animated: true)
        }
        buttonView.autoresizingMask = []
        return buttonView
    }()

    private struct TextViewModel {
        let type: TextViewType
        let headerText: String
        let placeholder: String
        let footerText: String

        init(type: TextViewType) {
            self.type = type
            switch type {
            case .caption:
                headerText = "Caption"
                placeholder = "How does this image relate to the article?"
                footerText = "Label that shows next to the item for all readers"
            case .alternativeText:
                headerText = "Alternative text"
                placeholder = "Describe this image"
                footerText = "Text description for readers who cannot see the image"
            }
        }
    }

    private enum TextViewType: Int, Hashable {
        case caption
        case alternativeText
    }

    private lazy var viewModels: [TextViewModel] = {
        let captionViewModel = TextViewModel(type: .caption)
        let alternativeTextViewModel = TextViewModel(type: .alternativeText)
        return [captionViewModel, alternativeTextViewModel]
    }()

    init(image: UIImage, searchResult: InsertMediaSearchResult) {
        self.image = image
        self.searchResult = searchResult
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

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: traitCollection, with: coordinator)
        UIView.performWithoutAnimation {
            self.textViewHeightDelta = nil
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
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
        textViewsGroupedByType[viewModel.type] = cell.textViewConfigured(with: self, placeholder: viewModel.placeholder, tag: indexPath.row)
        cell.footerText = viewModel.footerText
        cell.selectionStyle = .none
        cell.apply(theme: theme)
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard
            let cell = tableView.visibleCells[safeIndex: indexPath.row] as? InsertMediaSettingsTextTableViewCell,
            let textViewHeightDelta = textViewHeightDelta,
            textViewHeightDelta.row == indexPath.row
        else {
            return UITableView.automaticDimension
        }
        return cell.frame.size.height + textViewHeightDelta.value
    }
}

extension InsertMediaSettingsTableViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let oldHeight = textView.frame.size.height
        let newHeight = textView.systemLayoutSizeFitting(textView.frame.size).height
        guard oldHeight != newHeight else {
            return
        }
        textViewHeightDelta = (newHeight - oldHeight, textView.tag)
        UIView.performWithoutAnimation {
            textView.frame.size.height = newHeight
            tableView.beginUpdates()
            tableView.endUpdates()
        }
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
