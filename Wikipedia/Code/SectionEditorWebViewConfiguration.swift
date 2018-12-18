import WebKit

protocol SectionEditorWebViewSelectionChangedDelegate: NSObjectProtocol {
    // Inside 'selectionChanged' the delegate should de-select all buttons.
    func selectionChanged(isRangeSelected: Bool)

    // Inside these the delegate should enable the respective button.
    func highlightBoldButton()
    func highlightItalicButton()
    func highlightReferenceButton()
    func highlightTemplateButton()
    func highlightAnchorButton()
    func highlightIndentButton(depth: Int)
    func highlightSignatureButton(depth: Int)
    func highlightListButton(ordered: Bool, depth: Int)
    func highlightHeadingButton(depth: Int)
    func highlightUndoButton()
    func highlightRedoButton()
    func highlightCommentButton()
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

private enum ButtonConstants: String {
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

    public weak var selectionChangedDelegate: SectionEditorWebViewSelectionChangedDelegate?
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
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case MessageNameConstants.selectionChanged.rawValue:
            guard let isRangeSelected = message.body as? Bool else {
                DDLogError("Unable to interpret Bool message.")
                selectionChangedDelegate?.selectionChanged(isRangeSelected: false)
                break
            }
            selectionChangedDelegate?.selectionChanged(isRangeSelected: isRangeSelected)
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

                switch button {
                case ButtonConstants.li.rawValue:
                    guard let ordered = buttonInfoDict?[ButtonInfoConstants.ordered.rawValue] as? Bool else {
                        break
                    }
                    selectionChangedDelegate?.highlightListButton(ordered: ordered, depth: depth)
                    break
                case ButtonConstants.heading.rawValue:
                    selectionChangedDelegate?.highlightHeadingButton(depth: depth)
                    break
                case ButtonConstants.indent.rawValue:
                    selectionChangedDelegate?.highlightIndentButton(depth: depth)
                    break
                case ButtonConstants.signature.rawValue:
                    selectionChangedDelegate?.highlightSignatureButton(depth: depth)
                    break
                case ButtonConstants.link.rawValue:
                    selectionChangedDelegate?.highlightAnchorButton()
                    break
                case ButtonConstants.bold.rawValue:
                    selectionChangedDelegate?.highlightBoldButton()
                    break
                case ButtonConstants.italic.rawValue:
                    selectionChangedDelegate?.highlightItalicButton()
                    break
                case ButtonConstants.reference.rawValue:
                    selectionChangedDelegate?.highlightReferenceButton()
                    break
                case ButtonConstants.template.rawValue:
                    selectionChangedDelegate?.highlightTemplateButton()
                    break
                case ButtonConstants.undo.rawValue:
                    selectionChangedDelegate?.highlightUndoButton()
                    break
                case ButtonConstants.redo.rawValue:
                    selectionChangedDelegate?.highlightRedoButton()
                    break
                case ButtonConstants.comment.rawValue:
                    selectionChangedDelegate?.highlightCommentButton()
                    break
                case ButtonConstants.debug.rawValue:
                    print("\n\n\n\(buttonInfoDict ?? ["" : ""])")
                    break
                default:
                    break
                }
            }
        }
    }
}
