import Foundation

// sets the theme using wmf.applyTheme atDocumentEnd
class CodemirrorSetupUserScript: WKUserScript, WKScriptMessageHandler {
    let messageHandlerName = "wmfThemeReady"
    let completion: () -> Void
    
    init(language: String, theme: Theme, completion: @escaping () -> Void) {
        self.completion = completion
        let source = """
        wmf.setup('\(language)', '\(theme.webName)', () => {
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
