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
    let type: EditButtonType
    let ordered: Bool
    let depth: Int
}

struct SelectionChangedMessage {
    let selectionIsRange: Bool
}

private enum MessageNameConstants: String {
    case selectionChanged
    case highlightTheseButtons
}

private enum MessageConstants: String {
    case button
    case info
}

enum EditButtonType: String {
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
    case smallTextSize
    case bigTextSize
}

private enum ButtonInfoConstants: String {
    case ordered
    case depth
}

class SectionEditorWebViewConfiguration: WKWebViewConfiguration, WKScriptMessageHandler {

    override init() {
        super.init()
        setURLSchemeHandler(WMFURLSchemeHandler.shared(), forURLScheme: WMFURLSchemeHandlerScheme)
        
        let contentController = WKUserContentController()
        contentController.add(self, name: MessageNameConstants.selectionChanged.rawValue)
        contentController.add(self, name: MessageNameConstants.highlightTheseButtons.rawValue)
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
                if let buttonType = EditButtonType(rawValue: button) {
                    post(buttonNeedsToBeSelectedMessage: ButtonNeedsToBeSelectedMessage(type: buttonType, ordered: ordered, depth: depth))
                }
            }
        }
    }
}
