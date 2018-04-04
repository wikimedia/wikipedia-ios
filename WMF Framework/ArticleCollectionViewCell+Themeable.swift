extension ArticleCollectionViewCell: Themeable {
    open func apply(theme: Theme) {
        let selected = isBatchEditing ? theme.colors.batchSelectionBackground : theme.colors.midBackground
        setBackgroundColors(theme.colors.paperBackground, selected: selected)
        imageView.backgroundColor = theme.colors.midBackground
        titleLabel.textColor = theme.colors.primaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        extractLabel?.textColor = theme.colors.primaryText
        saveButton.setTitleColor(theme.colors.link, for: .normal)
        imageView.alpha = theme.imageOpacity
        statusView.backgroundColor = theme.colors.warning
        alertIcon.tintColor = alertType == .downloading ? theme.colors.warning : theme.colors.error
        alertLabel.textColor = alertType == .downloading ? theme.colors.warning : theme.colors.error
        actionsView.apply(theme: theme)
        batchEditSelectView?.apply(theme: theme)
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
