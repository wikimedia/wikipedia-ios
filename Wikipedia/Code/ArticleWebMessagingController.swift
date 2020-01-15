
import Foundation

protocol ArticleWebMessageHandling: class {
    func didSetup(messagingController: ArticleWebMessagingController)
    func didTapLink(messagingController: ArticleWebMessagingController, title: String)
}

class ArticleWebMessagingController: NSObject {
    
    private weak var delegate: ArticleWebMessageHandling?
    
    private let messageHandlerName = "action"
    private let bodyActionKey = "action"
    private let bodyDataKey = "data"

    init(delegate: ArticleWebMessageHandling?) {
        self.delegate = delegate
    }
    
    func setup(contentController: WKUserContentController, with parameters: PageContentServiceSetupScript.Parameters) {
        contentController.add(self, name: messageHandlerName)
        do {
            let pcsSetup = try PageContentServiceSetupScript(parameters, messageHandlerName: messageHandlerName)
            contentController.removeAllUserScripts()
            contentController.addUserScript(pcsSetup)
        } catch let error {
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: false)
        }
    }
}

extension ArticleWebMessagingController: WKScriptMessageHandler {
    
    enum Action: String {
        case setup
        case linkClicked = "link_clicked"
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
            
        default:
            break
        }
    }
}
