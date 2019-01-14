class TextSizeFormattingTableViewController: TextFontFormattingTableViewController {

    override var titleLabelText: String? {
        return WMFLocalizedString("edit-text-size-table-view-title", value: "Text size", comment: "Title for text size menu in the editing interface")
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
        cell.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)

        cell.apply(theme: theme)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sizes.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        let size = sizes[indexPath.row]
        delegate?.textFormattingProvidingDidTapTextSize(newSize: size.type)
    }
}
