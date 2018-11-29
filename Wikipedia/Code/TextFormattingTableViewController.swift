class TextFormattingTableViewController: UITableViewController {
    private var theme = Theme.standard

    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet var cellLabels: [UILabel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        leftAlignTitleItem()
        apply(theme: theme)
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Text formatting"
        label.sizeToFit()
        return label
    }()

    private func leftAlignTitleItem() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
        updateLabels()
    }

    private func updateFonts() {
        titleLabel.font = UIFont.wmf_font(.headline, compatibleWithTraitCollection: traitCollection)
        cellLabels.forEach { $0.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection) }
        clearButton.titleLabel?.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
    }

    private func updateLabels() {
        titleLabel.sizeToFit()
    }

}

extension TextFormattingTableViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        navigationItem.titleView?.backgroundColor = theme.colors.baseBackground
        navigationController?.navigationBar.tintColor = theme.colors.chromeText
        tableView.backgroundColor = theme.colors.baseBackground
        tableView.separatorColor = theme.colors.border
        titleLabel.textColor = theme.colors.primaryText
        clearButton.titleLabel?.textColor = theme.colors.error
        cellLabels.forEach { $0.textColor = theme.colors.primaryText }
    }
}
