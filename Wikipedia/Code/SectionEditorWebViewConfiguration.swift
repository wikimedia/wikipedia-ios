import WebKit

protocol SectionEditorWebViewSelectionChangedDelegate: NSObjectProtocol {
    func turnOffAllButtonHighlights()
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

private enum MessageNameConstants: String {
    case highlightTheseButtons
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

    override init() {
        super.init()
        setURLSchemeHandler(WMFURLSchemeHandler.shared(), forURLScheme: WMFURLSchemeHandlerScheme)
        
        let contentController = WKUserContentController()
        contentController.add(self, name: MessageNameConstants.highlightTheseButtons.rawValue)
        userContentController = contentController
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // First disable all buttons...
        selectionChangedDelegate?.turnOffAllButtonHighlights()
        
        // Now enable just the buttons which need to be (based on messages received from JS land)...
        callButtonEnableHighlightMethods(name: message.name, body: message.body)
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
