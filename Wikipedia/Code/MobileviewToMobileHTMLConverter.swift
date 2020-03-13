import WebKit

@objc public class MobileviewToMobileHTMLConverter : NSObject, WKNavigationDelegate {
    private var isConverterLoaded = false
    lazy private var conversionBuffer: [() -> Void] = []
    
    // The 'domain' and 'baseURI' parameters are used by the mobileview-to-mobilehtml converter
    // to create <script> and <link> tags - check the converter output and ensure its <script>
    // and <link> tags have the same urls that we'd get directly calling the mobilehtml api.
    func convertToMobileHTML(mobileViewJSON: String, domain: String, baseURI: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        let conversion = {
            self.webView.evaluateJavaScript("convertMobileViewJSON(\(mobileViewJSON), `\(domain)`, `\(baseURI)`)", completionHandler: completionHandler)
        }
        guard isConverterLoaded else {
            conversionBuffer.append(conversion)
            guard webView.url == nil else {
                return
            }
            webView.loadFileURL(bundledConverterFileURL, allowingReadAccessTo: bundledConverterFileURL.deletingLastPathComponent())
            return
        }
        conversion()
    }
    lazy private var webView: WKWebView = {
        let wv = WKWebView(frame: .zero)
        wv.navigationDelegate = self
        return wv
    }()
    lazy private var bundledConverterFileURL: URL = {
        URL(fileURLWithPath: WikipediaAppUtils.assetsPath())
            .appendingPathComponent("pcs-html-converter", isDirectory: true)
            .appendingPathComponent("index.html", isDirectory: false)
    }()
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isConverterLoaded = true
        conversionBuffer.forEach {thisConversion in
            thisConversion()
        }
        conversionBuffer.removeAll()
    }
}

enum MobileviewToMobileHTMLConverterError: Error {
    case noArticleURL
    case noMobileViewJSONString
    case noArticleURLHost
    case noMobileAppsHost
}

extension MobileviewToMobileHTMLConverter {
    public func convertMobileviewSavedDataToMobileHTML(articleURL: URL, article: LegacyArticle, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        var mobileviewDict = article.info
        let sectionDictionaries = article.sections.map { (section) -> [String: Any] in
            var sectionDict: [String: Any] = section.info
            sectionDict["text"] = section.html
            return sectionDict
        }
        mobileviewDict["sections"] = sectionDictionaries
        if (mobileviewDict["normalizedtitle"] == nil) {
            mobileviewDict["normalizedtitle"] = articleURL.wmf_title
        }
        let jsonDict = ["mobileview": mobileviewDict]
        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict, options: .fragmentsAllowed),
            let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            assertionFailure("Article mobileview jsonString not reconstructed")
            completionHandler?(nil, MobileviewToMobileHTMLConverterError.noMobileViewJSONString)
            return
        }
        
        guard let host = articleURL.host else {
            assertionFailure("Article url host not available")
            if let completionHandler = completionHandler {
                completionHandler(nil, MobileviewToMobileHTMLConverterError.noArticleURLHost)
            } 
            return
        }


        convertToMobileHTML(mobileViewJSON: jsonString, domain: host, baseURI: ArticleFetcher.pcsBaseURI, completionHandler: completionHandler)
    }
}
