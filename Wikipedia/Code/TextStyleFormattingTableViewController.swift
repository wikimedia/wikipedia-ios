class TextStyleFormattingTableViewController: UITableViewController {
    private let reuseIdentifier = "TextStyleFormattingTableViewCell"

    private struct Style {
        let name: String
        let font: UIFont
    }

    private lazy var styles: [Style] = {
        let paragraph = Style(name: "Paragraph", font: UIFont.wmf_font(.subheadline))
        let heading = Style(name: "Heading", font: UIFont.wmf_font(.title2))
        let subheading1 = Style(name: "Sub-heading 1", font: UIFont.wmf_font(.semiboldBody))
        let subheading2 = Style(name: "Sub-heading 2", font: UIFont.wmf_font(.semiboldSubheadline))
        let subheading3 = Style(name: "Sub-heading 3", font: UIFont.wmf_font(.semiboldFootnote))

        return [paragraph, heading, subheading1, subheading2, subheading3]
    }()

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let style = styles[indexPath.item]
        cell.textLabel?.text = style.name
        cell.textLabel?.font = style.font
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return styles.count
    }
}
