import UIKit

public class WMFTableOfContentsHeader: UIView {
    @IBOutlet public var contentsLabel: UILabel!
    
    var site:MWKSite!
    
    public var articleSite:MWKSite! {
        get {
            return site
        }
        set(newSite){
            self.contentsLabel.text = self.headerTextForSite(newSite)
            site = newSite
        }
    }
    
    public func headerTextForSite(site: MWKSite) -> String {
        var headerString = localizedStringForSiteWithKeyFallingBackOnEnglish(site, "table-of-contents-heading")
        if(NSLocale.wmf_isCurrentLocaleEnglish()){
            headerString = headerString.uppercaseStringWithLocale(NSLocale.currentLocale())
        }
        return headerString
    }
}
