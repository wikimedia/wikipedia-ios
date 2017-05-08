
import Foundation

@objc enum WMFArticleFooterMenuItem: Int {

    case languages, lastEdited, pageIssues, disambiguation, coordinate
    
    // Reminder: These are the strings used by the footerMenu JS transform:
    private var footerMenuJSTransformEnumString: String {
        switch self {
        case .languages: return "languages"
        case .lastEdited: return "lastEdited"
        case .pageIssues: return "pageIssues"
        case .disambiguation: return "disambiguation"
        case .coordinate: return "coordinate"
        }
    }
    
    private var footerMenuTransformJSEnumPath: String {
        return "window.wmf.footerMenu.IconTypeEnum.\(footerMenuJSTransformEnumString)"
    }
    
    private func localizedTitle(with article: MWKArticle) -> String {
        var title = ""
        switch self {
        case .languages: title = WMFLocalizedStringWithDefaultValue("page-read-in-other-languages", article.url, Bundle.wmf_localization, "Available in %1$@ other languages", "Label for button showing number of languages an article is available in. %1$@ will be replaced with the number of languages")
        case .lastEdited: title = WMFLocalizedStringWithDefaultValue("page-last-edited", article.url, Bundle.wmf_localization, "Edited %1$@ days ago", "Label for button showing number of days since an article was last edited. %1$@ will be replaced with the number of days")
        case .pageIssues: title = WMFLocalizedStringWithDefaultValue("page-issues", article.url, Bundle.wmf_localization, "Page issues", "Label for the button that shows the \"Page issues\" dialog, where information about the imperfections of the current page is provided (by displaying the warning/cleanup templates).\n{{Identical|Page issue}}")
        case .disambiguation: title = WMFLocalizedStringWithDefaultValue("page-similar-titles", article.url, Bundle.wmf_localization, "Similar pages", "Label for button that shows a list of similar titles (disambiguation) for the current page")
        case .coordinate: title = WMFLocalizedStringWithDefaultValue("page-location", article.url, Bundle.wmf_localization, "View on a map", "Label for button used to show an article on the map")
        }
        return title.wmf_stringByReplacingApostrophesWithBackslashApostrophes()
    }
    
    private func titleSubstitutionStringForArticle(article: MWKArticle) -> String? {
        switch self {
        case .languages:
            return "\(article.languagecount)"
        case .lastEdited:
            let lastModified = article.lastmodified ?? Date()
            let days = NSCalendar.wmf_gregorian().wmf_days(from: lastModified, to: Date())
            return "\(days)"
        default:
            return nil
        }
    }
    
    private func localizedSubtitle(with article: MWKArticle) -> String {
        switch self {
        case .lastEdited: return WMFLocalizedStringWithDefaultValue("page-edit-history", article.url, Bundle.wmf_localization, "Full edit history", "Label for button used to show an article's complete edit history").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        default:
            return ""
        }
    }
    
    
    public func shouldAddItem(with article: MWKArticle) -> Bool {
        switch self {
        case .languages where !article.hasMultipleLanguages:
            return false
        case .pageIssues:
            guard let issues = article.pageIssues(), issues.count > 0 else {
                return false
            }
        case .disambiguation:
            guard let issues = article.disambiguationURLs(), issues.count > 0 else {
                return false
            }
        case .coordinate where !CLLocationCoordinate2DIsValid(article.coordinate):
            return false
        default:
            break
        }
        return true
    }
    
    public func itemAdditionJavascriptString(with article: MWKArticle) -> String {
        var title = self.localizedTitle(with: article)
        if let substitutionString = titleSubstitutionStringForArticle(article: article) {
            title = String.localizedStringWithFormat(title, substitutionString)
        }
        
        let subtitle = self.localizedSubtitle(with: article)
        
        let itemSelectionHandler =
        "function(){" +
            "window.webkit.messageHandlers.footerMenuItemClicked.postMessage('\(footerMenuJSTransformEnumString)');" +
        "}"
        
        return "window.wmf.footerMenu.addItem('\(title)', '\(subtitle)', \(self.footerMenuTransformJSEnumPath), 'footer_container_menu_items', \(itemSelectionHandler));"
    }
}

extension WKWebView {
    
    public func wmf_addFooterMenuForArticle(_ article: MWKArticle){
        let heading = WMFLocalizedStringWithDefaultValue("article-about-title", article.url, Bundle.wmf_localization, "About this article", "The text that is displayed before the 'about' section at the bottom of an article").wmf_stringByReplacingApostrophesWithBackslashApostrophes().uppercased(with: Locale.current)
        evaluateJavaScript("window.wmf.footerMenu.setHeading('\(heading)', 'footer_container_menu_heading');", completionHandler: nil)

        let itemsJS = [
            WMFArticleFooterMenuItem.languages,
            WMFArticleFooterMenuItem.coordinate,
            WMFArticleFooterMenuItem.lastEdited,
            WMFArticleFooterMenuItem.pageIssues,
            WMFArticleFooterMenuItem.disambiguation
            ].filter{$0.shouldAddItem(with: article)}
             .map{$0.itemAdditionJavascriptString(with: article)}
             .joined(separator: "")
        
        evaluateJavaScript(itemsJS, completionHandler: nil)
    }

    public func wmf_addFooterLegalForArticle(_ article: MWKArticle){
        let licenseString = String.localizedStringWithFormat(WMFLocalizedStringWithDefaultValue("license-footer-text", article.url, Bundle.wmf_localization, "Content is available under %1$@ unless otherwise noted.", "Marker at page end for who last modified the page when anonymous. %1$@ is a relative date such as '2 months ago' or 'today'."), "$1").wmf_stringByReplacingApostrophesWithBackslashApostrophes() // Replace with $1 for JavaScript
        let licenseSubstitutionString = WMFLocalizedStringWithDefaultValue("license-footer-name", article.url, Bundle.wmf_localization, "CC BY-SA 3.0", "License short name; usually leave untranslated as CC-BY-SA 3.0\n{{Identical|CC BY-SA}}").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let licenseLinkClickHandler =
        "function(){" +
            "window.webkit.messageHandlers.footerLegalLicenseLinkClicked.postMessage('linkClicked');" +
        "}"
        evaluateJavaScript("window.wmf.footerLegal.add('\(licenseString)', '\(licenseSubstitutionString)', 'footer_container_legal', \(licenseLinkClickHandler));", completionHandler: nil)
    }

    public func wmf_addFooterReadMoreForArticle(_ article: MWKArticle){
        guard
            let proxyURL = WMFProxyServer.shared().proxyURL(forWikipediaAPIHost: article.url.host),
            let title = (article.url as NSURL).wmf_title?.wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        else {
            assertionFailure("Expected read more title and proxyURL")
            return
        }
        
        let heading = WMFLocalizedStringWithDefaultValue("article-read-more-title", article.url, Bundle.wmf_localization, "Read more", "The text that is displayed before the read more section at the bottom of an article\n{{Identical|Read more}}").wmf_stringByReplacingApostrophesWithBackslashApostrophes().uppercased(with: Locale.current)
        evaluateJavaScript("window.wmf.footerReadMore.setHeading('\(heading)', 'footer_container_readmore_heading');", completionHandler: nil)

        let saveForLaterString = SaveButton.saveTitle.wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let savedForLaterString = SaveButton.savedTitle.wmf_stringByReplacingApostrophesWithBackslashApostrophes()

        let tapHandler =
            "function(href){" +
                "window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href })" +
        "}"

        let saveButtonTapHandler =
        "function(title){" +
            "window.webkit.messageHandlers.footerReadMoreSaveClicked.postMessage({'title': title})" +
        "}"
        
        let titlesShownHandler =
        "function(titles){" +
            "window.webkit.messageHandlers.footerReadMoreTitlesShown.postMessage(titles)" +
        "}";
        
        evaluateJavaScript("window.wmf.footerReadMore.add('\(proxyURL)', '\(title)', '\(saveForLaterString)', '\(savedForLaterString)', 'footer_container_readmore_pages', \(tapHandler), \(saveButtonTapHandler), \(titlesShownHandler) );", completionHandler: nil)
    }
    
}
