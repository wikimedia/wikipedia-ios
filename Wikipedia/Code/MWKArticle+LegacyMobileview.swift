
fileprivate extension MWKSection {
    func mobileViewDict() -> [String: Any?] {
        var dict: [String: Any?] = [:]
        dict["toclevel"] = toclevel
        dict["level"] = level?.stringValue
        dict["line"] = line
        dict["number"] = number
        dict["index"] = index
        dict["anchor"] = anchor
        dict["id"] = sectionId
        dict["text"] = text // stringByReplacingImageURLsWithAppSchemeURLs(inHTMLString: text ?? "", withBaseURL: baseURL, targetImageWidth: imageWidth)
        dict["fromtitle"] = fromURL?.wmf_titleWithUnderscores
        return dict
    }
}

fileprivate extension MWKArticle {
    func mobileViewLastModified() -> String? {
        guard let lastModifiedDate = lastmodified else {
            return nil
        }
        return iso8601DateString(lastModifiedDate)
    }
    func mobileViewLastModifiedBy() -> [String: String]? {
        guard let lastmodifiedby = lastmodifiedby else {
            return nil
        }
        return [
            "name": lastmodifiedby.name ?? "",
            "gender": lastmodifiedby.gender ?? ""
        ]
    }
    func mobileViewPageProps() -> [String: String]? {
        guard let wikidataId = wikidataId else {
            return nil
        }
        return [
            "wikibase_item": wikidataId
        ]
    }
    func mobileViewDescriptionSource() -> String? {
        switch descriptionSource {
        case .local:
            return "local"
        case .central:
            return "central"
        default:
            // should default use "local" too?
            return nil
        }
    }
    func mobileViewImage(size: CGSize) -> [String: Any]? {
        guard let imgName = image?.canonicalFilename() else {
            return nil
        }
        return [
            "file": imgName,
            "width": size.width,
            "height": size.height
        ]
    }
    func mobileViewThumbnail() -> [String: Any]? {
        guard let thumbnailSourceURL = imageURL /*article.thumbnail?.sourceURL.absoluteString*/ else {
            return nil
        }
        return [
            "url": thumbnailSourceURL
            // Can't seem to find the original thumb "width" and "height" to match that seen in the orig mobileview - did we not save/model these?
        ]
    }
    func mobileViewProtection() -> [String: Any]? {
        guard let protection = protection else {
            return nil
        }
        var protectionDict:[String: Any] = [:]
        for protectedAction in protection.protectedActions() {
            guard let actionString = protectedAction as? String else {
                continue
            }
            protectionDict[actionString] = protection.allowedGroups(forAction: actionString)
        }
        return protectionDict
    }
}

extension MWKArticle {
    @objc private func reconstructMobileViewJSON(imageSize: CGSize) -> [String: Any]? {
        guard
            let sections = sections?.entries as? [MWKSection]
        else {
            assertionFailure("Couldn't get expected article sections")
            return nil
        }

        var mvDict: [String: Any] = [:]
        
        mvDict["ns"] = ns
        mvDict["lastmodified"] = mobileViewLastModified()
        mvDict["lastmodifiedby"] = mobileViewLastModifiedBy()
        mvDict["revision"] = revisionId
        mvDict["languagecount"] = languagecount
        mvDict["displaytitle"] = displaytitle
        mvDict["id"] = articleId
        mvDict["pageprops"] = mobileViewPageProps()
        mvDict["description"] = entityDescription
        mvDict["descriptionsource"] = mobileViewDescriptionSource()
        mvDict["sections"] = sections.map { $0.mobileViewDict() }
        mvDict["editable"] = editable
        mvDict["image"] = mobileViewImage(size: imageSize)
        mvDict["thumb"] = mobileViewThumbnail()
        mvDict["protection"] = mobileViewProtection()

        return ["mobileview": mvDict]
    }
    @objc public func reconstructedMobileViewJSONString(imageSize: CGSize) -> String? {
        guard
            let jsonDict = reconstructMobileViewJSON(imageSize: imageSize),
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict),
            let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            assertionFailure("JSON string extraction failed")
            return nil
        }
        return jsonString
    }
}

class MobileviewToMobileHTMLConverter : NSObject, WKNavigationDelegate {
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
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isConverterLoaded = true
        conversionBuffer.forEach {thisConversion in
            thisConversion()
        }
        conversionBuffer.removeAll()
    }
}

extension MobileviewToMobileHTMLConverter {
    func convertMobileviewSavedDataToMobileHTML(article: MWKArticle, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        guard let articleURL = article.url else {
            assertionFailure("Article url not available")
            return
        }
        guard let jsonString = article.reconstructedMobileViewJSONString(imageSize: CGSize(width: 320, height: 320)) else {
            assertionFailure("Article mobileview jsonString not reconstructed")
            return
        }
        guard let host = articleURL.host else {
            assertionFailure("Article url host not available")
            return
        }
// TODO: baseURI will need to change once we switch back to prod for mobilehtml!!
        guard let mobileappsHost = Configuration.mobileAppsServicesLabs.wikipediaMobileAppsServicesAPIURLComponentsForHost(articleURL.host, appending: []).host else {
            assertionFailure("Mobileapps url host not available")
            return
        }
        let baseURI = "//\(mobileappsHost)/api/v1/"

        convertToMobileHTML(mobileViewJSON: jsonString, domain: host, baseURI: baseURI, completionHandler: completionHandler)
    }
}

//EXAMPLE CONVERSION:

/*

    lazy var converter: MobileviewToMobileHTMLConverter = {
        MobileviewToMobileHTMLConverter.init()
    }()
    
    override func didReceiveMemoryWarning() {

        guard
            let dataStore = SessionSingleton.sharedInstance()?.dataStore,
            let articleCacheController = dataStore.articleCacheControllerWrapper.cacheController as? ArticleCacheController
        else {
            return
        }

        dataStore.savedPageList.enumerateItems { (article, stop) in
            guard let articleURL = article.url else {
                assertionFailure("Could not get article url")
                return
            }
            guard article.mobileviewConversionAttempted == false else {
                // If conversion was previously attempted don't try again.
                return
            }

            do {
                // Since conversion isn't instantaneous set the `mobileviewConversionAttempted` flag before invoking
                // the converter (vs only setting it in the converter's completion block)
                article.mobileviewConversionAttempted = true
                try dataStore.save()
            } catch let error {
                DDLogError("Error updating article: \(error)")
            }

            let article = dataStore.article(with: articleURL)
            
            self.converter.convertMobileviewSavedDataToMobileHTML(article: article) { (result, error) in

                let handleConversionFailure = {
                    // TODO: no need to keep mobileview section html if conversion failed, so ok to remove section data
                    // because we're setting `isDownloaded` next so saved article fetching will re-download from new
                    // mobilehtml endpoint
                    //
                    // article.sections?.entries.removeAll()

                    
                    // TODO: if conversion failed above for any reason set "article.isDownloaded" to false so normal fetching logic picks it up
                    //
                    // article.isDownloaded = false
                }
                
                guard error == nil, let result = result else {
                    handleConversionFailure()
                    assertionFailure("Conversion error or no result")
                    return
                }
                guard let mobileHTML = result as? String else {
                    handleConversionFailure()
                    assertionFailure("mobileHTML not extracted")
                    return
                }
                
                
                articleCacheController.cacheFromMigration(desktopArticleURL: articleURL, content: mobileHTML, mimeType: "text/html")
            }
        }
    }
 
*/
