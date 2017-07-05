extension ArticleCollectionViewCell: Themeable {
    public func apply(theme: Theme) {
        backgroundColor = theme.paper
        titleLabel.textColor = theme.text
        descriptionLabel.textColor = theme.text
        extractLabel?.textColor = theme.text
        tintColor = theme.link
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
