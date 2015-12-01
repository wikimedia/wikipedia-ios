
import UIKit

public class WMFArticleFooterView: UIView {

    @IBOutlet var licenseLabel: UILabel!
    @IBOutlet var showLicenseButton: UIButton!

    public func setLicenseTextForSite(site: MWKSite) {
    
        let baseStyle = [NSForegroundColorAttributeName : UIColor.wmf_licenseTextColor(),
            NSFontAttributeName : UIFont.systemFontOfSize(12)
        ]
        
        let substitutionStyle = [NSForegroundColorAttributeName : UIColor.wmf_licenseLinkColor(),
            NSFontAttributeName : UIFont.systemFontOfSize(12)
        ]
        
        let footerText : NSString = localizedStringForSiteWithKeyFallingBackOnEnglish(site, "license-footer-text");
        
        let licenseText : NSString = localizedStringForSiteWithKeyFallingBackOnEnglish(site, "license-footer-name")
        
        let styledFooterText = footerText.attributedStringWithAttributes(baseStyle, substitutionStrings: [licenseText], substitutionAttributes: [substitutionStyle])
        
        licenseLabel.attributedText = styledFooterText
    }
    
}
