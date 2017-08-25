import WebKit

// "addScriptMessageHandler:" retains the handler object you pass it,
// which caused the WebViewController's dealloc to never get called.
// See http://stackoverflow.com/a/26383032/135557 for details.

class WeakScriptMessageDelegate : NSObject, WKScriptMessageHandler {
    weak var delegate : WKScriptMessageHandler?
    @objc init(delegate:WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    @objc func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceive: message)
    }
}
