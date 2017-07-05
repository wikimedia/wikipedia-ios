extension ArticleCollectionViewCell: Themeable {
    public func apply(theme: Theme) {
        contentView.backgroundColor = theme.colors.paperBackground
        titleLabel.backgroundColor = theme.colors.paperBackground
        descriptionLabel.backgroundColor = theme.colors.paperBackground
        extractLabel?.backgroundColor = theme.colors.paperBackground
        imageView.backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.primaryText
        descriptionLabel.textColor = theme.colors.primaryText
        extractLabel?.textColor = theme.colors.primaryText
        tintColor = theme.colors.link
    }
}
