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

enum TextSizeType: String {
    case normal
    case big
    case small

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
        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "close"), style: .plain, target: self, action: #selector(close(_:)))
        return button
    }()

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
        updateTitleLabel()
        apply(theme: theme)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
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
        selectedTextStyleType = .paragraph
        selectedTextSizeType = .normal
    }

    open func buttonSelectionDidChange(button: SectionEditorButton) {
        switch button.kind {
        case .heading(let type):
            selectedTextStyleType = type
        case .textSize(let type):
            selectedTextSizeType = type
        default:
            break
        }
    }

    open func disableButton(button: SectionEditorButton) {
        
    }
}

extension TextFormattingProvidingTableViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        tableView.backgroundColor = theme.colors.inputAccessoryBackground
        titleLabel.textColor = theme.colors.primaryText
    }
}
