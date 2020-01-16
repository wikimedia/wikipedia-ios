
import Foundation

protocol ArticleWebMessageHandling: class {
    func didSetup(messagingController: ArticleWebMessagingController)
    func didTapLink(messagingController: ArticleWebMessagingController, title: String)
    func didGetLeadImage(messagingcontroller: ArticleWebMessagingController, source: String, width: Int?, height: Int?)
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
    
    func setup(webView: WKWebView, with parameters: PageContentService.Parameters) {
        self.webView = webView
        let contentController = webView.configuration.userContentController
        contentController.add(self, name: messageHandlerName)
        do {
            let pcsSetup = try PageContentService.SetupScript(parameters, messageHandlerName: messageHandlerName)
            contentController.removeAllUserScripts()
            contentController.addUserScript(pcsSetup)
            let propertiesScript = PageContentService.PropertiesScript(messageHandlerName: messageHandlerName)
            contentController.addUserScript(propertiesScript)
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
        default:
            break
        }
    }
}
