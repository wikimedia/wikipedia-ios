
import Foundation
import CocoaLumberjackSwift

protocol ArticleWebMessageHandling: class {
    func didRecieve(action: ArticleWebMessagingController.Action)
}

class ArticleWebMessagingController: NSObject {
    
    fileprivate weak var webView: WKWebView?
    weak var delegate: ArticleWebMessageHandling?
    
    private let bodyActionKey = "action"
    private let bodyDataKey = "data"
    
    var parameters: PageContentService.Setup.Parameters?
    var contentController: WKUserContentController?
    var shouldAttemptToShowArticleAsLivingDoc = false
    
    func setup(with webView: WKWebView, language: String, theme: Theme, layoutMargins: UIEdgeInsets, leadImageHeight: CGFloat = 0, areTablesInitiallyExpanded: Bool = false, textSizeAdjustment: Int? = nil, userGroups: [String] = []) {
        let margins = getPageContentServiceMargins(from: layoutMargins)
        let textSizeAdjustment =  textSizeAdjustment ?? UserDefaults.standard.wmf_articleFontSizeMultiplier() as? Int ?? 100
        let parameters = PageContentService.Setup.Parameters(theme: theme.webName.lowercased(), dimImages: theme.imageOpacity < 1, margins: margins, leadImageHeight: "\(leadImageHeight)px", areTablesInitiallyExpanded: areTablesInitiallyExpanded, textSizeAdjustmentPercentage: "\(textSizeAdjustment)%", userGroups: userGroups)
        self.parameters = parameters
        self.webView = webView
        let contentController = webView.configuration.userContentController
        contentController.add(self, name: PageContentService.messageHandlerName)
        self.contentController = contentController
        do {
            try updateUserScripts(on: contentController, with: parameters)
        } catch let error {
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: false)
        }
    }
    
    func removeScriptMessageHandler() {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: PageContentService.messageHandlerName)
    }
    
    /// Update the scripts that run on page load. Utilize this when any parameters change.
    func updateUserScripts(on contentController: WKUserContentController, with parameters: PageContentService.Setup.Parameters) throws {
        let pcsSetup = try PageContentService.SetupScript(parameters)
        // Unfortunately we can only remove all and re-add all
        // it doesn't appear there's any way to just replace the script we need to update
        contentController.removeAllUserScripts()
        contentController.addUserScript(pcsSetup)
        let propertiesScript = PageContentService.PropertiesScript()
        contentController.addUserScript(propertiesScript)
        let utilitiesScript = PageContentService.UtilitiesScript()
        contentController.addUserScript(utilitiesScript)
        
        if shouldAttemptToShowArticleAsLivingDoc {
            let significantEventsStyleScript = PageContentService.SignificantEventsStyleScript(theme: parameters.theme)
            contentController.addUserScript(significantEventsStyleScript)
        } else {
            let styleScript = PageContentService.StyleScript()
            contentController.addUserScript(styleScript)
        }
    }
    
    func addFooter(articleURL: URL, restAPIBaseURL: URL, menuItems: [PageContentService.Footer.Menu.Item], lastModified: Date?) {
        guard let title = articleURL.percentEncodedPageTitleForPathComponents else {
            return
        }
        var editedDaysAgo: Int?
        if let lastModified = lastModified {
            editedDaysAgo = NSCalendar.wmf_gregorian().wmf_days(from: lastModified, to: Date())
        }
        let menu = PageContentService.Footer.Menu(items: menuItems, editedDaysAgo: editedDaysAgo)
        let readMore = PageContentService.Footer.ReadMore(itemCount: 3, baseURL: restAPIBaseURL.absoluteString)
        let parameters = PageContentService.Footer.Parameters(title: title, menu: menu, readMore: readMore)
        guard let parametersJS = try? PageContentService.getJavascriptFor(parameters) else {
            return
        }
        webView?.evaluateJavaScript("pcs.c1.Footer.add(\(parametersJS))", completionHandler: { (result, error) in
            if let error = error {
                DDLogError("Error adding footer: \(error)")
            }
        })
    }
    
    // MARK: - Adjustable state
    
    // MARK: PCS
    
    /// Update the pageSetupSettings so that they are correct on reload
    /// Without updating these after changing settings like theme, text size, etc, the page will revert to the original settings on reload
    func updateSetupParameters() {
        guard let parameters = parameters, let contentController = contentController else {
            return
        }
        try? updateUserScripts(on: contentController, with: parameters)
    }
    
    func updateTheme(_ theme: Theme) {
        let webTheme = theme.webName.lowercased()
        let js = "pcs.c1.Page.setTheme(pcs.c1.Themes.\(theme.webName.uppercased()))"
        webView?.evaluateJavaScript(js)
        parameters?.theme = webTheme
        updateSetupParameters()
        
        if shouldAttemptToShowArticleAsLivingDoc {
            let significantEventsJS = PageContentService.SignificantEventsStyleScript.sourceForTheme(webTheme)
            webView?.evaluateJavaScript(significantEventsJS)
        }
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
        parameters?.margins = margins
        updateSetupParameters()
    }
    
    func updateTextSizeAdjustmentPercentage(_ percentage: Int) {
        let percentage = "\(percentage)%"
        let js = "pcs.c1.Page.setTextSizeAdjustmentPercentage('\(percentage)')"
        webView?.evaluateJavaScript(js)
        parameters?.textSizeAdjustmentPercentage = percentage
        updateSetupParameters()
    }
    
    func prepareForScroll(to anchor: String, highlight: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let webView = webView else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        webView.evaluateJavaScript("pcs.c1.Page.prepareForScrollToAnchor(`\(anchor.sanitizedForJavaScriptTemplateLiterals)`, {highlight: \(highlight ? "true" : "false")})") { (result, error) in
            if let error = error {
                DDLogError("Error attempting to scroll to anchor: \(anchor) \(error)")
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
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
        case edit(sectionID: Int, descriptionSource: ArticleDescriptionSource?)
        case addTitleDescription
        case footerItem(type: PageContentService.Footer.Menu.Item, payload: Any?)
        case viewInBrowser
        case leadImage(source: String?, width: Int?, height: Int?)
        case tableOfContents(items: [TableOfContentsItem])
        case scrollToAnchor(anchor: String, rect: CGRect)
        case aaaldInsertOnScreen
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
        case viewInBrowser = "view_in_browser"
        case leadImage
        case tableOfContents
        case scrollToAnchor = "scroll_to_anchor"
        case aaaldInsertOnScreen
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
            case .viewInBrowser:
                return .viewInBrowser
            case .link:
                return getLinkAction(with: data)
            case .leadImage:
                return getLeadImageAction(with: data)
            case .tableOfContents:
                return getTableOfContentsAction(with: data)
            case .scrollToAnchor:
                return getScrollToAnchorAction(with: data)
            case .aaaldInsertOnScreen:
                return .aaaldInsertOnScreen
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
            guard let urlString = data?["url"] as? String else {
                return nil
            }
            return .link(href: urlString, text: nil, title: nil)
        }
        
        func getFooterItemAction(with data: [String: Any]?) -> Action? {
            guard let itemTypeString = data?["itemType"] as? String, let menuItemType = PageContentService.Footer.Menu.Item(rawValue: itemTypeString) else {
                return nil
            }
            return .footerItem(type: menuItemType, payload: data?["payload"])
        }
        
        func getScrollToAnchorAction(with data: [String: Any]?) -> Action? {
            guard
                let dictionary = data?["rect"] as? [String: Any],
                let anchor = data?["anchor"] as? String,
                let x = dictionary["x"] as? CGFloat,
                let y = dictionary["y"] as? CGFloat,
                let width = dictionary["width"] as? CGFloat,
                let height = dictionary["height"] as? CGFloat,
                width > 0,
                height > 0
            else {
                return nil
            }
            let rect = CGRect(x: x, y: y, width: width, height: height)
            return .scrollToAnchor(anchor: anchor, rect: rect)
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

//Article as a Living Document Scripts

extension ArticleWebMessagingController {
    
    enum TopBadgeType {
        case lastUpdated
        case newChanges
    }
    
    var articleAsLivingDocBoxSkeletonContainerID: String {
        return "significant-changes-skeleton"
    }
    var badgeHTMLSkeletonContainerID: String {
        return "significant-changes-top-skeleton"
    }
    var articleAsLivingDocBoxContainerID: String {
        return "significant-changes-container"
    }
    var badgeHTMLContainerID: String {
        return "significant-changes-top-container"
    }
    var articleAsLivingDocBoxContainerHTMLStart: String {
        return "<div id='\(articleAsLivingDocBoxContainerID)'>"
    }
    var articleAsLivingDocBoxInnerContainerID: String {
        return "significant-changes-inner-container"
    }
    var articleAsLivingDocBoxInnerContainerHTMLStart: String {
        return "<div id='\(articleAsLivingDocBoxInnerContainerID)'>"
    }
    var articleAsLivingDocBoxInnerContainerHTMLEnd: String {
        return "</div>"
    }
    var articleAsLivingDocBoxContainerHTMLEnd: String {
        return "</div>"
    }
    var badgeHTMLContainerStart: String {
        return "<div id='\(badgeHTMLContainerID)'>"
    }
    var badgeHTMLContainerEnd: String {
        return "</div>"
    }
    func createAndInsertArticleContainerScript(innerHTML: String) -> String {
        return """
             //then create and insert new element
             var pcs = document.getElementById('pcs');
             if (!pcs) {
                return false;
             }
             var sections = pcs.getElementsByTagName('section');
             if (sections.length === 0) {
                 return false;
             }
             var firstSection = sections[0];
             var pTags = firstSection.getElementsByTagName('p');
             if (pTags.length === 0) {
                 return false;
             }
             var firstParagraph = pTags[0];
             firstParagraph.insertAdjacentHTML("afterend","\(articleAsLivingDocBoxContainerHTMLStart + innerHTML + articleAsLivingDocBoxContainerHTMLEnd)");
             return true;
        """
    }
    
    func createAndInsertBadgeScript(innerHTML: String) -> String {
        return """
                    //then create and insert new element
                    var pcs = document.getElementById('pcs');
                    if (!pcs) {
                        return false;
                    }
                    var headers = pcs.getElementsByTagName('header');
                    if (headers.length === 0) {
                        return false;
                    }
                    var firstHeader = headers[0];
                    firstHeader.insertAdjacentHTML("afterbegin","\(badgeHTMLContainerStart + innerHTML + badgeHTMLContainerEnd)");
                    return true;
        """
    }
    
    func removeArticleAsLivingDocContent(completion: ((Bool) -> Void)? = nil) {
        let javascript = """
            function removeSignificantEventsContent() {
                var boxSkeleton = document.getElementById('\(articleAsLivingDocBoxContainerID)');
                var missingSkeletons = false;
                if (boxSkeleton) {
                    boxSkeleton.remove();
                } else {
                    missingSkeletons = true;
                }

                var topSkeleton = document.getElementById('\(badgeHTMLContainerID)');
                if (topSkeleton) {
                    topSkeleton.remove();
                } else {
                    missingSkeletons = true;
                }
                
                if (missingSkeletons == true) {
                    return false;
                } else {
                    return true;
                }
            }

            removeSignificantEventsContent();
        """
        
        webView?.evaluateJavaScript(javascript) { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    DDLogDebug("Failure in removeSkeletonArticleAsLivingDocContent: \(error)")
                    completion?(false)
                    return
                }
                
                if let boolResult = result as? Bool {
                    if !boolResult {
                        DDLogDebug("Failure in removeSkeletonArticleAsLivingDocContent")
                    }
                    completion?(boolResult)
                    return
                }
                
                DDLogDebug("Failure in removeSkeletonArticleAsLivingDocContent")
                completion?(false)
            }
        }
    }
    
    func injectSkeletonArticleAsLivingDocContent(completion: ((Bool) -> Void)? = nil) {
        
        let innerBoxHTML = "<div id='\(articleAsLivingDocBoxSkeletonContainerID)'></div>"
        let innerBadgeHTML = "<div id='\(badgeHTMLSkeletonContainerID)'></div>"
        
        let javascript = """
            function injectSignificantEventsContent() {
                \(createAndInsertArticleContainerScript(innerHTML: innerBoxHTML))
            }
            injectSignificantEventsContent();

            function injectNewChangesBadge() {
                \(createAndInsertBadgeScript(innerHTML: innerBadgeHTML))
            }
            injectNewChangesBadge();
        """
        
        webView?.evaluateJavaScript(javascript) { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    DDLogDebug("Failure in injectSkeletonArticleAsLivingDocContent: \(error)")
                    completion?(false)
                    return
                }
                
                if let boolResult = result as? Bool {
                    if !boolResult {
                        DDLogDebug("Failure in injectSkeletonArticleAsLivingDocContent")
                    }
                    completion?(boolResult)
                    return
                }
                
                DDLogDebug("Failure in injectSkeletonArticleAsLivingDocContent")
                completion?(false)
            }
        }
    }
    
    func aaaldContentInsertJS(articleInsertHtmlSnippets: [String]) -> String {
        let insertHeaderText = WMFLocalizedString("aaald-article-insert-header", value: "Significant Updates", comment: "Header text in article content insert section that displays recent significant article updates.")

        var articleAsLivingDocBoxInnerHTML = "\(articleAsLivingDocBoxInnerContainerHTMLStart)<h4 id='significant-changes-header'>\(insertHeaderText.uppercased(with: Locale.current))</h4><ul id='significant-changes-list'>"
        
        for articleInsertHtmlSnippet in articleInsertHtmlSnippets {
            articleAsLivingDocBoxInnerHTML += articleInsertHtmlSnippet
        }
        
        let readMoreUpdatesText = WMFLocalizedString("aaald-article-insert-read-more", value: "Read more updates", comment: "Footer text in article content insert section of recent significant article updates that invites user to read more updates on another screen.")
        
        articleAsLivingDocBoxInnerHTML += "</ul><hr id='significant-changes-hr'><p id='significant-changes-read-more'><a href='#significant-events-read-more'>\(readMoreUpdatesText)</a></p>\(articleAsLivingDocBoxInnerContainerHTMLEnd)"
        
        let js = """
            function injectSignificantEventsContent() {
                 //first remove existing element if it's there
                 var existing = document.getElementById('\(articleAsLivingDocBoxContainerID)');
                 if (existing) {
                     existing.innerHTML = "\(articleAsLivingDocBoxInnerHTML)";
                     return true;
                 }
                 \(createAndInsertArticleContainerScript(innerHTML: articleAsLivingDocBoxInnerHTML))
            }
            injectSignificantEventsContent();
        """
        
        return js
    }
    
    func aaaldScrollViewDetectionJS() -> String {
        return """

            function isInViewport(el) {
                const rect = el.getBoundingClientRect();
                return (
                    (rect.top >= 0 && rect.top <= (window.innerHeight || document.documentElement.clientHeight)) ||
                    (rect.bottom >= 0 && rect.bottom <= (window.innerHeight || document.documentElement.clientHeight))
                );
            }

            var aaaldInsertElementForScrollDetection = document.getElementById('\(articleAsLivingDocBoxInnerContainerID)');
            var detectedIsOnScreen = false;

            function detectIfInsertIsOnScreen() {
                if (!aaaldInsertElementForScrollDetection) {
                    aaaldInsertElementForScrollDetection = document.getElementById('\(articleAsLivingDocBoxInnerContainerID)');
                }
                if (aaaldInsertElementForScrollDetection) {
                    const isOnScreen = isInViewport(aaaldInsertElementForScrollDetection);
                    if (detectedIsOnScreen === false && isOnScreen === true) {
                        window.webkit.messageHandlers.\(PageContentService.messageHandlerName).postMessage({"\(bodyActionKey)": "\(PCSAction.aaaldInsertOnScreen.rawValue)"});
                        detectedIsOnScreen = true;
                    }
                }
            }

            document.addEventListener('scroll', function () {
                detectIfInsertIsOnScreen();
            }, {
                passive: true
            });

            detectIfInsertIsOnScreen();
        """
    }
    
    func aaaldTopBadgeJS(timestamp: String?, topBadgeType: TopBadgeType) -> String {
        let newChangesText = WMFLocalizedString("aaald-article-insert-new-changes", value: "New changes", comment: "Badge text in article content showing that there have been new significant updates to the article since the user last viewed it.")
        let lastUpdatedText = WMFLocalizedString("aaald-article-insert-last-updated", value: "Last updated", comment: "Badge text in article content showing when the article as last updated.")
        
        guard let timestamp = timestamp else {
            return ""
        }
        
        let innerContainerID = topBadgeType == .lastUpdated ? "significant-changes-top-inner-container-last-updated" : "significant-changes-top-inner-container-new-changes"
        let topTextID = topBadgeType == .lastUpdated ? "significant-changes-top-text-last-updated" : "significant-changes-top-text-new-changes"
        let badgeText = topBadgeType == .lastUpdated ? lastUpdatedText : newChangesText
        var badgeInnerHTML = "<div id='significant-changes-top-container'><div id='\(innerContainerID)'>"
        if topBadgeType == .newChanges {
            badgeInnerHTML += "<span id='significant-changes-top-dot'></span>"
        }
        badgeInnerHTML += "<span id='\(topTextID)'>\(badgeText)</span></div>"
        badgeInnerHTML += "<span id='significant-changes-top-timestamp'>\(timestamp)</span>"
        
        return """
            function injectNewChangesBadge() {
                //first remove existing element if it's there
                var existing = document.getElementById('\(badgeHTMLContainerID)');
                if (existing) {
                    existing.innerHTML = "\(badgeInnerHTML)";
                    return true;
                }
                \(createAndInsertBadgeScript(innerHTML: badgeInnerHTML))
            }
            
            injectNewChangesBadge();
        """
    }

    func injectArticleAsLivingDocContent(articleInsertHtmlSnippets: [String], topBadgeType: TopBadgeType = .lastUpdated, timestamp: String? = nil, _ completion: ((Bool) -> Void)? = nil) {
        
        guard articleInsertHtmlSnippets.count > 0 else {
            completion?(false)
            return
        }
        
        let contentInsertJS = aaaldContentInsertJS(articleInsertHtmlSnippets: articleInsertHtmlSnippets)
        let scrollViewDetectionJS = aaaldScrollViewDetectionJS()
        let topBadgeJS = aaaldTopBadgeJS(timestamp: timestamp, topBadgeType: topBadgeType)
        
        let finalInjectJS = contentInsertJS + scrollViewDetectionJS + topBadgeJS
        
        webView?.evaluateJavaScript(finalInjectJS) { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    DDLogDebug("Failure in injectArticleAsLivingDocContent: \(error)")
                    completion?(false)
                    return
                }
                
                if let boolResult = result as? Bool {
                    if !boolResult {
                        DDLogDebug("Failure in injectArticleAsLivingDocContent")
                    }
                    completion?(boolResult)
                    return
                }
                
                DDLogDebug("Failure in injectArticleAsLivingDocContent")
                completion?(false)
            }
        }
    }
    
    //should be used only when significant events is active
    //we are manually suppressing left and right body margins in standard view
    //and adding back in as padding so we get the edge to edge gray background
    func customUpdateMargins(with layoutMargins: UIEdgeInsets, leadImageHeight: CGFloat) {
        let javascript = """
            function customUpdateMargins() {
                 document.body.style.marginLeft = "0px";
                 document.body.style.marginRight = "0px";
                 document.body.style.paddingLeft = "\(layoutMargins.left)px";
                 document.body.style.paddingRight = "\(layoutMargins.right)px";
                 document.body.style.marginTop = "\(leadImageHeight + layoutMargins.top)px";
                 var seContainer = document.getElementById('\(articleAsLivingDocBoxContainerID)');
                 if (seContainer) {
                        seContainer.style.marginLeft = "-\(layoutMargins.left)px";
                        seContainer.style.marginRight = "-\(layoutMargins.right)px";
                        seContainer.style.paddingLeft = "\(layoutMargins.left)px";
                        seContainer.style.paddingRight = "\(layoutMargins.right)px";
                 }

                 return true;
            }
            customUpdateMargins();
        """
        webView?.evaluateJavaScript(javascript) { (success, error) in
            if let error = error {
                DDLogDebug("Failure in customUpdateMargins: \(error)")
            }
            
            if let success = success as? Bool,
               success == false {
                DDLogDebug("Failure in customUpdateMargins")
            }
        }
    }
}
