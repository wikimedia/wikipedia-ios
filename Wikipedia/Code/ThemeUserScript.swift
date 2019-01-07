import Foundation

// sets the theme using wmf.applyTheme atDocumentEnd
class ThemeUserScript: WKUserScript, WKScriptMessageHandler {
    let messageHandlerName = "wmfThemeReady"
    let completion: () -> Void
    
    init(_ theme: Theme, completion: @escaping () -> Void) {
        self.completion = completion
        let source = """
        wmf.applyTheme('\(theme.webName)', () => {
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
