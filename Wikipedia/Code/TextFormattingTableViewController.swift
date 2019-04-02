class TextFormattingTableViewController: TextFormattingProvidingTableViewController {

    override var titleLabelText: String? {
        return WMFLocalizedString("edit-text-formatting-table-view-title", value: "Text formatting", comment: "Title for text formatting menu in the editing interface")
    }

    private struct Content {
        let type: ContentType
        let title: String?
        let detailText: String?
        let customView: (UIView & Themeable)?
        var isEnabled: Bool = true
        
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
        case destructiveAction
    }

    private struct Item {
        let cell: TextFormattingTableViewCell.Type
        var content: Content
        let onSelection: (() -> Void)?

        init(with content: Content, onSelection: (() -> Void)? = nil) {
            switch content.type {
            case .customView:
                self.cell = TextFormattingCustomViewTableViewCell.self
            case .detail:
                self.cell = TextFormattingDetailTableViewCell.self
            case .destructiveAction:
                self.cell = TextFormattingDetailTableViewCell.self
            }
            self.content = content
            self.onSelection = onSelection
        }
    }

    // MARK: - Items
    // Some are lazy, some need to be updated so they can't all be in a lazy array

    let textStyleFormattingTableViewController = TextStyleFormattingTableViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
    let textSizeFormattingTableViewController = TextSizeFormattingTableViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")

    private var textStyle: Item {
        let showTextStyleFormattingTableViewController = {
            self.textStyleFormattingTableViewController.delegate = self.delegate
            self.textStyleFormattingTableViewController.selectedTextStyleType = self.selectedTextStyleType
            self.textStyleFormattingTableViewController.apply(theme: self.theme)
            self.navigationController?.pushViewController(self.textStyleFormattingTableViewController, animated: true)
        }
        return Item(with: Content(type: .detail, title: textStyleFormattingTableViewController.titleLabelText, detailText: selectedTextStyleType.name), onSelection: showTextStyleFormattingTableViewController)
    }

    private var textSize: Item {
        let showTextSizeFormattingTableViewController = {
            self.textSizeFormattingTableViewController.delegate = self.delegate
            self.textSizeFormattingTableViewController.selectedTextSizeType = self.selectedTextSizeType
            self.textSizeFormattingTableViewController.apply(theme: self.theme)
            self.navigationController?.pushViewController(self.textSizeFormattingTableViewController, animated: true)
        }
        return Item(with: Content(type: .detail, title: textSizeFormattingTableViewController.titleLabelText, detailText: selectedTextSizeType.name), onSelection: showTextSizeFormattingTableViewController)
    }
    
    private func didSelectClearFormatting() {
        guard clearFormatting.content.isEnabled else {
            return
        }
        delegate?.textFormattingProvidingDidTapClearFormatting()
    }
    
    private lazy var clearFormatting: Item = {
        let content = Content(type: .destructiveAction, title: WMFLocalizedString("edit-text-clear-formatting", value: "Clear formatting", comment: "Title for the button that clears formatting from the selected range"), detailText: nil, customView: nil)
        let clearFormatting: () -> Void = { [weak self] in
          self?.didSelectClearFormatting()
        }
        return Item(with: content, onSelection: clearFormatting)
    }()

    private let textFormattingPlainToolbarView = TextFormattingPlainToolbarView.wmf_viewFromClassNib()
    private let textFormattingGroupedToolbarView = TextFormattingGroupedToolbarView.wmf_viewFromClassNib()
    
    weak override var delegate: TextFormattingDelegate? {
        didSet {
            textFormattingPlainToolbarView?.delegate = delegate
            textFormattingGroupedToolbarView?.delegate = delegate
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private lazy var staticItems: [Item] = {
        let plainToolbar = Item(with: Content(type: .customView, customView: textFormattingPlainToolbarView))

        let groupedToolbar = Item(with: Content(type: .customView, customView: textFormattingGroupedToolbarView))
        
        return [plainToolbar, groupedToolbar]
    }()

    private var items: [Item] {
        var allItems = staticItems
        allItems.append(textStyle)
        allItems.append(clearFormatting)
        return allItems
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
            cell.selectionStyle = .none
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
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .none
            cell.accessibilityTraits = .button
            return cell
        case .destructiveAction:
            guard let cell = tableView.dequeueCell(ofType: TextFormattingDetailTableViewCell.self, for: indexPath) else {
                break
            }
            guard let title = content.title else {
                    break
            }
            cell.apply(theme: theme)
            cell.configure(with: title, detailText: content.detailText)
            cell.textLabel?.textColor = content.isEnabled ? theme.colors.destructive : theme.colors.secondaryText
            cell.accessoryType = .none
            cell.selectionStyle = .none
            cell.accessibilityTraits =  content.isEnabled ? .button : [.button, .notEnabled]
            return cell
        }

        return nil
    }
    

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        item.onSelection?()
    }

    override func textSelectionDidChange(isRangeSelected: Bool) {
        super.textSelectionDidChange(isRangeSelected: isRangeSelected)
        textFormattingPlainToolbarView?.enableAllButtons()
        textFormattingGroupedToolbarView?.enableAllButtons()
        textStyleFormattingTableViewController.textSelectionDidChange(isRangeSelected: isRangeSelected)
        textSizeFormattingTableViewController.textSelectionDidChange(isRangeSelected: isRangeSelected)
        textFormattingPlainToolbarView?.deselectAllButtons()
        textFormattingGroupedToolbarView?.deselectAllButtons()
        clearFormatting.content.isEnabled = true
        tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .none)
        
    }

    override func buttonSelectionDidChange(button: SectionEditorButton) {
        super.buttonSelectionDidChange(button: button)
        textStyleFormattingTableViewController.buttonSelectionDidChange(button: button)
        textSizeFormattingTableViewController.buttonSelectionDidChange(button: button)
        textFormattingPlainToolbarView?.selectButton(button)
        textFormattingGroupedToolbarView?.selectButton(button)
    }

    override func disableButton(button: SectionEditorButton) {
        super.disableButton(button: button)
        textStyleFormattingTableViewController.disableButton(button: button)
        textSizeFormattingTableViewController.disableButton(button: button)
        textFormattingPlainToolbarView?.disableButton(button)
        textFormattingGroupedToolbarView?.disableButton(button)
        if button.kind == .clearFormatting {
            clearFormatting.content.isEnabled = false
            tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .none)
        }
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
