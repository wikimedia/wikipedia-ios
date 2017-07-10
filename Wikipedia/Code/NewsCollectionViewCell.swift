import UIKit

@objc(WMFNewsCollectionViewCell)
class NewsCollectionViewCell: SideScrollingCollectionViewCell {
    var descriptionFont:UIFont? = nil
    var descriptionLinkFont:UIFont? = nil

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        descriptionFont = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        descriptionLinkFont = UIFont.wmf_preferredFontForFontFamily(.systemBold, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        updateDescriptionHTMLStyle()
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
