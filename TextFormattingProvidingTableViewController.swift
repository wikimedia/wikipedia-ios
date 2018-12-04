protocol TextFormattingProviding where Self: UIViewController {
    var delegate: TextFormattingDelegate? { get set }
}

protocol TextFormattingDelegate: class {
    func textFormattingProvidingDidTapCloseButton(_ textFormattingProviding: TextFormattingProviding)
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
        delegate?.textFormattingProvidingDidTapCloseButton(self)
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
