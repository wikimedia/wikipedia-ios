import Foundation
import WebKit
import WMF

@objc protocol WMFPreviewAnchorTapAlertDelegate: class {
    func previewWebViewContainer(_ previewWebViewContainer: PreviewWebViewContainer, didTapLink url: URL)
}

class PreviewWebViewContainer: UIView, WKNavigationDelegate, Themeable {
    var theme: Theme = .standard
    @IBOutlet weak var previewAnchorTapAlertDelegate: WMFPreviewAnchorTapAlertDelegate!

    lazy var webView: WKWebView = {
        let controller = WKUserContentController()
        var earlyJSTransforms = ""

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.applicationNameForUserAgent = "WikipediaApp"
        

        let newWebView = WKWebView(frame: CGRect.zero, configuration: configuration)
        newWebView.isOpaque = false
        newWebView.scrollView.backgroundColor = .clear
        wmf_addSubviewWithConstraintsToEdges(newWebView)
        newWebView.navigationDelegate = self
        return newWebView
    }()

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated else {
            decisionHandler(WKNavigationActionPolicy.allow)
            return
        }
        previewAnchorTapAlertDelegate.previewWebViewContainer(self, didTapLink: url)
        decisionHandler(WKNavigationActionPolicy.cancel)
    }

    func apply(theme: Theme) {
        self.theme = theme
        webView.backgroundColor = theme.colors.paperBackground
        backgroundColor = theme.colors.paperBackground
    }
}
