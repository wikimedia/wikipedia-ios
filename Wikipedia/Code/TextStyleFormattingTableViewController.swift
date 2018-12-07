class TextStyleFormattingTableViewController: TextFormattingProvidingTableViewController {

    override var titleLabelText: String? {
        return "Style"
    }

    private var isRootViewController: Bool {
        guard let navigationController = navigationController else {
            assertionFailure("View controller expected to be embedded inside a navigation controller")
            return false
        }
        let viewControllers = navigationController.viewControllers
        guard viewControllers.count > 0, let first = viewControllers.first else {
            return false
        }
        return viewControllers.count == 1 && first is TextStyleFormattingTableViewController
    }

    override var shouldSetCustomTitleLabel: Bool {
        return isRootViewController
    }

    private struct Style {
        let type: TextStyleType
        let name: String
        let font: UIFont
    }

    private lazy var styles: [Style] = {
        let paragraph = Style(type: .paragraph, name: "Paragraph", font: UIFont.wmf_font(.subheadline))
        let heading = Style(type: .heading, name: "Heading", font: UIFont.wmf_font(.title2))
        let subheading1 = Style(type: .subheading1, name: "Sub-heading 1", font: UIFont.wmf_font(.semiboldBody))
        let subheading2 = Style(type: .subheading2, name: "Sub-heading 2", font: UIFont.wmf_font(.semiboldSubheadline))
        let subheading3 = Style(type: .subheading3, name: "Sub-heading 3", font: UIFont.wmf_font(.semiboldFootnote))

        return [paragraph, heading, subheading1, subheading2, subheading3]
    }()

    override func styleTypeDidChange() {
        guard navigationController != nil else {
            return
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TextFormattingTableViewCell.identifier, for: indexPath) as? TextFormattingTableViewCell else {
            return UITableViewCell()
        }
        return configuredCell(cell, at: indexPath)
    }

    private func configuredCell(_ cell: TextFormattingTableViewCell, at indexPath: IndexPath) -> UITableViewCell {
        let style = styles[indexPath.row]
        if style.type == selectedTextStyleType {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        cell.textLabel?.text = style.name
        cell.textLabel?.font = style.font
        cell.layoutMargins = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 0)

        cell.apply(theme: theme)

        return cell
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        tableView.indexPathsForSelectedRows?.forEach { selectedIndexPath in
            let cell = tableView.cellForRow(at: selectedIndexPath)
            cell?.accessoryType = .none
        }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return styles.count
    }
}
