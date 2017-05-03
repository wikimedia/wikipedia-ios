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
        let headerString = WMFLocalizedStringWithDefaultValue("table-of-contents-heading", url, Bundle.wmf_localization, "Contents", "Header text appearing above the first section in the table of contents\n{{Identical|Content}}")
        if (NSLocale.wmf_isCurrentLocaleEnglish()) {
            return headerString.uppercased(with: Locale.current)
        } else {
            return headerString
        }
    }
}
