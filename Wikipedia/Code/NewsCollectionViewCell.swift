import UIKit

@objc(WMFNewsCollectionViewCell)
class NewsCollectionViewCell: SideScrollingCollectionViewCell {    
    override func setup() {
        super.setup()
        updateDescriptionFonts()
    }
    
    var descriptionFont:UIFont? = nil
    var descriptionLinkFont:UIFont? = nil

    private func updateDescriptionFonts() {
        descriptionFont = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        descriptionLinkFont = UIFont.wmf_preferredFontForFontFamily(.systemBold, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDescriptionFonts()
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
