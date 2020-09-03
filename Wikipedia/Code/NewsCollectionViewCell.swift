import UIKit

public class NewsCollectionViewCell: SideScrollingCollectionViewCell {
    var descriptionFont:UIFont? = nil
    var descriptionLinkFont:UIFont? = nil

    override public func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        descriptionFont = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        descriptionLinkFont = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        updateDescriptionHTMLStyle()
    }
    
    override public func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        collectionView.backgroundColor = labelBackgroundColor
    }
    
    func updateDescriptionHTMLStyle() {
        guard
            let descriptionHTML = descriptionHTML,
            let descriptionFont = descriptionFont,
            let descriptionLinkFont = descriptionLinkFont
        else {
            descriptionLabel.text = nil
            return
        }
        let attributedString = descriptionHTML.wmf_attributedStringFromHTML(with: descriptionFont, boldFont: descriptionLinkFont, italicFont: descriptionFont, boldItalicFont: descriptionLinkFont, color: descriptionLabel.textColor, linkColor: nil, handlingLists: false, handlingSuperSubscripts: false, withAdditionalBoldingForMatchingSubstring:nil, tagMapping: ["a":"b"], additionalTagAttributes: nil)
        descriptionLabel.attributedText = attributedString
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
