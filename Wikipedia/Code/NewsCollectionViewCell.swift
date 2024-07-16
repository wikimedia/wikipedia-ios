import Components

public class NewsCollectionViewCell: SideScrollingCollectionViewCell {

    override public func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        updateDescriptionHTMLStyle()
    }
    
    override public func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        collectionView.backgroundColor = labelBackgroundColor
    }

    private var styles: HtmlUtils.Styles {
        HtmlUtils.Styles(font: WKFont.for(.callout, compatibleWith: traitCollection), boldFont: WKFont.for(.boldCallout, compatibleWith: traitCollection), italicsFont: WKFont.for(.italicCallout, compatibleWith: traitCollection), boldItalicsFont: WKFont.for(.boldItalicCallout, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: nil, lineSpacing: 3)
    }

    private func getAttributedString(_ htmlString: String) -> NSAttributedString {
        return (try? HtmlUtils.nsAttributedStringFromHtml(htmlString, styles: styles)) ?? NSAttributedString(string: htmlString)
    }

    func updateDescriptionHTMLStyle() {
        guard let descriptionHTML = descriptionHTML else {
            descriptionLabel.text = nil
            return
        }
        descriptionLabel.attributedText = getAttributedString(descriptionHTML)
    }
    
    var descriptionHTML: String? {
        didSet {
            updateDescriptionHTMLStyle()
        }
    }
}

public class NewsExploreCollectionViewCell: NewsCollectionViewCell {
    public override func apply(theme: Theme) {
        super.apply(theme: theme)
        setBackgroundColors(theme.colors.cardBackground, selected: theme.colors.selectedCardBackground)
    }
}
