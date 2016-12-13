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
        if(Locale.wmf_isCurrentLocaleEnglish()){
            headerString = headerString.uppercased(with: Locale.current)
        }
        return headerString
    }
}
