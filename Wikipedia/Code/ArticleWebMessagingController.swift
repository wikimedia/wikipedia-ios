
import Foundation

protocol ArticleWebMessageHandling: class {
    func didRecieve(action: ArticleWebMessagingController.Action)
}

class ArticleWebMessagingController: NSObject {
    
    private weak var webView: WKWebView?
    private weak var delegate: ArticleWebMessageHandling?
    
    private let bodyActionKey = "action"
    private let bodyDataKey = "data"

    init(delegate: ArticleWebMessageHandling?) {
        self.delegate = delegate
    }
    
    func setup(with webView: WKWebView, language: String, theme: Theme, layoutMargins: UIEdgeInsets, leadImageHeight: CGFloat = 0, areTablesInitiallyExpanded: Bool = false, textSizeAdjustment: Int? = nil, userGroups: [String] = []) {
        let margins = getPageContentServiceMargins(from: layoutMargins)
        let addTitleDescription = WMFLocalizedString("description-add-link-title", language: language, value: "Add title description", comment: "Text for link for adding a title description")
        let tableInfoboxTitle = WMFLocalizedString("info-box-title", language: language, value: "Quick Facts", comment: "The title of infoboxes – in collapsed and expanded form")
        let tableOtherTitle = WMFLocalizedString("table-title-other", language: language, value: "More information", comment: "The title of non-info box tables - in collapsed and expanded form {{Identical|More information}}")
        let tableFooterTitle = WMFLocalizedString("info-box-close-text", language: language, value: "Close", comment: "The text for telling users they can tap the bottom of the info box to close it {{Identical|Close}}")
        let l10n = PageContentService.Setup.Parameters.L10n(addTitleDescription: addTitleDescription, tableInfobox: tableInfoboxTitle, tableOther: tableOtherTitle, tableClose: tableFooterTitle)
        let textSizeAdjustment =  textSizeAdjustment ?? UserDefaults.standard.wmf_articleFontSizeMultiplier() as? Int ?? 100
        let parameters = PageContentService.Setup.Parameters(l10n: l10n, theme: theme.webName.lowercased(), dimImages: theme.imageOpacity < 1, margins: margins, leadImageHeight: "\(leadImageHeight)px", areTablesInitiallyExpanded: areTablesInitiallyExpanded, textSizeAdjustmentPercentage: "\(textSizeAdjustment)%", userGroups: userGroups)
        self.webView = webView
        let contentController = webView.configuration.userContentController
        contentController.add(self, name: PageContentService.messageHandlerName)
        do {
            let pcsSetup = try PageContentService.SetupScript(parameters)
            contentController.removeAllUserScripts()
            contentController.addUserScript(pcsSetup)
            let propertiesScript = PageContentService.PropertiesScript()
            contentController.addUserScript(propertiesScript)
            let utilitiesScript = PageContentService.UtilitiesScript()
            contentController.addUserScript(utilitiesScript)
            let styleScript = PageContentService.StyleScript()
            contentController.addUserScript(styleScript)
        } catch let error {
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: false)
        }
    }
    
    func addFooter(articleURL: URL, restAPIBaseURL: URL, menuItems: [PageContentService.Footer.Menu.Item], languageCount: Int, lastModified: Date?) {
        guard
            let language = articleURL.wmf_language,
            let title = articleURL.wmf_title
        else {
            return
        }
        
        let locale = Locale(identifier: language)
        let readMoreHeading = CommonStrings.readMoreTitle(with: language).uppercased(with: locale)
        let licenseString = String.localizedStringWithFormat(WMFLocalizedString("license-footer-text", language: language, value: "Content is available under %1$@ unless otherwise noted.", comment: "Marker at page end for who last modified the page when anonymous. %1$@ is a relative date such as '2 months ago' or 'today'."), "$1")
        let licenseSubstitutionString = WMFLocalizedString("license-footer-name", language: language, value: "CC BY-SA 3.0", comment: "License short name; usually leave untranslated as CC-BY-SA 3.0 {{Identical|CC BY-SA}}")
        let viewInBrowserString = WMFLocalizedString("view-in-browser-footer-link", language: language, value: "View article in browser", comment: "Link to view article in browser")
        let menuHeading = CommonStrings.aboutThisArticleTitle(with: language).uppercased(with: locale)
        let menuLanguagesTitle = String.localizedStringWithFormat(WMFLocalizedString("page-read-in-other-languages", language: language, value: "Available in {{PLURAL:%1$d|%1$d other language|%1$d other languages}}", comment: "Label for button showing number of languages an article is available in. %1$@ will be replaced with the number of languages"), languageCount)
        let menuLastEditedTitle: String
        if let lastModified = lastModified {
            let days = NSCalendar.wmf_gregorian().wmf_days(from: lastModified, to: Date())
            menuLastEditedTitle = String.localizedStringWithFormat(WMFLocalizedString("page-last-edited",  language: language, value: "{{PLURAL:%1$d|0=Edited today|1=Edited yesterday|Edited %1$d days ago}}", comment: "Relative days since an article was last edited. 0 = today, singular = yesterday. %1$d will be replaced with the number of days ago."), days)
        } else {
            menuLastEditedTitle = WMFLocalizedString("page-last-edited-unknown",  language: language, value: "Edited some time ago", comment: "Shown on the item for showing the article history when it's unclear how many days ago the article was edited.")
        }
        let menuLastEditedSubtitle = WMFLocalizedString("page-edit-history", language: language, value: "Full edit history", comment: "Label for button used to show an article's complete edit history")
        let menuTalkPageTitle = WMFLocalizedString("page-talk-page",  language: language, value: "View talk page", comment: "Label for button linking out to an article's talk page")
        let menuPageIssuesTitle = WMFLocalizedString("page-issues", language: language, value: "Page issues", comment: "Label for the button that shows the \"Page issues\" dialog, where information about the imperfections of the current page is provided (by displaying the warning/cleanup templates). {{Identical|Page issue}}")
        let menuDisambiguationTitle = WMFLocalizedString("page-similar-titles", language: language, value: "Similar pages", comment: "Label for button that shows a list of similar titles (disambiguation) for the current page")
        let menuCoordinateTitle = WMFLocalizedString("page-location", language: language, value: "View on a map", comment: "Label for button used to show an article on the map")
        let l10n = PageContentService.Footer.L10n(readMoreHeading: readMoreHeading, menuDisambiguationTitle: menuDisambiguationTitle, menuLanguagesTitle: menuLanguagesTitle, menuHeading: menuHeading, menuLastEditedSubtitle: menuLastEditedSubtitle, menuLastEditedTitle: menuLastEditedTitle, licenseString: licenseString, menuTalkPageTitle: menuTalkPageTitle, menuPageIssuesTitle: menuPageIssuesTitle, viewInBrowserString: viewInBrowserString, licenseSubstitutionString: licenseSubstitutionString, menuCoordinateTitle: menuCoordinateTitle)
        let menu = PageContentService.Footer.Menu(items: menuItems)
        let readMore = PageContentService.Footer.ReadMore(itemCount: 3, baseURL: restAPIBaseURL.absoluteString)
        let parameters = PageContentService.Footer.Parameters(title: title, menu: menu, readMore: readMore, l10n: l10n)
        guard let parametersJS = try? PageContentService.getJavascriptFor(parameters) else {
            return
        }
        webView?.evaluateJavaScript("pcs.c1.Footer.add(\(parametersJS))", completionHandler: { (result, error) in
            
        })
    }
    
    // MARK: - Adjustable state
    
    // MARK: PCS
    
    func updateTheme(_ theme: Theme) {
        let js = "pcs.c1.Page.setTheme(pcs.c1.Themes.\(theme.webName.uppercased()))"
        webView?.evaluateJavaScript(js)
    }

    func getPageContentServiceMargins(from insets: UIEdgeInsets, leadImageHeight: CGFloat = 0) -> PageContentService.Setup.Parameters.Margins {
        return PageContentService.Setup.Parameters.Margins(top: "\(insets.top + leadImageHeight)px", right: "\(insets.right)px", bottom: "\(insets.bottom)px", left: "\(insets.left)px")
    }
    
    func updateMargins(with layoutMargins: UIEdgeInsets, leadImageHeight: CGFloat) {
        let margins = getPageContentServiceMargins(from: layoutMargins, leadImageHeight: leadImageHeight)
        guard let marginsJSON = try? PageContentService.getJavascriptFor(margins) else {
            return
        }
        webView?.evaluateJavaScript("pcs.c1.Page.setMargins(\(marginsJSON))")
    }
    
    func updateTextSizeAdjustmentPercentage(_ percentage: Int) {
        let js = "pcs.c1.Page.setTextSizeAdjustmentPercentage('\(percentage)%')"
        webView?.evaluateJavaScript(js)
    }
    
    func prepareForScroll(to anchor: String, highlight: Bool, completion: @escaping (Result<CGRect, Error>) -> Void) {
        guard let webView = webView else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        webView.evaluateJavaScript("pcs.c1.Page.prepareForScrollToAnchor(`\(anchor.sanitizedForJavaScriptTemplateLiterals)`, \(highlight ? "true" : "false"))") { (result, error) in
            guard
                let dictionary = result as? [String: Any],
                let x = dictionary["x"] as? CGFloat,
                let y = dictionary["y"] as? CGFloat,
                let width = dictionary["width"] as? CGFloat,
                let height = dictionary["height"] as? CGFloat,
                width > 0,
                height > 0
                else {
                    completion(.failure(RequestError.invalidParameters))
                    return
            }
            let scrollRect = CGRect(x: x + webView.scrollView.contentOffset.x + x, y: webView.scrollView.contentOffset.y + y, width: width, height: height)
            completion(.success(scrollRect))
        }
    }
    
    func removeElementHighlights() {
        webView?.evaluateJavaScript("pcs.c1.Page.removeHighlightsFromHighlightedElements()")
    }
    
    // MARK: iOS App Specific overrides (code in www/, built products in assets/)
    
    func removeSearchTermHighlights() {
        let js = "window.wmf.findInPage.removeSearchTermHighlights()"
        webView?.evaluateJavaScript(js)
    }
}

struct ReferenceBackLink {
    let id: String
    init?(scriptMessageDict: [String: Any]) {
        guard
            let id = scriptMessageDict["id"] as? String
        else {
            return nil
        }
        self.id = id
    }
}

extension ArticleWebMessagingController: WKScriptMessageHandler {
    /// Actions represent events from the web page
    enum Action {
        case setup
        case finalSetup
        case image(src: String, href: String, width: Int?, height: Int?)
        case link(href: String, text: String?, title: String?)
        case reference(selectedIndex: Int, group: [WMFLegacyReference])
        case backLink(referenceId: String, referenceText: String, backLinks: [ReferenceBackLink])
        case pronunciation(url: URL)
        case properties
        case edit(sectionID: Int, descriptionSource: ArticleDescriptionSource?)
        case addTitleDescription
        case footerItem(type: PageContentService.Footer.Menu.Item, payload: Any?)
        case readMoreTitlesRetrieved
        case viewLicense
        case viewInBrowser
        case leadImage(source: String?, width: Int?, height: Int?)
        case tableOfContents(items: [TableOfContentsItem])
        case unknown(href: String)
    }
    
    /// PCSActions are receieved from the JS bridge and converted into actions
    // Handle both _clicked and non-clicked variants in case the names change
    private enum PCSAction: String {
        case setup
        case finalSetup = "final_setup"
        case image
        case link
        case reference
        case backLink = "back_link"
        case pronunciation
        case edit = "edit_section"
        case addTitleDescription = "add_title_description"
        case footerItem = "footer_item"
        case readMoreTitlesRetrieved = "read_more_titles_retrieved"
        case viewLicense = "view_license"
        case viewInBrowser = "view_in_browser"
        case leadImage
        case tableOfContents
        init?(pcsActionString: String) {
            let cleaned = pcsActionString.replacingOccurrences(of: "_clicked", with: "")
            self.init(rawValue: cleaned)
        }
        func getAction(with data: [String: Any]?) -> Action? {
            switch self {
            case .setup:
                return .setup
            case .finalSetup:
                return .finalSetup
            case .image:
                return getImageAction(with: data)
            case .reference:
                return getReferenceAction(with: data)
            case .backLink:
                return getBackLinkAction(with: data)
            case .pronunciation:
                return getPronunciationAction(with: data)
            case .edit:
                return getEditAction(with: data)
            case .addTitleDescription:
                return .addTitleDescription
            case .footerItem:
                return getFooterItemAction(with: data)
            case .readMoreTitlesRetrieved:
                return .readMoreTitlesRetrieved
            case .viewLicense:
                return .viewLicense
            case .viewInBrowser:
                return .viewInBrowser
            case .link:
                return getLinkAction(with: data)
            case .leadImage:
                return getLeadImageAction(with: data)
            case .tableOfContents:
                return getTableOfContentsAction(with: data)
            }
        }
        func getLeadImageAction(with data: [String: Any]?) -> Action? {
            // Send back a lead image event even if it's empty - we need to handle this case
            let leadImage = data?["leadImage"] as? [String: Any]
            let source = leadImage?["source"] as? String
            let width = leadImage?["width"] as? Int
            let height = leadImage?["height"] as? Int
            return Action.leadImage(source: source, width: width, height: height)
        }
        
        func getTableOfContentsAction(with data: [String: Any]?) -> Action? {
            guard let tableOfContents = data?["tableOfContents"] as? [[String: Any]] else {
                return nil
            }
            var currentRootSectionId = -1
            let items = tableOfContents.compactMap { (tocJSON) -> TableOfContentsItem? in
                guard
                    let id = tocJSON["id"] as? Int,
                    let level = tocJSON["level"] as? Int,
                    let anchor = tocJSON["anchor"] as? String,
                    let title = tocJSON["title"] as? String
                else {
                        return nil
                }
                let indentationLevel = level - 1
                if indentationLevel == 0 {
                    currentRootSectionId = id
                }
                return TableOfContentsItem(id: id, titleHTML: title, anchor: anchor, rootItemId: currentRootSectionId, indentationLevel: indentationLevel)
            }
            return Action.tableOfContents(items: items)
        }
        
        func getLinkAction(with data: [String: Any]?) -> Action? {
            guard let href = data?["href"] as? String else {
                return nil
            }
            let title = data?["title"] as? String
            let text = data?["text"] as? String
            return .link(href: href, text: text, title: title)
        }
        
        func getEditAction(with data: [String: Any]?) -> Action? {
            guard let sectionIDString = data?["sectionId"] as? String, let sectionID = Int(sectionIDString) else {
                return nil
            }
            let source: ArticleDescriptionSource?
            if let sourceString = data?["descriptionSource"] as? String {
                source = ArticleDescriptionSource.from(string: sourceString)
            } else {
                source = nil
            }
            return .edit(sectionID: sectionID, descriptionSource: source)
        }
        
        func getImageAction(with data: [String: Any]?) -> Action? {
            guard let src = data?["src"] as? String, let href = data?["href"] as? String else {
                return nil
            }
            let width = data?["data-file-width"] as? Int
            let height = data?["data-file-height"] as? Int
            return .image(src: src, href: href, width: width, height: height)
        }
        
        func getReferenceAction(with data: [String: Any]?) -> Action? {
            guard let selectedIndex = data?["selectedIndex"] as? Int, let groupArray = data?["referencesGroup"] as? [[String: Any]]  else {
                return nil
            }
            let group = groupArray.compactMap { WMFLegacyReference(scriptMessageDict: $0) }
            return .reference(selectedIndex: selectedIndex, group: group)
        }
        
        func getBackLinkAction(with data: [String: Any]?) -> Action? {
            guard
                let referenceId = data?["referenceId"] as? String,
                let referenceText = data?["referenceText"] as? String,
                let backLinkDictionaries = data?["backLinks"] as? [[String: Any]]
            else {
                return nil
            }
            let backLinks = backLinkDictionaries.compactMap { ReferenceBackLink(scriptMessageDict: $0) }
            return .backLink(referenceId: referenceId, referenceText: referenceText, backLinks: backLinks)
        }
        
        func getPronunciationAction(with data: [String: Any]?) -> Action? {
            guard var urlString = data?["url"] as? String else {
                return nil
            }
            if urlString.hasPrefix("//") {
                urlString = "https:" + urlString
            }
            guard let url = NSURL(string: urlString)?.wmf_URLByMakingiOSCompatibilityAdjustments else {
                return nil
            }
            return .pronunciation(url: url)
        }
        
        func getFooterItemAction(with data: [String: Any]?) -> Action? {
            guard let itemTypeString = data?["itemType"] as? String, let menuItemType = PageContentService.Footer.Menu.Item(rawValue: itemTypeString) else {
                return nil
            }
            return .footerItem(type: menuItemType, payload: data?["payload"])
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            return
        }
        guard let actionString = body[bodyActionKey] as? String else {
            return
        }
        let data = body[bodyDataKey] as? [String: Any]
        guard let action = PCSAction(pcsActionString: actionString)?.getAction(with: data) else {
            // Fallback on href for future unknown event types
            if let href = data?["href"] as? String {
                let action = ArticleWebMessagingController.Action.unknown(href: href)
                delegate?.didRecieve(action: action)
            }
            return
        }
        delegate?.didRecieve(action: action)
    }
}
