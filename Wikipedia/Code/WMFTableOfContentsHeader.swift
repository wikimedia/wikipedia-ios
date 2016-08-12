import UIKit

public class WMFTableOfContentsHeader: UIView {
    @IBOutlet public var contentsLabel: UILabel!
    
    var url:NSURL!

    public var articleURL:NSURL! {
        get {
            return url
        }
        set(newURL){
            self.contentsLabel.text = self.headerTextForURL(newURL)
            url = newURL
        }
    }
    
    public func headerTextForURL(url: NSURL) -> String {
        var headerString = localizedStringForURLWithKeyFallingBackOnEnglish(url, "table-of-contents-heading")
        if(NSLocale.wmf_isCurrentLocaleEnglish()){
            headerString = headerString.uppercaseStringWithLocale(NSLocale.currentLocale())
        }
        return headerString
    }
}
