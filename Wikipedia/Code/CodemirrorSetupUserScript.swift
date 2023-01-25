import Foundation

// sets the theme using wmf.applyTheme atDocumentEnd
class CodemirrorSetupUserScript: PageUserScript, WKScriptMessageHandler {
    public enum CodemirrorDirection: String {
        case ltr
        case rtl
    }
    let messageHandlerName = "wmfCodemirrorReady"
    let completion: () -> Void
    
    init(languageCode: String, direction: CodemirrorDirection, theme: Theme, textSizeAdjustment: Int, isSyntaxHighlighted: Bool, readOnly: Bool, completion: @escaping () -> Void) {
        self.completion = completion
        let source = """
        wmf.setup('\(languageCode)', '\(direction.rawValue)', '\(theme.webName)', \(textSizeAdjustment), \(isSyntaxHighlighted), \(readOnly), () => {
            window.webkit.messageHandlers.\(messageHandlerName).postMessage({})
        })
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        DispatchQueue.main.async {
            self.completion()
        }
    }
}
