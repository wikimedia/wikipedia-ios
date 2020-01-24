import Foundation
import WebKit
import WMF

@objc protocol WMFPreviewSectionLanguageInfoDelegate: class {
    func wmf_editedSectionLanguageInfo() -> MWLanguageInfo?
}

@objc protocol WMFPreviewAnchorTapAlertDelegate: class {
    func previewWebViewContainer(_ previewWebViewContainer: PreviewWebViewContainer, didTapLink url: URL, exists: Bool, isExternal: Bool)
}

class PreviewWebViewContainer: UIView, WKNavigationDelegate, Themeable {
    var theme: Theme = .standard
    @IBOutlet weak var previewSectionLanguageInfoDelegate: WMFPreviewSectionLanguageInfoDelegate!
    @IBOutlet weak var previewAnchorTapAlertDelegate: WMFPreviewAnchorTapAlertDelegate!

    lazy var webView: WKWebView = {
        let controller = WKUserContentController()
        var earlyJSTransforms = ""

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.applicationNameForUserAgent = "WikipediaApp"
        let schemeHandler = SchemeHandler.shared
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)

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
        let exists: Bool
        if let query = url.query {
            exists = !query.contains("redlink=1")
        } else {
            exists = true
        }
        let isExternal = url.host != "wikipedia.org"
        previewAnchorTapAlertDelegate.previewWebViewContainer(self, didTapLink: url, exists: exists, isExternal: isExternal)
        decisionHandler(WKNavigationActionPolicy.cancel)
    }

    func apply(theme: Theme) {
        self.theme = theme
        webView.backgroundColor = theme.colors.paperBackground
        backgroundColor = theme.colors.paperBackground
    }
}
