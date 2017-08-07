extension ArticleCollectionViewCell: Themeable {
    public func apply(theme: Theme) {
        backgroundView?.backgroundColor = theme.colors.paperBackground
        selectedBackgroundView?.backgroundColor = theme.colors.midBackground
        imageView.backgroundColor = theme.colors.midBackground
        titleLabel.textColor = theme.colors.primaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        extractLabel?.textColor = theme.colors.primaryText
        saveButton.setTitleColor(theme.colors.link, for: .normal)
        imageView.alpha = theme.imageOpacity
        updateSelectedOrHighlighted()
    }
}
