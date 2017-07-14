
import WebKit

@objc enum WMFArticleFooterMenuItem: Int {

    case languages, lastEdited, pageIssues, disambiguation, coordinate
    
    // Reminder: These are the strings used by the footerMenu JS transform:
    private var menuItemTypeString: String {
        switch self {
        case .languages: return "languages"
        case .lastEdited: return "lastEdited"
        case .pageIssues: return "pageIssues"
        case .disambiguation: return "disambiguation"
        case .coordinate: return "coordinate"
        }
    }
    
    private var menuItemTypeJSPath: String {
        return "window.wmf.footerMenu.MenuItemType.\(menuItemTypeString)"
    }
    
    private func localizedTitle(with article: MWKArticle) -> String {
        var title = ""
        let language = article.url.wmf_language
        switch self {
        case .languages: title = WMFLocalizedString("page-read-in-other-languages", language: language, value: "Available in %1$@ other languages", comment: "Label for button showing number of languages an article is available in. %1$@ will be replaced with the number of languages")
        case .lastEdited: title = WMFLocalizedString("page-last-edited",  language: language, value: "Edited %1$@ days ago", comment: "Label for button showing number of days since an article was last edited. %1$@ will be replaced with the number of days")
        case .pageIssues: title = WMFLocalizedString("page-issues", language: language, value: "Page issues", comment: "Label for the button that shows the \"Page issues\" dialog, where information about the imperfections of the current page is provided (by displaying the warning/cleanup templates).\n{{Identical|Page issue}}")
        case .disambiguation: title = WMFLocalizedString("page-similar-titles", language: language, value: "Similar pages", comment: "Label for button that shows a list of similar titles (disambiguation) for the current page")
        case .coordinate: title = WMFLocalizedString("page-location", language: language, value: "View on a map", comment: "Label for button used to show an article on the map")
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
        case .lastEdited: return WMFLocalizedString("page-edit-history", language: article.url.wmf_language, value: "Full edit history", comment: "Label for button used to show an article's complete edit history").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        default:
            return ""
        }
    }
    
    
    public func shouldAddItem(with article: MWKArticle) -> Bool {
        switch self {
        case .languages where !article.hasMultipleLanguages:
            return false
        case .pageIssues:
            // Always try to add - footer menu JS will hide this if no page issues found.
            return true
        case .disambiguation:
            // Always try to add - footer menu JS will hide this if no disambiguation titles found.
            return true
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
        "function(payload){" +
            "window.webkit.messageHandlers.footerMenuItemClicked.postMessage({'selection': '\(menuItemTypeString)', 'payload': payload});" +
        "}"
        
        return "window.wmf.footerMenu.maybeAddItem('\(title)', '\(subtitle)', \(self.menuItemTypeJSPath), 'pagelib_footer_container_menu_items', \(itemSelectionHandler), document);"
    }
}

extension WKWebView {
    
    public func wmf_addFooterContainer() {
        let footerContainerJS =
        "if (window.wmf.footerContainer.isContainerAttached(document) === false) {" +
            "document.querySelector('body').appendChild(window.wmf.footerContainer.containerFragment(document))" +
        "}"
        evaluateJavaScript(footerContainerJS, completionHandler: nil)
    }
    
    public func wmf_addFooterMenuForArticle(_ article: MWKArticle){
        let heading = WMFLocalizedString("article-about-title", language: article.url.wmf_language, value: "About this article", comment: "The text that is displayed before the 'about' section at the bottom of an article").wmf_stringByReplacingApostrophesWithBackslashApostrophes().uppercased(with: Locale.current)
        evaluateJavaScript("window.wmf.footerMenu.setHeading('\(heading)', 'pagelib_footer_container_menu_heading', document);", completionHandler: nil)

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
        let licenseString = String.localizedStringWithFormat(WMFLocalizedString("license-footer-text", language: article.url.wmf_language, value: "Content is available under %1$@ unless otherwise noted.", comment: "Marker at page end for who last modified the page when anonymous. %1$@ is a relative date such as '2 months ago' or 'today'."), "$1").wmf_stringByReplacingApostrophesWithBackslashApostrophes() // Replace with $1 for JavaScript
        let licenseSubstitutionString = WMFLocalizedString("license-footer-name", language: article.url.wmf_language, value: "CC BY-SA 3.0", comment: "License short name; usually leave untranslated as CC-BY-SA 3.0\n{{Identical|CC BY-SA}}").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let licenseLinkClickHandler =
        "function(){" +
            "window.webkit.messageHandlers.footerLegalLicenseLinkClicked.postMessage('linkClicked');" +
        "}"
        evaluateJavaScript("window.wmf.footerLegal.add(document, '\(licenseString)', '\(licenseSubstitutionString)', 'pagelib_footer_container_legal', \(licenseLinkClickHandler));", completionHandler: nil)
    }

    public func wmf_addFooterReadMoreForArticle(_ article: MWKArticle){
        guard
            let proxyURL = WMFProxyServer.shared().proxyURL(forWikipediaAPIHost: article.url.host),
            let title = (article.url as NSURL).wmf_title?.wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        else {
            assertionFailure("Expected read more title and proxyURL")
            return
        }
        
        evaluateJavaScript("window.addEventListener('resize', function(){window.wmf.footerContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window)});", completionHandler: nil)
        
        let heading = WMFLocalizedString("article-read-more-title", language: article.url.wmf_language, value: "Read more", comment: "The text that is displayed before the read more section at the bottom of an article\n{{Identical|Read more}}").wmf_stringByReplacingApostrophesWithBackslashApostrophes().uppercased(with: Locale.current)
        evaluateJavaScript("window.wmf.footerReadMore.setHeading('\(heading)', 'pagelib_footer_container_readmore_heading', document);", completionHandler: nil)

        let saveForLaterString = SaveButton.saveTitle(language:article.url.wmf_language).wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let savedForLaterString = SaveButton.savedTitle(language:article.url.wmf_language).wmf_stringByReplacingApostrophesWithBackslashApostrophes()

        let saveButtonTapHandler =
        "function(title){" +
            "window.webkit.messageHandlers.footerReadMoreSaveClicked.postMessage({'title': title})" +
        "}"
        
        let titlesShownHandler =
        "function(titles){" +
            "window.webkit.messageHandlers.footerReadMoreTitlesShown.postMessage(titles);" +
            "window.wmf.footerContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window);" +
        "}";
        
        evaluateJavaScript("window.wmf.footerReadMore.add(document, '\(proxyURL)', '\(title)', '\(saveForLaterString)', '\(savedForLaterString)', 'pagelib_footer_container_readmore_pages', \(saveButtonTapHandler), \(titlesShownHandler) );", completionHandler: nil)
    }
    
}
