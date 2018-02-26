import UIKit

@objc(WMFNewsCollectionViewCell)
public class NewsCollectionViewCell: SideScrollingCollectionViewCell {
    var descriptionFont:UIFont? = nil
    var descriptionLinkFont:UIFont? = nil

    override public func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        descriptionFont = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        descriptionLinkFont = UIFont.wmf_preferredFontForFontFamily(.systemSemiBold, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
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
        let attributedString = descriptionHTML.wmf_attributedStringByRemovingHTML(with: descriptionFont, linkFont: descriptionLinkFont)
        descriptionLabel.attributedText = attributedString
    }
    
    var descriptionHTML: String? {
        didSet {
            updateDescriptionHTMLStyle()
        }
    }
}
