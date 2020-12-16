import UIKit

open class TableOfContentsHeader: UIView {
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
        let headerString = WMFLocalizedString("table-of-contents-heading", language: url.wmf_language, value: "Contents", comment: "Header text appearing above the first section in the table of contents {{Identical|Content}}")
        if (Locale.current.isEnglish) {
            return headerString.uppercased(with: Locale.current)
        } else {
            return headerString
        }
    }
}
