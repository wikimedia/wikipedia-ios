import Foundation
import WebKit
import WMF

@objc protocol WMFPreviewSectionLanguageInfoDelegate: class {
    func wmf_editedSectionLanguageInfo() -> MWLanguageInfo?
}

@objc protocol WMFPreviewAnchorTapAlertDelegate: class {
    func wmf_showAlert(forTappedAnchorHref href: String)
}

class PreviewWebViewContainer: UIView, WKNavigationDelegate, Themeable {
    weak var externalLinksOpenerDelegate: WMFOpenExternalLinkDelegate?
    var theme: Theme = .standard
    @IBOutlet weak var previewSectionLanguageInfoDelegate: WMFPreviewSectionLanguageInfoDelegate!
    @IBOutlet weak var previewAnchorTapAlertDelegate: WMFPreviewAnchorTapAlertDelegate!
    
    private func earlyJSTransformsString(for langInfo: MWLanguageInfo, isRTL: Bool) -> String {
        return "window.wmf.utilities.setLanguage('\(langInfo.code)', '\(langInfo.dir)', '\(isRTL ? "rtl" : "ltr")')"
    }

    lazy var webView: WKWebView = {
        let controller = WKUserContentController()
        var earlyJSTransforms = ""
        if let langInfo = previewSectionLanguageInfoDelegate.wmf_editedSectionLanguageInfo() {
            earlyJSTransforms = earlyJSTransformsString(for: langInfo, isRTL: UIApplication.shared.wmf_isRTL)
        }
        controller.addUserScript(WKUserScript(source: earlyJSTransforms, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        controller.addUserScript(WKUserScript(source: "window.wmf.themes.classifyElements(document)", injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        
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
        guard let path = navigationAction.request.url?.path, navigationAction.navigationType == .linkActivated else {
            decisionHandler(WKNavigationActionPolicy.allow)
            return
        }
        previewAnchorTapAlertDelegate.wmf_showAlert(forTappedAnchorHref: path)
        decisionHandler(WKNavigationActionPolicy.cancel)
    }

    func apply(theme: Theme) {
        self.theme = theme
        webView.backgroundColor = theme.colors.paperBackground
        backgroundColor = theme.colors.paperBackground
    }
}
