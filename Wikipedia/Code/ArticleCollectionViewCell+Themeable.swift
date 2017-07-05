extension ArticleCollectionViewCell: Themeable {
    public func apply(theme: Theme) {
        backgroundColor = theme.paper
        titleLabel.textColor = theme.text
        titleLabel.backgroundColor = theme.paper
        descriptionLabel.textColor = theme.text
        descriptionLabel.backgroundColor = theme.paper
        extractLabel?.textColor = theme.text
        extractLabel?.backgroundColor = theme.paper
        tintColor = theme.link
    }
}
