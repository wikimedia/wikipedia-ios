import WebKit
import WMF

let WKWebViewLoadAssetsHTMLRequestTimeout: TimeInterval = 60; //60s is the default NSURLRequest timeout interval

extension WKWebView {
    
    // Loads contents of fileName. Assumes the file is in the "assets" folder.
    @objc func loadHTMLFromAssetsFile(_ fileName: String?, scrolledToFragment fragment: String?) {
        guard
            let fileName = fileName,
            let requestURL = WMFProxyServer.shared().proxyURL(forRelativeFilePath: fileName, fragment: fragment ?? "top")
        else {
            DDLogError("attempted to load nil fileName or requestURL");
            return
        }
        self.load(URLRequest.init(url: requestURL, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: WKWebViewLoadAssetsHTMLRequestTimeout))
    }
    
    // Loads html passed to it injected into html from fileName.
    @objc func loadHTML(_ string: String?, baseURL: URL?, withAssetsFile fileName: String?, scrolledToFragment fragment: String?, padding: UIEdgeInsets, theme: Theme) {
        guard
            let fileName = fileName,
            let baseURL = baseURL,
            let articleDatabaseKey = baseURL.wmf_articleDatabaseKey
        else {
            DDLogError("window, proxyServer, baseURL or fileName not found");
            return
        }
        
        let proxyServer = WMFProxyServer.shared()
        if proxyServer.isRunning == false {
            proxyServer.start()
        }

        let localFilePath = (WikipediaAppUtils.assetsPath() as NSString).appendingPathComponent(fileName)
        guard let fileContents = try? String(contentsOfFile: localFilePath, encoding: String.Encoding.utf8) else {
            DDLogError("\(localFilePath) contents not found");
            return
        }

        assert(fileContents.split(separator: "@").count == (6 + 1), """
                HTML template file does not have required number of percent-ampersand occurences (5).
                Number of percent-ampersands must match number of values passed to 'stringWithFormat:'
        """)
        
        let headTagAddition = stringToInjectIntoHeadTag(fontSize: UserDefaults.wmf.wmf_articleFontSizeMultiplier(), baseURL: baseURL, theme: theme)
        
        var siteCSSLink = ""
        if let baseSite = baseURL.wmf_site?.absoluteString {
            siteCSSLink = """
            <link href="\(baseSite)/api/rest_v1/data/css/mobile/site" rel="stylesheet" type="text/css"></link>
            """
        }
        
        // index.html and preview.html have 6 "%@" subsitition markers. Replace these with actual content.
        let templateAndContent = String(format: fileContents, siteCSSLink, headTagAddition, padding.top as NSNumber, padding.left as NSNumber, padding.right as NSNumber, string ?? "")
        
        let requestPath = "\(articleDatabaseKey.hash)-\(fileName)"
        proxyServer.setResponseData(templateAndContent.data(using: String.Encoding.utf8), withContentType: "text/html; charset=utf-8", forPath: requestPath)
        
        loadHTMLFromAssetsFile(requestPath, scrolledToFragment: fragment)
    }
    
    fileprivate func stringToInjectIntoHeadTag(fontSize: NSNumber, baseURL: URL, theme: Theme) -> String {
        /*
        The 'theme' and 'compatibility' calls are deliberately injected specifically into the head tag via an inline script because:
             "... inline scripts are fetched and executed immediately, before the browser continues to parse the page"
             https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script
        
         This ensures all theme settings are in place before any page rendering occurs.
        
        'compatibility.enableSupport()'
             Needs to happen only once but *before* body elements are present and before
             calling 'themes.setTheme()'.
        
        'themes.setTheme()'
             Needs to happen before body elements are present so these will appear with
             correct theme colors already set. (This method is also used to changes themes,
             but changing themes doesn't require 'compatibility.enableSupport()' or
             'themes.classifyElements()' be called again.)
        
        Reminder:
             We don't want to use 'addUserScript:' with WKUserScriptInjectionTimeAtDocumentEnd for this because
             it happens too late - at 'DocumentEnd'. We want the colors to be set before this so there is never
             a flickering color change visible to the user. We can't use WKUserScriptInjectionTimeAtDocumentBegin
             because this fires before any of the head tag contents are resolved, including references to our JS
             libraries - we'd have to make a larger set of changes to make this work.
        */
        
        return """
            <style type='text/css'>
                body {
                    -webkit-text-size-adjust: \(fontSize)%;
                }
            </style>
            <base href="\(baseURL.absoluteString)">
            <script type='text/javascript'>
                window.wmf.compatibility.enableSupport(document)
                window.wmf.platform.classify(window)
                \(WKWebView.wmf_themeApplicationJavascript(with: theme))
            </script>
            """
    }
}
