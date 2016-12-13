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
        guard let headerString = localizedStringForURLWithKeyFallingBackOnEnglish(url, "table-of-contents-heading") else {
            return ""
        }
        if (NSLocale.wmf_isCurrentLocaleEnglish()) {
            return headerString.uppercased(with: Locale.current)
        } else {
            return headerString
        }
    }
}
