import WMFComponents

class ActionButton: SetupButton {
    
    var titleLabelFont = WMFFont.mediumSubheadline

    override func setup() {
        super.setup()
        var deprecatedSelf = self as DeprecatedButton
        deprecatedSelf.deprecatedContentEdgeInsets = UIEdgeInsets(top: layoutMargins.top + 1, left: layoutMargins.left + 7, bottom: layoutMargins.bottom + 1, right: layoutMargins.right + 7)
        titleLabel?.numberOfLines = 0
        updateFonts(with: traitCollection)
    }
    
    // MARK: - Dynamic Type
    // Only applies new fonts if the content size category changes
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        maybeUpdateFonts(with: traitCollection)
    }
    
    var contentSizeCategory: UIContentSizeCategory?
    fileprivate func maybeUpdateFonts(with traitCollection: UITraitCollection) {
        guard contentSizeCategory == nil || contentSizeCategory != traitCollection.preferredContentSizeCategory else {
            return
        }
        contentSizeCategory = traitCollection.preferredContentSizeCategory
        updateFonts(with: traitCollection)
    }
    
    // Override this method and call super
    open func updateFonts(with traitCollection: UITraitCollection) {
        titleLabel?.font = WMFFont.for(titleLabelFont, compatibleWith: traitCollection)
    }
}

extension ActionButton: Themeable {
    func apply(theme: Theme) {
        setTitleColor(theme.colors.link, for: .normal)
        backgroundColor = theme.colors.cardButtonBackground
        layer.cornerRadius = 5
    }
    
}
