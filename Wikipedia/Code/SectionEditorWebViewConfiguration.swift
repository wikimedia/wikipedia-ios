import WebKit

extension NSNotification.Name {
    static let WMFSectionEditorSelectionChangedNotification = Notification.Name("WMFSectionEditorSelectionChangedNotification")
    static let WMFSectionEditorButtonHighlightNotification = Notification.Name("WMFSectionEditorButtonHighlightNotification")
}

extension SectionEditorWebViewConfiguration {
    static let WMFSectionEditorSelectionChanged = "WMFSectionEditorSelectionChanged"
    static let WMFSectionEditorSelectionChangedSelectedButton = "WMFSectionEditorSelectionChangedSelectedButton"
}

struct ButtonNeedsToBeSelectedMessage {
    let button: ButtonConstants
    let ordered: Bool
    let depth: Int
}

struct SelectionChangedMessage {
    let selectionIsRange: Bool
}

enum SectionEditorWebViewEventType: String {
    case atDocumentEnd
    case atDocumentStart
}

protocol SectionEditorWebViewEventDelegate: NSObjectProtocol {
    func handleEvent(_ type: SectionEditorWebViewEventType, userInfo: [String: Any])
}

private enum MessageNameConstants: String {
    case selectionChanged
    case highlightTheseButtons
    case event
}

private enum MessageConstants: String {
    case button
    case info
}

enum ButtonConstants: String {
    case li
    case heading
    case indent
    case signature
    case link
    case bold
    case italic
    case reference
    case template
    case undo
    case redo
    case debug
    case comment
}

private enum ButtonInfoConstants: String {
    case ordered
    case depth
}

class SectionEditorWebViewConfiguration: WKWebViewConfiguration, WKScriptMessageHandler {

    public weak var eventDelegate: SectionEditorWebViewEventDelegate?

    override init() {
        super.init()
        setURLSchemeHandler(WMFURLSchemeHandler.shared(), forURLScheme: WMFURLSchemeHandlerScheme)
        
        let contentController = WKUserContentController()
        contentController.add(self, name: MessageNameConstants.selectionChanged.rawValue)
        contentController.add(self, name: MessageNameConstants.highlightTheseButtons.rawValue)
        contentController.add(self, name: MessageNameConstants.event.rawValue)
        contentController.addUserScript(WKUserScript(source: "window.webkit.messageHandlers.event.postMessage({'type':'atDocumentStart'});", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        contentController.addUserScript(WKUserScript(source: "window.webkit.messageHandlers.event.postMessage({'type':'atDocumentEnd'});", injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        userContentController = contentController
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func post(selectionChangedMessage: SelectionChangedMessage) {
        NotificationCenter.default.post(
            name: Notification.Name.WMFSectionEditorSelectionChangedNotification,
            object: nil,
            userInfo: [SectionEditorWebViewConfiguration.WMFSectionEditorSelectionChanged: selectionChangedMessage]
        )
    }

    private func post(buttonNeedsToBeSelectedMessage: ButtonNeedsToBeSelectedMessage) {
        NotificationCenter.default.post(
            name: Notification.Name.WMFSectionEditorButtonHighlightNotification,
            object: nil,
            userInfo: [SectionEditorWebViewConfiguration.WMFSectionEditorSelectionChangedSelectedButton: buttonNeedsToBeSelectedMessage]
        )
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case MessageNameConstants.selectionChanged.rawValue:
            guard let isRangeSelected = message.body as? Bool else {
                DDLogError("Unable to interpret Bool message.")
                post(selectionChangedMessage: SelectionChangedMessage(selectionIsRange: false))
                break
            }
            post(selectionChangedMessage: SelectionChangedMessage(selectionIsRange: isRangeSelected))
        case MessageNameConstants.highlightTheseButtons.rawValue:
            callButtonEnableHighlightMethods(name: message.name, body: message.body)
        case MessageNameConstants.event.rawValue:
            guard let body = message.body as? [String: Any] else {
                return
            }
            guard let typeString = body["type"] as? String else {
                return
            }
            guard let type = SectionEditorWebViewEventType(rawValue: typeString) else {
                return
            }
            eventDelegate?.handleEvent(type, userInfo: body)
            
        default:
            DDLogError("Unhandled JS message.")
        }
    }
    
    private func callButtonEnableHighlightMethods(name: String, body: Any) {
        if let buttonDictArray = body as? Array<Dictionary<String, Any>> {
            for buttonDict in buttonDictArray {
                let buttonInfoDict = buttonDict[MessageConstants.info.rawValue] as? Dictionary<String, Any>
                guard let button = buttonDict[MessageConstants.button.rawValue] as? String else {
                    continue
                }
                let depth = buttonInfoDict?[ButtonInfoConstants.depth.rawValue] as? Int ?? 0
                let ordered = buttonInfoDict?[ButtonInfoConstants.ordered.rawValue] as? Bool ?? false
                if let buttonType = ButtonConstants(rawValue: button) {
                    post(buttonNeedsToBeSelectedMessage: ButtonNeedsToBeSelectedMessage(button: buttonType, ordered: ordered, depth: depth))
                }
            }
        }
    }
}
