import Foundation

// sets the theme using wmf.applyTheme atDocumentEnd
class CodemirrorSetupUserScript: PageUserScript, WKScriptMessageHandler {
    public enum CodemirrorDirection: String {
        case ltr
        case rtl
    }
    let messageHandlerName = "wmfCodemirrorReady"
    let completion: () -> Void
    
    init(language: String, direction: CodemirrorDirection, theme: Theme, textSizeAdjustment: Int, isSyntaxHighlighted: Bool, completion: @escaping () -> Void) {
        self.completion = completion
        let source = """
        wmf.setup('\(language)', '\(direction.rawValue)', '\(theme.webName)', \(textSizeAdjustment), \(isSyntaxHighlighted), () => {
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
