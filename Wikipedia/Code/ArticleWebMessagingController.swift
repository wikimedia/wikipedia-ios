
import Foundation

protocol ArticleWebMessageHandling: class {
    func didSetup(messagingController: ArticleWebMessagingController)
    func didTapLink(messagingController: ArticleWebMessagingController, title: String)
    func didGetLeadImage(messagingcontroller: ArticleWebMessagingController, source: String, width: Int?, height: Int?)
    func didGetTableOfContents(messagingcontroller: ArticleWebMessagingController, items: [TableOfContentsItem])
}

class ArticleWebMessagingController: NSObject {
    
    private weak var webView: WKWebView?
    private weak var delegate: ArticleWebMessageHandling?
    
    private let messageHandlerName = "action"
    private let bodyActionKey = "action"
    private let bodyDataKey = "data"

    init(delegate: ArticleWebMessageHandling?) {
        self.delegate = delegate
    }
    
    func setup(with webView: WKWebView, language: String, theme: Theme, leadImageHeight: Int, areTablesInitiallyExpanded: Bool, textSizeAdjustment: Int, userGroups: [String]) {
        let margins = PageContentService.Parameters.Margins(
            top: "16px",
            right: "16px",
            bottom: "16px",
            left: "16px"
        )
        let addTitleDescription = WMFLocalizedString("description-add-link-title", language: language, value: "Add title description", comment: "Text for link for adding a title description")
        let tableInfoboxTitle = WMFLocalizedString("info-box-title", language: language, value: "Quick Facts", comment: "The title of infoboxes – in collapsed and expanded form")
        let tableOtherTitle = WMFLocalizedString("table-title-other", language: language, value: "More information", comment: "The title of non-info box tables - in collapsed and expanded form {{Identical|More information}}")
        let tableFooterTitle = WMFLocalizedString("info-box-close-text", language: language, value: "Close", comment: "The text for telling users they can tap the bottom of the info box to close it {{Identical|Close}}")
        let l10n = PageContentService.Parameters.L10n(addTitleDescription: addTitleDescription, tableInfobox: tableInfoboxTitle, tableOther: tableOtherTitle, tableClose: tableFooterTitle)
        let parameters = PageContentService.Parameters(l10n: l10n, theme: theme.webName.lowercased(), dimImages: theme.imageOpacity < 1, margins: margins, leadImageHeight: "\(leadImageHeight)px", areTablesInitiallyExpanded: areTablesInitiallyExpanded, textSizeAdjustmentPercentage: "\(textSizeAdjustment)%", userGroups: userGroups)
        self.webView = webView
        let contentController = webView.configuration.userContentController
        contentController.add(self, name: messageHandlerName)
        do {
            let pcsSetup = try PageContentService.SetupScript(parameters, messageHandlerName: messageHandlerName)
            contentController.removeAllUserScripts()
            contentController.addUserScript(pcsSetup)
            let propertiesScript = PageContentService.PropertiesScript(messageHandlerName: messageHandlerName)
            contentController.addUserScript(propertiesScript)
            let utilitiesScript = PageContentService.UtilitiesScript()
            contentController.addUserScript(utilitiesScript)
        } catch let error {
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: false)
        }
    }
    
    // MARK: Adjustable state
    
    func updateTheme(_ theme: Theme) {
        let js = "pcs.c1.Page.setTheme(pcs.c1.Themes.\(theme.webName.uppercased()))"
        webView?.evaluateJavaScript(js)
    }

    func updateMargins(_ margins: PageContentService.Parameters.Margins) {
        guard let marginsJSON = try? PageContentService.getJavascriptFor(margins) else {
            return
        }
        webView?.evaluateJavaScript("pcs.c1.Page.setMargins(\(marginsJSON))")
    }
    
    func updateTextSizeAdjustmentPercentage(_ percentage: Int) {
        let js = "pcs.c1.Page.setTextSizeAdjustmentPercentage('\(percentage)%')"
        webView?.evaluateJavaScript(js)
    }
}

extension ArticleWebMessagingController: WKScriptMessageHandler {
    
    enum Action: String {
        case setup
        case linkClicked = "link_clicked"
        case properties
    }
    
    enum LinkKey: String {
        case href
        case text
        case title
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            return
        }
        guard let action = body[bodyActionKey] as? String else {
            return
        }
        let data = body[bodyDataKey] as? [String: Any]
        print(body)
        
        switch Action(rawValue: action) {
        case .setup:
            delegate?.didSetup(messagingController: self)
        case .linkClicked:
            
            guard let title = data?[LinkKey.title.rawValue] as? String else {
                assertionFailure("Missing title data in link")
                //tonitodo: pass back error for error state?
                return
            }
            
             delegate?.didTapLink(messagingController: self, title: title)
        case .properties:
            guard let data = data else {
                return
            }
            if
                let leadImage = data["leadImage"] as? [String: Any],
                let leadImageURLString = leadImage["source"] as? String {
                let width = leadImage["width"] as? Int
                let height = leadImage["height"] as? Int
                delegate?.didGetLeadImage(messagingcontroller: self, source: leadImageURLString, width: width, height: height)
            }
            if
                let tableOfContents = data["tableOfContents"] as? [[String: Any]]
            {
                let items = tableOfContents.compactMap { (tocJSON) -> TableOfContentsItem? in
                    guard
                        let id = tocJSON["id"] as? Int,
                        let level = tocJSON["level"] as? Int,
                        let anchor = tocJSON["anchor"] as? String,
                        let title = tocJSON["title"] as? String
                    else {
                            return nil
                    }
                    return TableOfContentsItem(id: id, titleHTML: title, anchor: anchor, indentationLevel: level)
                }
                delegate?.didGetTableOfContents(messagingcontroller: self, items: items)
            }
        default:
            break
        }
    }
}
