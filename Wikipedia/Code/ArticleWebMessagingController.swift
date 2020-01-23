
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
        contentController.add(self, name: PageContentService.messageHandlerName)
        do {
            let pcsSetup = try PageContentService.SetupScript(parameters)
            contentController.removeAllUserScripts()
            contentController.addUserScript(pcsSetup)
            let propertiesScript = PageContentService.PropertiesScript()
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
    /// Actions represent events from the web page
    enum Action {
        case setup
        case finalSetup
        case image
        case link(title: String)
        case reference
        case pronunciation
        case properties
        case edit(sectionID: Int, descriptionSource: String?)
        case addTitleDescription
        case footerItemSelected
        case readMoreTitlesRetrieved
        case viewLicense
        case viewInBrowser
        case leadImage(source: String, width: Int?, height: Int?)
        case tableOfContents(items: [TableOfContentsItem])
    }
    
    /// PCSActions are receieved from the JS bridge and converted into actions
    // Handle both _clicked and non-clicked variants in case the names change
    private enum PCSAction: String {
        case setup
        case finalSetup = "final_setup"
        case image
        case link
        case reference
        case pronunciation
        case edit = "edit_section"
        case addTitleDescription = "add_title_description"
        case footerItemSelected = "footer_item_selected"
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
                return .image
            case .reference:
                return .reference
            case .pronunciation:
                return .pronunciation
            case .edit:
                return getEditAction(with: data)
            case .addTitleDescription:
                return .addTitleDescription
            case .footerItemSelected:
                return .footerItemSelected
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
            guard
               let leadImage = data?["leadImage"] as? [String: Any],
               let source = leadImage["source"] as? String else {
                return nil
            }
            let width = leadImage["width"] as? Int
            let height = leadImage["height"] as? Int
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
            guard let title = data?[LinkKey.title.rawValue] as? String else {
                assertionFailure("Missing title data in link")
                return nil
            }
            return .link(title: title)
        }
        func getEditAction(with data: [String: Any]?) -> Action? {
            guard let sectionID = data?["sectionId"] as? Int else {
                assertionFailure("Missing title data in link")
                return nil
            }
            return .edit(sectionID: sectionID, descriptionSource: data?["descriptionSource"] as? String)
        }
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
        guard let actionString = body[bodyActionKey] as? String else {
            return
        }
        let data = body[bodyDataKey] as? [String: Any]
        guard let action = PCSAction(pcsActionString: actionString)?.getAction(with: data) else {
            return
        }
        delegate?.didRecieve(action: action)
    }
}
