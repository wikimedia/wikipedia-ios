extension ArticleCollectionViewCell: Themeable {
    public func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.primaryText
        descriptionLabel.textColor = theme.colors.primaryText
        extractLabel?.textColor = theme.colors.primaryText
        tintColor = theme.colors.link
    }
    
    open override var backgroundColor: UIColor? {
        didSet {
            titleLabel.backgroundColor = backgroundColor
            descriptionLabel.backgroundColor = backgroundColor
            extractLabel?.backgroundColor = backgroundColor
            imageView.backgroundColor = backgroundColor
        }
    }
}
