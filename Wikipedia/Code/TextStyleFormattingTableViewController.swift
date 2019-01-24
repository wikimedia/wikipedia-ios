class TextStyleFormattingTableViewController: TextFontFormattingTableViewController {

    override var titleLabelText: String? {
        return WMFLocalizedString("edit-style-table-view-title", value: "Style", comment: "Title for the text style menu in the editing interface")
    }

    private struct Style {
        let type: TextStyleType
        let name: String
        let font: UIFont
    }

    private lazy var styles: [Style] = {
        let paragraphType = TextStyleType.paragraph
        let paragraph = Style(type: paragraphType, name: paragraphType.name, font: UIFont.wmf_font(.subheadline))

        let headingType = TextStyleType.heading
        let heading = Style(type: headingType, name: headingType.name, font: UIFont.wmf_font(.title2))

        let subheading1Type = TextStyleType.subheading1
        let subheading1 = Style(type: subheading1Type, name: subheading1Type.name, font: UIFont.wmf_font(.semiboldBody))

        let subheading2Type = TextStyleType.subheading2
        let subheading2 = Style(type: subheading2Type, name: subheading2Type.name, font: UIFont.wmf_font(.semiboldSubheadline))

        let subheading3Type = TextStyleType.subheading3
        let subheading3 = Style(type: subheading3Type, name: subheading3Type.name, font: UIFont.wmf_font(.semiboldFootnote))

        let subheading4Type = TextStyleType.subheading4
        let subheading4 = Style(type: subheading4Type, name: subheading4Type.name, font: UIFont.wmf_font(.semiboldCaption2))

        return [paragraph, heading, subheading1, subheading2, subheading3, subheading4]
    }()

    override func configuredCell(_ cell: TextFormattingTableViewCell, at indexPath: IndexPath) -> UITableViewCell {
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return styles.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        let style = styles[indexPath.row]
        let depth = style.type.rawValue
        delegate?.textFormattingProvidingDidTapHeading(depth: depth)
    }
}
