import UIKit

open class WMFTableOfContentsHeader: UIView {
    @IBOutlet open var contentsLabel: UILabel!
    
    var url:URL!

    open var articleURL:URL! {
        get {
            return url
        }
        set(newURL){
            self.contentsLabel.text = self.headerTextForURL(newURL)
            url = newURL
        }
    }
    
    open func headerTextForURL(_ url: URL) -> String {
        var headerString = localizedStringForURLWithKeyFallingBackOnEnglish(url, "table-of-contents-heading")
        if(NSLocale.wmf_isCurrentLocaleEnglish()){
            headerString = headerString.uppercaseStringWithLocale(NSLocale.currentLocale())
        }
        return headerString
    }
}
