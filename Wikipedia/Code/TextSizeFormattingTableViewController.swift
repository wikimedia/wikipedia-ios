class TextSizeFormattingTableViewController: TextFontFormattingTableViewController {

    override var titleLabelText: String? {
        return "Text size"
    }

    private struct Size {
        let type: TextSizeType
        let name: String
        let font: UIFont
    }

    private lazy var sizes: [Size] = {
        let normalType = TextSizeType.normal
        let normal = Size(type: normalType, name: normalType.name, font: UIFont.wmf_font(.subheadline))

        let bigType = TextSizeType.big
        let big = Size(type: bigType, name: bigType.name, font: UIFont.wmf_font(.title2))

        let smallType = TextSizeType.small
        let small = Size(type: smallType, name: smallType.name, font: UIFont.wmf_font(.semiboldBody))

        return [normal, big, small]
    }()

    override func configuredCell(_ cell: TextFormattingTableViewCell, at indexPath: IndexPath) -> UITableViewCell {
        let size = sizes[indexPath.row]
        if size.type == selectedTextSizeType {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        cell.textLabel?.text = size.name
        cell.textLabel?.font = size.font
        cell.layoutMargins = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 0)

        cell.apply(theme: theme)

        return cell
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        tableView.indexPathsForSelectedRows?.forEach { selectedIndexPath in
            let cell = tableView.cellForRow(at: selectedIndexPath)
            cell?.accessoryType = .none
            
            // Ensure 'Normal' is always selected if no other size is active.
            // Needed if user taps 'Normal' when it's already checked - in this case it needs to remain checked.
            let isFirstCell = indexPath.row == 0 && indexPath.section == 0
            if isFirstCell {
                cell?.accessoryType = .checkmark
            }
        }
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sizes.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let size = sizes[indexPath.row]
        delegate?.textSizeTapped(newSize: size.name, sender: self)
    }
}
