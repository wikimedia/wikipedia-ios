protocol TextFormattingProviding: class {
    var delegate: TextFormattingDelegate? { get set }
}

protocol TextFormattingDelegate: class {
    func closeTapped(sender: TextFormattingProviding)
    func boldTapped(sender: TextFormattingProviding)
    func italicTapped(sender: TextFormattingProviding)
    func referenceTapped(sender: TextFormattingProviding)
    func templateTapped(sender: TextFormattingProviding)
    func commentTapped(sender: TextFormattingProviding)
    func linkTapped(sender: TextFormattingProviding)
    
    func increaseIndentTapped(sender: TextFormattingProviding)
    func decreaseIndentTapped(sender: TextFormattingProviding)
    func orderedListTapped(sender: TextFormattingProviding)
    func unorderedListTapped(sender: TextFormattingProviding)
    func superscriptTapped(sender: TextFormattingProviding)
    func subscriptTapped(sender: TextFormattingProviding)
    func underlineTapped(sender: TextFormattingProviding)
    func strikethroughTapped(sender: TextFormattingProviding)
}

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

    private func resetSelectTextStyleType() {
        selectedTextStyleType = .paragraph
    }

    private func selectTextStyleType(for type: EditButtonType, depth: Int) {
        guard type == .heading else {
            return
        }
        guard let newTextStyleType = TextStyleType(rawValue: depth) else {
            return
        }
        selectedTextStyleType = newTextStyleType
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(forName: Notification.Name.WMFSectionEditorSelectionChangedNotification, object: nil, queue: nil) { [weak self] notification in
            self?.resetSelectTextStyleType()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.WMFSectionEditorButtonHighlightNotification, object: nil, queue: nil) { [weak self] notification in
            if let message = notification.userInfo?[SectionEditorWebViewConfiguration.WMFSectionEditorSelectionChangedSelectedButton] as? ButtonNeedsToBeSelectedMessage {
                self?.selectTextStyleType(for: message.type, depth: message.depth)
                // print("buttonNeedsToBeSelectedMessage = \(message)")
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        delegate?.closeTapped(sender: self)
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
