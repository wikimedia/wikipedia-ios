
import WebKit
import WMF

@objc enum WMFArticleFooterMenuItem: Int {

    case languages, lastEdited, pageIssues, disambiguation, coordinate, talkPage
    
    // Reminder: These are the strings used by the footerMenu JS transform:
    private var menuItemTypeString: String {
        switch self {
        case .languages: return "languages"
        case .lastEdited: return "lastEdited"
        case .pageIssues: return "pageIssues"
        case .disambiguation: return "disambiguation"
        case .coordinate: return "coordinate"
        case .talkPage: return "talkPage"
        }
    }
    
    public var menuItemTypeJSPath: String {
        return "window.wmf.footerMenu.MenuItemType.\(menuItemTypeString)"
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
}

extension WKWebView {
    
    @objc static public func wmf_themeApplicationJavascript(with theme: Theme?) -> String {
        var jsThemeConstant = "DEFAULT"
        guard let theme = theme else {
            return jsThemeConstant
        }
        var isDim = false
        switch theme.name {
        case Theme.sepia.name:
            jsThemeConstant = "SEPIA"
        case Theme.darkDimmed.name:
            isDim = true
            fallthrough
        case Theme.dark.name:
            jsThemeConstant = "DARK"
        default:
            break
        }
        return "window.wmf.themes.setTheme(document, window.wmf.themes.THEME.\(jsThemeConstant));" +
            "window.wmf.imageDimming.dim(window, \(isDim ? "true" : "false"));"
    }
    
    @objc public func wmf_applyTheme(_ theme: Theme){
        let themeJS = WKWebView.wmf_themeApplicationJavascript(with: theme)
        evaluateJavaScript(themeJS, completionHandler: nil)
    }
    
// TODO: update this TEMPORARY method naming
    @objc public func wmf_loadArticle2(_ article: MWKArticle){
        guard
            let url = article.url,
            let proxyURL = WMFProxyServer.shared().proxyURL(forWikipediaAPIHost: url.host),
            let encodedTitle = url.wmf_titleWithUnderscores,
            let lang = (url as NSURL).wmf_language
            else {
                assertionFailure("Expected proxyURL")
                return
        }

        // https://github.com/wikimedia/wikipedia-ios/pull/1334/commits/f2b2228e2c0fd852479464ec84e38183d1cf2922
        let apiURLString = "/w/api.php?action=mobileview&format=json&noheadings=true&pilicense=any&prop=sections%7Ctext%7Clastmodified%7Clastmodifiedby%7Clanguagecount%7Cid%7Cprotection%7Ceditable%7Cdisplaytitle%7Cthumb%7Cdescription%7Cimage%7Crevision%7Cnamespace&sectionprop=toclevel%7Cline%7Canchor%7Clevel%7Cnumber%7Cfromtitle%7Cindex&sections=all&thumbwidth=640&page=\(encodedTitle)".wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        
        var nonNilTitle = ""
        if let title = article.displaytitle ?? (url as NSURL).wmf_title {
            nonNilTitle = title.wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        }
        
        var nonNilDescription = ""
        if let description = article.entityDescription {
            nonNilDescription = description.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: article.url.wmf_language).wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        }
        
        let langInfo = MWLanguageInfo(forCode: lang)
        
        
        
        

        
        
        
        let proxyURLString = proxyURL.absoluteString.wmf_stringByReplacingApostrophesWithBackslashApostrophes()

        let langCode = langInfo.code
        let langDir = langInfo.dir
        let isRTL = UIApplication.shared.wmf_isRTL ? "true": "false"
        let newJSLanguage = "new window.wmf.sectionTransformation.Language('\(langCode)', '\(langDir)', \(isRTL))"
        
        let infoboxTitle = WMFLocalizedString("info-box-title", language: lang, value: "Quick Facts", comment: "The title of infoboxes – in collapsed and expanded form").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let tableTitle = WMFLocalizedString("table-title-other", language: lang, value: "More information", comment: "The title of non-info box tables - in collapsed and expanded form\n{{Identical|More information}}").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let closeBoxText = WMFLocalizedString("info-box-close-text", language: lang, value: "Close", comment: "The text for telling users they can tap the bottom of the info box to close it\n{{Identical|Close}}").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let readMoreHeading = WMFLocalizedString("article-read-more-title", language: lang, value: "Read more", comment: "The text that is displayed before the read more section at the bottom of an article\n{{Identical|Read more}}").wmf_stringByReplacingApostrophesWithBackslashApostrophes().uppercased(with: Locale.current).wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let licenseString = String.localizedStringWithFormat(WMFLocalizedString("license-footer-text", language: lang, value: "Content is available under %1$@ unless otherwise noted.", comment: "Marker at page end for who last modified the page when anonymous. %1$@ is a relative date such as '2 months ago' or 'today'."), "$1").wmf_stringByReplacingApostrophesWithBackslashApostrophes() // Replace with $1 for JavaScript
        let licenseSubstitutionString = WMFLocalizedString("license-footer-name", language: lang, value: "CC BY-SA 3.0", comment: "License short name; usually leave untranslated as CC-BY-SA 3.0\n{{Identical|CC BY-SA}}").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let viewInBrowserString = WMFLocalizedString("view-in-browser-footer-link", language: lang, value: "View article in browser", comment: "Link to view article in browser").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let menuHeading = WMFLocalizedString("article-about-title", language: article.url.wmf_language, value: "About this article", comment: "The text that is displayed before the 'about' section at the bottom of an article").wmf_stringByReplacingApostrophesWithBackslashApostrophes().uppercased(with: Locale.current)
        let menuLanguagesTitle = String.localizedStringWithFormat(WMFLocalizedString("page-read-in-other-languages", language: lang, value: "Available in %1$@ other languages", comment: "Label for button showing number of languages an article is available in. %1$@ will be replaced with the number of languages"), "\(article.languagecount)").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let lastModified = article.lastmodified ?? Date()
        let days = NSCalendar.wmf_gregorian().wmf_days(from: lastModified, to: Date())
        let menuLastEditedTitle = String.localizedStringWithFormat(WMFLocalizedString("page-last-edited",  language: lang, value: "Edited %1$@ days ago", comment: "Label for button showing number of days since an article was last edited. %1$@ will be replaced with the number of days"), "\(days)").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let menuLastEditedSubtitle = WMFLocalizedString("page-edit-history", language: lang, value: "Full edit history", comment: "Label for button used to show an article's complete edit history").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let menuTalkPageTitle = WMFLocalizedString("page-talk-page",  language: lang, value: "View talk page", comment: "Label for button linking out to an article's talk page").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let menuPageIssuesTitle = WMFLocalizedString("page-issues", language: lang, value: "Page issues", comment: "Label for the button that shows the \"Page issues\" dialog, where information about the imperfections of the current page is provided (by displaying the warning/cleanup templates).\n{{Identical|Page issue}}").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let menuDisambiguationTitle = WMFLocalizedString("page-similar-titles", language: lang, value: "Similar pages", comment: "Label for button that shows a list of similar titles (disambiguation) for the current page").wmf_stringByReplacingApostrophesWithBackslashApostrophes()
        let menuCoordinateTitle = WMFLocalizedString("page-location", language: lang, value: "View on a map", comment: "Label for button used to show an article on the map").wmf_stringByReplacingApostrophesWithBackslashApostrophes()

        let newJSLocalizedStrings = "new window.wmf.sectionTransformation.LocalizedStrings('\(infoboxTitle)', '\(tableTitle)', '\(closeBoxText)', '\(readMoreHeading)', '\(licenseString)', '\(licenseSubstitutionString)', '\(viewInBrowserString)', '\(menuHeading)', '\(menuLanguagesTitle)', '\(menuLastEditedTitle)', '\(menuLastEditedSubtitle)', '\(menuTalkPageTitle)', '\(menuPageIssuesTitle)', '\(menuDisambiguationTitle)', '\(menuCoordinateTitle)')"
        
        let isMain = article.isMain ? "true": "false"
        let articleTitle = nonNilTitle
        let articleEntityDescription = nonNilDescription
        let editable = article.editable ? "true": "false"
        let hasReadMore = article.hasReadMore ? "true": "false"
        let newJSArticle = "new window.wmf.sectionTransformation.Article(\(isMain), '\(articleTitle)', '\(articleEntityDescription)', \(editable), \(newJSLanguage), \(hasReadMore))"

        let menuItemsJS = [
            WMFArticleFooterMenuItem.languages,
            WMFArticleFooterMenuItem.coordinate,
            WMFArticleFooterMenuItem.lastEdited,
            WMFArticleFooterMenuItem.pageIssues,
            WMFArticleFooterMenuItem.disambiguation,
            WMFArticleFooterMenuItem.talkPage
            ].filter{$0.shouldAddItem(with: article)}
            .map{$0.menuItemTypeJSPath}
            .joined(separator: ", ")
        
        let menuItemsJSArray = "[\(menuItemsJS)]"
        
        evaluateJavaScript("window.wmf.sectionTransformation.transformAndAppendSectionsToDocument('\(proxyURLString)', '\(apiURLString)', \(newJSArticle), \(newJSLocalizedStrings), \(menuItemsJSArray))") { (result, error) in
            guard let error = error else {
                return
            }
            print(error)
        }
    }
}
