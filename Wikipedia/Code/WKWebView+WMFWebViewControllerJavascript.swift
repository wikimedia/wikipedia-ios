
import WebKit
import WMF

fileprivate extension Bool{
    func toString() -> String {
        return self ? "true" : "false"
    }
}

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

fileprivate protocol JSONEncodable: Encodable {
}

fileprivate extension JSONEncodable {
    func toJSON() -> String {
        guard
            let jsonData = try? JSONEncoder().encode(self),
            let jsonString = String(data: jsonData, encoding: .utf8)
            else {
                assertionFailure("Expected JSON string")
                return "{}"
        }
        return jsonString
    }
}

fileprivate struct FooterLocalizedStrings: JSONEncodable {
    var readMoreHeading: String = ""
    var licenseString: String = ""
    var licenseSubstitutionString: String = ""
    var viewInBrowserString: String = ""
    var menuHeading: String = ""
    var menuLanguagesTitle: String = ""
    var menuLastEditedTitle: String = ""
    var menuLastEditedSubtitle: String = ""
    var menuTalkPageTitle: String = ""
    var menuPageIssuesTitle: String = ""
    var menuDisambiguationTitle: String = ""
    var menuCoordinateTitle: String = ""
    init(for article: MWKArticle) {
        let lang = (article.url as NSURL).wmf_language
        readMoreHeading = WMFLocalizedString("article-read-more-title", language: lang, value: "Read more", comment: "The text that is displayed before the read more section at the bottom of an article\n{{Identical|Read more}}").uppercased(with: Locale.current)
        licenseString = String.localizedStringWithFormat(WMFLocalizedString("license-footer-text", language: lang, value: "Content is available under %1$@ unless otherwise noted.", comment: "Marker at page end for who last modified the page when anonymous. %1$@ is a relative date such as '2 months ago' or 'today'."), "$1")
        licenseSubstitutionString = WMFLocalizedString("license-footer-name", language: lang, value: "CC BY-SA 3.0", comment: "License short name; usually leave untranslated as CC-BY-SA 3.0\n{{Identical|CC BY-SA}}")
        viewInBrowserString = WMFLocalizedString("view-in-browser-footer-link", language: lang, value: "View article in browser", comment: "Link to view article in browser")
        menuHeading = WMFLocalizedString("article-about-title", language: lang, value: "About this article", comment: "The text that is displayed before the 'about' section at the bottom of an article").uppercased(with: Locale.current)
        menuLanguagesTitle = String.localizedStringWithFormat(WMFLocalizedString("page-read-in-other-languages", language: lang, value: "Available in %1$@ other languages", comment: "Label for button showing number of languages an article is available in. %1$@ will be replaced with the number of languages"), "\(article.languagecount)")
        let lastModified = article.lastmodified ?? Date()
        let days = NSCalendar.wmf_gregorian().wmf_days(from: lastModified, to: Date())
        menuLastEditedTitle = String.localizedStringWithFormat(WMFLocalizedString("page-last-edited",  language: lang, value: "Edited %1$@ days ago", comment: "Label for button showing number of days since an article was last edited. %1$@ will be replaced with the number of days"), "\(days)")
        menuLastEditedSubtitle = WMFLocalizedString("page-edit-history", language: lang, value: "Full edit history", comment: "Label for button used to show an article's complete edit history")
        menuTalkPageTitle = WMFLocalizedString("page-talk-page",  language: lang, value: "View talk page", comment: "Label for button linking out to an article's talk page")
        menuPageIssuesTitle = WMFLocalizedString("page-issues", language: lang, value: "Page issues", comment: "Label for the button that shows the \"Page issues\" dialog, where information about the imperfections of the current page is provided (by displaying the warning/cleanup templates).\n{{Identical|Page issue}}")
        menuDisambiguationTitle = WMFLocalizedString("page-similar-titles", language: lang, value: "Similar pages", comment: "Label for button that shows a list of similar titles (disambiguation) for the current page")
        menuCoordinateTitle = WMFLocalizedString("page-location", language: lang, value: "View on a map", comment: "Label for button used to show an article on the map")
    }
}

fileprivate struct CollapseTablesLocalizedStrings: JSONEncodable {
    var tableInfoboxTitle: String = ""
    var tableOtherTitle: String = ""
    var tableFooterTitle: String = ""
    init(for lang: String?) {
        tableInfoboxTitle = WMFLocalizedString("info-box-title", language: lang, value: "Quick Facts", comment: "The title of infoboxes – in collapsed and expanded form")
        tableOtherTitle = WMFLocalizedString("table-title-other", language: lang, value: "More information", comment: "The title of non-info box tables - in collapsed and expanded form\n{{Identical|More information}}")
        tableFooterTitle = WMFLocalizedString("info-box-close-text", language: lang, value: "Close", comment: "The text for telling users they can tap the bottom of the info box to close it\n{{Identical|Close}}")
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
        case Theme.blackDimmed.name:
            isDim = true
            fallthrough
        case Theme.black.name:
            jsThemeConstant = "BLACK"
        case Theme.darkDimmed.name:
            isDim = true
            fallthrough
        case Theme.dark.name:
            jsThemeConstant = "DARK"
        default:
            break
        }
        return """
        window.wmf.themes.setTheme(document, window.wmf.themes.THEME.\(jsThemeConstant))
        window.wmf.imageDimming.dim(window, \(isDim.toString()))
        """
    }
    
    @objc public func wmf_applyTheme(_ theme: Theme){
        let themeJS = WKWebView.wmf_themeApplicationJavascript(with: theme)
        evaluateJavaScript(themeJS, completionHandler: nil)
    }
    
    private func languageJS(for article: MWKArticle) -> String {
        let lang = (article.url as NSURL).wmf_language ?? MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode ?? "en"
        let langInfo = MWLanguageInfo(forCode: lang)
        let langCode = langInfo.code
        let langDir = langInfo.dir
        
        return """
        new window.wmf.sections.Language(
            '\(langCode.wmf_stringBySanitizingForJavaScript())',
            '\(langDir.wmf_stringBySanitizingForJavaScript())',
            \((langDir == "rtl").toString())
        )
        """
    }

    private func articleJS(for article: MWKArticle, title: String) -> String {
        let articleDisplayTitle = article.displaytitle ?? ""
        let articleEntityDescription = (article.entityDescription ?? "").wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: article.url.wmf_language)
        let addTitleDescriptionLocalizedString = WMFLocalizedString("description-add-link-title", language: (article.url as NSURL).wmf_language, value: "Add title description", comment: "Text for link for adding a title description")

        return """
        new window.wmf.sections.Article(
            \(article.isMain.toString()),
            '\(title.wmf_stringBySanitizingForJavaScript())',
            '\(articleDisplayTitle.wmf_stringBySanitizingForJavaScript())',
            '\(articleEntityDescription.wmf_stringBySanitizingForJavaScript())',
            \(article.editable.toString()),
            \(languageJS(for: article)),
            '\(addTitleDescriptionLocalizedString.wmf_stringBySanitizingForJavaScript())',
            \(article.isWikidataDescriptionEditable.toString())
        )
        """
    }

    private func menuItemsJS(for article: MWKArticle) -> String {
        let menuItemTypeJSPaths = [
            WMFArticleFooterMenuItem.languages,
            WMFArticleFooterMenuItem.coordinate,
            WMFArticleFooterMenuItem.lastEdited,
            WMFArticleFooterMenuItem.pageIssues,
            WMFArticleFooterMenuItem.disambiguation,
            WMFArticleFooterMenuItem.talkPage
            ]
            .filter{$0.shouldAddItem(with: article)}
            .map{$0.menuItemTypeJSPath}
        
        return "[\(menuItemTypeJSPaths.joined(separator: ", "))]"
    }
    
    @objc public func wmf_fetchTransformAndAppendSectionsToDocument(_ article: MWKArticle, collapseTables: Bool, scrolledTo fragment: String?){
        guard
            let url = article.url,
            let host = url.host,
            let proxyURL = WMFProxyServer.shared().proxyURL(forWikipediaAPIHost: host),
            let apiURL = WMFProxyServer.shared().articleSectionDataURLForArticle(with: url, targetImageWidth: self.traitCollection.wmf_articleImageWidth)
            else {
                assertionFailure("Expected url, proxyURL and encodedTitle")
                return
        }

        // https://github.com/wikimedia/wikipedia-ios/pull/1334/commits/f2b2228e2c0fd852479464ec84e38183d1cf2922
        let proxyURLString = proxyURL.absoluteString
        let apiURLString = apiURL.absoluteString
        let title = (article.url as NSURL).wmf_title ?? ""

        let addFooterCallbackJS = """
        () => {
            const footer = new window.wmf.footers.Footer(
                '\(title.wmf_stringBySanitizingForJavaScript())',
                \(menuItemsJS(for: article)),
                \(article.hasReadMore.toString()),
                3,
                \(FooterLocalizedStrings.init(for: article).toJSON()),
                '\(proxyURLString.wmf_stringBySanitizingForJavaScript())'
            )
            footer.add()
        }
        """
        
        let sectionErrorMessageLocalizedString = WMFLocalizedString("article-unable-to-load-section", language: (article.url as NSURL).wmf_language, value: "Unable to load this section. Try refreshing the article to see if it fixes the problem.", comment: "Displayed within the article content when a section fails to render for some reason.")
        
        evaluateJavaScript("""
            window.wmf.sections.sectionErrorMessageLocalizedString = '\(sectionErrorMessageLocalizedString.wmf_stringBySanitizingForJavaScript())'
            window.wmf.sections.collapseTablesLocalizedStrings = \(CollapseTablesLocalizedStrings.init(for: (article.url as NSURL).wmf_language).toJSON())
            window.wmf.sections.collapseTablesInitially = \(collapseTables ? "true" : "false")
            window.wmf.sections.fetchTransformAndAppendSectionsToDocument(
                \(articleJS(for: article, title: title)),
                '\(apiURLString.wmf_stringBySanitizingForJavaScript())',
                '\((fragment ?? "").wmf_stringBySanitizingForJavaScript())',
                \(addFooterCallbackJS)
            )
            """) { (result, error) in
            guard let error = error else {
                return
            }
            DDLogError("Error when evaluating javascript on fetch and transform: \(error)")
        }
    }
}
