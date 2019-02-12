class TextFontFormattingTableViewController: TextFormattingProvidingTableViewController {

    var isRootViewController: Bool {
        guard let navigationController = navigationController else {
            assertionFailure("View controller expected to be embedded inside a navigation controller")
            return false
        }
        let viewControllers = navigationController.viewControllers
        guard !viewControllers.isEmpty, let first = viewControllers.first else {
            return false
        }
        return viewControllers.count == 1 && first is TextFontFormattingTableViewController
    }

    override var shouldSetCustomTitleLabel: Bool {
        return isRootViewController
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let firstIndexPath = IndexPath(row: 0, section: 0)
        if indexPath ==  tableView.indexPathForSelectedRow || indexPath == lastSelectedIndexPath {
            return firstIndexPath
        } else {
            return indexPath
        }
    }

    private var lastSelectedIndexPath: IndexPath?

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .none
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        lastSelectedIndexPath = indexPath
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TextFormattingTableViewCell.identifier, for: indexPath) as? TextFormattingTableViewCell else {
            return UITableViewCell()
        }
        return configuredCell(cell, at: indexPath)
    }

    open func configuredCell(_ cell: TextFormattingTableViewCell, at indexPath: IndexPath) -> UITableViewCell {
        assertionFailure("Subclasses should override")
        return cell
    }
}
