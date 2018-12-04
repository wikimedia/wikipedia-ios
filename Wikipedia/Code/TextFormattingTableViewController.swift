protocol TextFormattingProviding where Self: UIViewController {
    var delegate: TextFormattingDelegate? { get set }
}

protocol TextFormattingDelegate: class {
    func textFormattingProvidingDidTapCloseButton(_ textFormattingProviding: TextFormattingProviding)
}

class TextFormattingTableViewController: UITableViewController, TextFormattingProviding {
    weak var delegate: TextFormattingDelegate?

    private var theme = Theme.standard

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Text formatting"
        label.sizeToFit()
        return label
    }()

    private struct Content {
        let type: ContentType
        let title: String?
        let detailText: String?
        let customView: (UIView & Themeable)?

        init(type: ContentType, title: String? = nil, detailText: String? = nil, customView: (UIView & Themeable)? = nil) {
            self.type = type
            self.title = title
            self.detailText = detailText
            self.customView = customView
        }
    }

    private enum ContentType {
        case customView
        case detail
    }

    private struct Item {
        let cell: TextFormattingTableViewCell.Type
        let content: Content
        let onSelection: (() -> Void)?

        init(with content: Content, onSelection: (() -> Void)? = nil) {
            switch content.type {
            case .customView:
                self.cell = TextFormattingCustomViewTableViewCell.self
            case .detail:
                self.cell = TextFormattingDetailTableViewCell.self
            }
            self.content = content
            self.onSelection = onSelection
        }
    }

    private lazy var items: [Item] = {
        let textFormattingToolbarView = TextFormattingToolbarView.wmf_viewFromClassNib()
        textFormattingToolbarView?.delegate = self
        let toolbar = Item(with: Content(type: .customView, customView: textFormattingToolbarView))

        let textFormattingGroupedToolbarView = TextFormattingGroupedToolbarView.wmf_viewFromClassNib()
        textFormattingGroupedToolbarView?.delegate = self
        let groupedToolbar = Item(with: Content(type: .customView, customView: textFormattingGroupedToolbarView))

        let showTextStyleFormattingTableViewController = {
            let textStyleFormattingTableViewController = TextStyleFormattingTableViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
            self.navigationController?.pushViewController(textStyleFormattingTableViewController, animated: true)
        }
        let textStyle = Item(with: Content(type: .detail, title: "Style", detailText: "Paragraph"), onSelection: showTextStyleFormattingTableViewController)

        let textSize = Item(with: Content(type: .detail, title: "Text size", detailText: "Normal"))

        let textFormattingButtonView = TextFormattingButtonView.wmf_viewFromClassNib()
        textFormattingButtonView?.buttonTitle = "Clear formatting"
        textFormattingButtonView?.buttonTitleColor = theme.colors.error
        textFormattingButtonView?.delegate = self
        let button = Item(with: Content(type: .customView, customView: textFormattingButtonView))

        return [toolbar, groupedToolbar, textStyle, textSize, button]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        leftAlignTitleItem()
        apply(theme: theme)
    }

    private func leftAlignTitleItem() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateTitleLabel()
    }

    private func updateTitleLabel() {
        titleLabel.font = UIFont.wmf_font(.headline, compatibleWithTraitCollection: traitCollection)
        titleLabel.sizeToFit()
    }

    @IBAction private func close(_ sender: UIBarButtonItem) {
        delegate?.textFormattingProvidingDidTapCloseButton(self)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let configuredCell = configuredCell(for: indexPath) else {
            assertionFailure("Expected a subclass of TextFormattingTableViewCell")
            return UITableViewCell()
        }
        return configuredCell
    }

    private func configuredCell(for indexPath: IndexPath) -> UITableViewCell? {
        let item = items[indexPath.row]
        let content = item.content
        let contentType = content.type

        switch contentType {
        case .customView:
            guard let cell = tableView.dequeueCell(ofType: TextFormattingCustomViewTableViewCell.self, for: indexPath) else {
                break
            }
            guard let customView = content.customView else {
                break
            }
            cell.configure(with: customView)
            cell.apply(theme: theme)
            return cell
        case .detail:
            guard let cell = tableView.dequeueCell(ofType: TextFormattingDetailTableViewCell.self, for: indexPath) else {
                break
            }
            guard
                let title = content.title,
                let detailText = content.detailText
            else {
                break
            }
            cell.apply(theme: theme)
            cell.configure(with: title, detailText: detailText)
            return cell
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        item.onSelection?()
    }

}

private extension UITableView {
    func dequeueCell<T: UITableViewCell>(ofType type: T.Type, for indexPath: IndexPath) -> T? {
        guard let cell = dequeueReusableCell(withIdentifier: type.identifier, for: indexPath) as? T else {
            assertionFailure("Could not dequeue cell of type \(T.self)")
            return nil
        }
        return cell
    }
}

extension TextFormattingTableViewController: TextFormattingToolbarViewDelegate {

}

extension TextFormattingTableViewController: TextFormattingGroupedToolbarViewDelegate {

}

extension TextFormattingTableViewController: TextFormattingButtonViewDelegate {

}

extension TextFormattingTableViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        navigationController?.navigationBar.tintColor = theme.colors.chromeText
        navigationController?.navigationBar.shadowImage = theme.navigationBarShadowImage
        tableView.backgroundColor = theme.colors.paperBackground
    }
}
