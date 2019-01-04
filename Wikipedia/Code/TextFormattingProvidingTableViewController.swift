enum TextStyleType: Int {
    case paragraph
    case heading = 2 // Heading is 2 equals (we don't show a heading choice for 1 equals variant)
    case subheading1 = 3
    case subheading2 = 4
    case subheading3 = 5
    case subheading4 = 6

    var name: String {
        switch self {
        case .paragraph:
            return "Paragraph"
        case .heading:
            return "Heading"
        case .subheading1:
            return "Sub-heading 1"
        case .subheading2:
            return "Sub-heading 2"
        case .subheading3:
            return "Sub-heading 3"
        case .subheading4:
            return "Sub-heading 4"
        }
    }
}

enum TextSizeType {
    case normal
    case big
    case small

    #warning("Text size strings need to be localized")
    var name: String {
        switch self {
        case .normal:
            return "Normal"
        case .big:
            return "Big"
        case .small:
            return "Small"
        }
    }
}

class TextFormattingProvidingTableViewController: UITableViewController, TextFormattingProviding {
    weak var delegate: TextFormattingDelegate?

    var theme = Theme.standard

    open var titleLabelText: String? {
        return nil
    }

    open var shouldSetCustomTitleLabel: Bool {
        return true
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = titleLabelText
        label.sizeToFit()
        return label
    }()

    private lazy var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem.init(image: #imageLiteral(resourceName: "close"), style: .plain, target: self, action: #selector(close(_:)))
        return button
    }()

    private func resetSelections() {
        selectedTextStyleType = .paragraph
        selectedTextSizeType = .normal
    }

    private func updateSelections(for type: EditButtonType, depth: Int) {
        switch type {
        case .heading:
            guard let newTextStyleType = TextStyleType(rawValue: depth) else {
                return
            }
            selectedTextStyleType = newTextStyleType
        case .smallTextSize:
            selectedTextSizeType = .small
        case .bigTextSize:
            selectedTextSizeType = .big
        default:
            break
        }
    }
    
    final var selectedTextStyleType: TextStyleType = .paragraph {
        didSet {
            guard navigationController != nil else {
                return
            }
            tableView.reloadData()
        }
    }

    final var selectedTextSizeType: TextSizeType = .normal {
        didSet {
            guard navigationController != nil else {
                return
            }
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if shouldSetCustomTitleLabel {
            leftAlignTitleItem()
        }
        setCloseButton()
        navigationItem.backBarButtonItem?.title = titleLabelText
        apply(theme: theme)
    }

    private func leftAlignTitleItem() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
    }

    private func setCloseButton() {
        navigationItem.rightBarButtonItem = closeButton
    }

    private func updateTitleLabel() {
        titleLabel.font = UIFont.wmf_font(.headline, compatibleWithTraitCollection: traitCollection)
        titleLabel.sizeToFit()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateTitleLabel()
    }

    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.textFormattingProvidingDidTapClose()
    }

    // MARK: Text & button selection messages

    open func textSelectionDidChange(isRangeSelected: Bool) {

    }

    open func buttonSelectionDidChange(button: SectionEditorWebViewMessagingController.Button) {

    }
}

extension TextFormattingProvidingTableViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            return
        }
        navigationController?.navigationBar.tintColor = theme.colors.chromeText
        navigationController?.navigationBar.shadowImage = theme.navigationBarShadowImage
        tableView.backgroundColor = theme.colors.paperBackground
    }
}
