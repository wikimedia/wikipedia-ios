
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
    
    private var localizedTitleKey: String {
        switch self {
        case .languages: return "page-read-in-other-languages"
        case .lastEdited: return "page-last-edited"
        case .pageIssues: return "page-issues"
        case .disambiguation: return "page-similar-titles"
        case .coordinate: return "page-location"
        }
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
    
    private var localizedSubtitleKey: String? {
        switch self {
        case .lastEdited: return "page-edit-history"
        default:
            return nil
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
        var title = article.apostropheEscapedArticleLanguageLocalizedStringForKey(self.localizedTitleKey)
        if let substitutionString = titleSubstitutionStringForArticle(article: article) {
            title = title.replacingOccurrences(of: "$1", with: substitutionString)
        }
        
        var subtitle = ""
        if let subtitleKey = self.localizedSubtitleKey{
            subtitle = article.apostropheEscapedArticleLanguageLocalizedStringForKey(subtitleKey)
        }
        
        let itemSelectionHandler =
        "function(){" +
            "window.webkit.messageHandlers.footerMenuItemClicked.postMessage('\(footerMenuJSTransformEnumString)');" +
        "}"
        
        return "window.wmf.footerMenu.addItem('\(title)', '\(subtitle)', \(self.footerMenuTransformJSEnumPath), 'footer_container_menu', \(itemSelectionHandler));"
    }
}

extension WKWebView {
    
    public func wmf_addFooterMenuForArticle(_ article: MWKArticle){
        let heading = article.apostropheEscapedArticleLanguageLocalizedStringForKey("article-about-title").uppercased(with: Locale.current)
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
        let licenseString = article.apostropheEscapedArticleLanguageLocalizedStringForKey("license-footer-text")
        let licenseSubstitutionString = article.apostropheEscapedArticleLanguageLocalizedStringForKey("license-footer-name")
        let licenseLinkClickHandler =
        "function(){" +
            "window.webkit.messageHandlers.footerLegalLicenseLinkClicked.postMessage('linkClicked');" +
        "}"
        evaluateJavaScript("window.wmf.footerLegal.add('\(licenseString)', '\(licenseSubstitutionString)', 'footer_container_legal', \(licenseLinkClickHandler));", completionHandler: nil)
    }

    public func wmf_addFooterReadMoreForArticle(_ article: MWKArticle){
        guard
            let proxyURL = WMFProxyServer.shared().proxyURL(forWikipediaAPIHost: article.url.host),
            let title = (article.url as NSURL).wmf_title
        else {
            assert(false, "Expected read more title and proxyURL")
        }
        
        let heading = article.apostropheEscapedArticleLanguageLocalizedStringForKey("article-read-more-title").uppercased(with: Locale.current)
        evaluateJavaScript("window.wmf.footerReadMore.setHeading('\(heading)', 'footer_container_readmore_heading');", completionHandler: nil)

        let saveForLaterString = article.apostropheEscapedArticleLanguageLocalizedStringForKey("button-save-for-later")
        let savedForLaterString = article.apostropheEscapedArticleLanguageLocalizedStringForKey("button-saved-for-later")

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
        
        evaluateJavaScript("window.wmf.footerReadMore.add('\(proxyURL)', '\(title)', '\(saveForLaterString)', '\(savedForLaterString)', 'footer_container_readmore_items', \(tapHandler), \(saveButtonTapHandler), \(titlesShownHandler) );", completionHandler: nil)
    }
    
}
