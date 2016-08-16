
import UIKit

public class WMFArticleFooterView: UIView {

    @IBOutlet var licenseLabel: UILabel!
    @IBOutlet var showLicenseButton: UIButton!

    public func setLicenseTextForURL(url: NSURL) {
    
        let baseStyle = [NSForegroundColorAttributeName : UIColor.wmf_licenseTextColor(),
            NSFontAttributeName : UIFont.systemFontOfSize(12)
        ]
        
        let substitutionStyle = [NSForegroundColorAttributeName : UIColor.wmf_licenseLinkColor(),
            NSFontAttributeName : UIFont.systemFontOfSize(12)
        ]
        
        let footerText : NSString = localizedStringForURLWithKeyFallingBackOnEnglish(url, "license-footer-text");
        
        let licenseText : NSString = localizedStringForURLWithKeyFallingBackOnEnglish(url, "license-footer-name")
        
        let styledFooterText = footerText.attributedStringWithAttributes(baseStyle, substitutionStrings: [licenseText], substitutionAttributes: [substitutionStyle])
        
        licenseLabel.attributedText = styledFooterText
    }
    
}
