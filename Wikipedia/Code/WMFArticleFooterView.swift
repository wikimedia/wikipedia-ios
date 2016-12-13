import UIKit

open class WMFArticleFooterView: UIView {

    @IBOutlet var licenseLabel: UILabel!
    @IBOutlet var showLicenseButton: UIButton!

    open func setLicenseTextForURL(_ url: URL) {
    
        let baseStyle = [NSForegroundColorAttributeName : UIColor.wmf_licenseText(),
            NSFontAttributeName : UIFont.systemFont(ofSize: 12)
        ] as [String : Any]
        
        let substitutionStyle = [NSForegroundColorAttributeName : UIColor.wmf_licenseLink(),
            NSFontAttributeName : UIFont.systemFont(ofSize: 12)
        ] as [String : Any]
        
        let footerText : NSString = localizedStringForURLWithKeyFallingBackOnEnglish(url, "license-footer-text");
        
        let licenseText : NSString = localizedStringForURLWithKeyFallingBackOnEnglish(url, "license-footer-name")
        
        let styledFooterText = footerText.attributedString(attributes: baseStyle, substitutionStrings: [licenseText], substitutionAttributes: [substitutionStyle])
        
        licenseLabel.attributedText = styledFooterText
    }
    
}
