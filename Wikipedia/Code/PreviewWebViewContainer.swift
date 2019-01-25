import Foundation
import WebKit
import WMF

@objc protocol WMFPreviewSectionLanguageInfoDelegate: class {
    func wmf_editedSectionLanguageInfo() -> MWLanguageInfo?
}

@objc protocol WMFPreviewAnchorTapAlertDelegate: class {
    func wmf_showAlert(forTappedAnchorHref href: String)
}

class PreviewWebViewContainer: UIView, WKNavigationDelegate, WKScriptMessageHandler, Themeable {
    weak var externalLinksOpenerDelegate: WMFOpenExternalLinkDelegate?
    var theme: Theme = .standard
    @IBOutlet weak var previewSectionLanguageInfoDelegate: WMFPreviewSectionLanguageInfoDelegate!
    @IBOutlet weak var previewAnchorTapAlertDelegate: WMFPreviewAnchorTapAlertDelegate!

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let href = href(from: message) else {
            return
        }
        previewAnchorTapAlertDelegate.wmf_showAlert(forTappedAnchorHref: href)
    }
    
    private func href(from message: WKScriptMessage) -> String? {
        guard message.name == "anchorClicked", let messageDict = message.body as? [String: Any], let href = messageDict["href"] as? String else {
            return nil
        }
        return href
    }
    
    private func configuration() -> WKWebViewConfiguration {
        let controller = WKUserContentController()
        var earlyJSTransforms = ""
        if let langInfo = previewSectionLanguageInfoDelegate.wmf_editedSectionLanguageInfo() {
            earlyJSTransforms = earlyJSTransformsString(for: langInfo, isRTL: UIApplication.shared.wmf_isRTL)
        }
        controller.addUserScript(WKUserScript(source: earlyJSTransforms, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        controller.addUserScript(WKUserScript(source: "window.wmf.themes.classifyElements(document)", injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        controller.add(WeakScriptMessageDelegate(delegate: self), name: "anchorClicked")

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.applicationNameForUserAgent = "WikipediaApp"
        config.setURLSchemeHandler(WMFURLSchemeHandler.shared(), forURLScheme: WMFURLSchemeHandlerScheme)
        return config
    }

    private func earlyJSTransformsString(for langInfo: MWLanguageInfo, isRTL: Bool) -> String {
        return """
            addEventListener('click', () => {
                event.preventDefault()
                if (event.target.tagName == 'A'){
                    const href = event.target.getAttribute( 'href' )
                    window.webkit.messageHandlers.anchorClicked.postMessage({ 'href': href })
                }
            })
            window.wmf.utilities.setLanguage('\(langInfo.code)', '\(langInfo.dir)', '\(isRTL ? "rtl" : "ltr")')
            """
    }

    lazy var webView: WKWebView = {
        let newWebView = WKWebView(frame: CGRect.zero, configuration: configuration())
        newWebView.isOpaque = false
        newWebView.scrollView.backgroundColor = .clear
        wmf_addSubviewWithConstraintsToEdges(newWebView)
        newWebView.navigationDelegate = self
        return newWebView
    }()

    // Force web view links to open in Safari.
    // From: http://stackoverflow.com/a/2532884
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let requestURL = navigationAction.request.url
        if ((requestURL?.scheme == "http") || (requestURL?.scheme == "https") || (requestURL?.scheme == "mailto")) && (navigationAction.navigationType == .linkActivated) {
            externalLinksOpenerDelegate?.wmf_openExternalUrl(requestURL)
            decisionHandler(WKNavigationActionPolicy.cancel)
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }

    func apply(theme: Theme) {
        self.theme = theme
        webView.backgroundColor = theme.colors.paperBackground
        backgroundColor = theme.colors.paperBackground
    }
}
