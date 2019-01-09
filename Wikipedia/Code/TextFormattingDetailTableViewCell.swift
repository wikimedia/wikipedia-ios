class TextFormattingDetailTableViewCell: TextFormattingTableViewCell {
    func configure(with title: String, detailText: String) {
        textLabel?.text = title
        detailTextLabel?.text = detailText
    }

    override func updateFonts() {
        let font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        textLabel?.font = font
        detailTextLabel?.font = font
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
         textLabel?.textColor = theme.colors.primaryText
         detailTextLabel?.textColor = theme.colors.primaryText
    }
}
