extension ArticleCollectionViewCell: Themeable {
    open func apply(theme: Theme) {
        // when we establish batch selection colors for all themes, move this to Theme
        let selected = batchEditingTranslation > 0 && theme == .light ? theme.colors.disabledLink : theme.colors.midBackground
        setBackgroundColors(theme.colors.paperBackground, selected: selected)
        imageView.backgroundColor = theme.colors.midBackground
        titleLabel.textColor = theme.colors.primaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        extractLabel?.textColor = theme.colors.primaryText
        saveButton.setTitleColor(theme.colors.link, for: .normal)
        imageView.alpha = theme.imageOpacity
        actionsView.apply(theme: theme)
        updateSelectedOrHighlighted()
    }
}

extension ArticleRightAlignedImageCollectionViewCell {
    open override func apply(theme: Theme) {
        super.apply(theme: theme)
        bottomSeparator.backgroundColor = theme.colors.border
        topSeparator.backgroundColor = theme.colors.border
    }
}
