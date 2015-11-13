import UIKit

public class WMFTableOfContentsHeader: UIView {

    @IBOutlet public var contentsLabel: UILabel!
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        var headerString = localizedStringForKeyFallingBackOnEnglish("table-of-contents-heading")
        
        if(NSLocale.wmf_isCurrentLocaleEnglish()){
            headerString = headerString.uppercaseStringWithLocale(NSLocale.currentLocale())
        }
        self.contentsLabel.text = headerString
    }
    
    public override func layoutSubviews() {
        //See WMFTableOfContentsViewController.forceUpdateHeaderFrame for explanation
        super.layoutSubviews()
        self.contentsLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.contentsLabel.frame);
    }
}
