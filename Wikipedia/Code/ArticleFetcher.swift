
import UIKit

enum ArticleFetcherError: Error {
    case doesNotExist
    case failureToGenerateURL
    case missingData
    case invalidEndpointType
    case unableToGenerateURLRequest
}

@objc(WMFArticleFetcher)
final public class ArticleFetcher: Fetcher, CacheFetching {    
    @objc required public init(session: Session, configuration: Configuration) {
        #if WMF_APPS_LABS_PAGE_CONTENT_SERVICE
        super.init(session: Session.shared, configuration: Configuration.appsLabsPageContentService)
        #elseif WMF_LOCAL_PAGE_CONTENT_SERVICE
        super.init(session: Session.shared, configuration: Configuration.localPageContentService)
        #else
        super.init(session: session, configuration: configuration)
        #endif
    }
    
    public enum EndpointType: String {
        case summary
        case mediaList = "media-list"
        case mobileHtmlOfflineResources = "mobile-html-offline-resources"
        case mobileHTML = "mobile-html"
        case references = "references"
    }

    public enum MobileHTMLType: String {
        case contentAndReferences = "contentAndReferences"
        case content = "content"
        case references = "references"
        case editPreview = "editPreview"
    }
    
    struct MediaListItem {
        let imageURL: URL
        let imageTitle: String
    }
    
    @discardableResult func fetchMediaListURLs(with request: URLRequest, completion: @escaping (Result<[MediaListItem], Error>) -> Void) -> URLSessionTask? {
          return fetchMediaList(with: request) { (result, response) in
            if let statusCode = response?.statusCode,
               statusCode == 404 {
               completion(.failure(ArticleFetcherError.doesNotExist))
               return
            }
            
            struct SourceAndTitle {
                let source: MediaListItemSource
                let title: String?
            }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let mediaList):
                
                var sourceAndTitles: [SourceAndTitle] = []
                for item in mediaList.items {
                    
                    guard let sources = item.sources else {
                        continue
                    }
                    
                    for source in sources {
                        sourceAndTitles.append(SourceAndTitle(source: source, title: item.title))
                    }
                }
                
                let result = sourceAndTitles.map { (sourceAndTitle) -> MediaListItem? in
                    let scheme = request.url?.scheme ?? "https"
                    let finalString = "\(scheme):\(sourceAndTitle.source.urlString)"
                    
                    guard let title = sourceAndTitle.title,
                        let url = URL(string: finalString) else {
                            return nil
                    }
                    
                    return MediaListItem(imageURL: url, imageTitle: title)
                    
                }.compactMap{ $0 }
                
                completion(.success(result))
            }
        }
    }
    
    @discardableResult func fetchOfflineResourceURLs(with request: URLRequest, completion: @escaping (Result<[URL], Error>) -> Void) -> URLSessionTask? {
        return trackedJSONDecodableTask(with: request) { (result: Result<[String]?, Error>, response) in
            if let statusCode = response?.statusCode,
                statusCode == 404 {
                completion(.failure(ArticleFetcherError.doesNotExist))
                return
            }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let urlStrings):
                
                guard let urlStrings = urlStrings else {
                    completion(.failure(ArticleFetcherError.missingData))
                    return
                }
                
                let result = urlStrings.map { (urlString) -> URL? in
                    let scheme = request.url?.scheme ?? "https"
                    let finalString = "\(scheme):\(urlString)"
                    return URL(string: finalString)
                }.compactMap{ $0 }
                
                completion(.success(result))
            }
            
        }
    }
    
    @discardableResult public func fetchMediaList(with request: URLRequest, completion: @escaping (Result<MediaList, Error>, HTTPURLResponse?) -> Void) -> URLSessionTask? {
        return trackedJSONDecodableTask(with: request) { (result: Result<MediaList?, Error>, response) in
            switch result {
            case .success(let result):
                guard let mediaList = result else {
                    completion(.failure(ArticleFetcherError.missingData), response)
                    return
                }
                
                completion(.success(mediaList), response)
                
            case .failure(let error):
                completion(.failure(error), response)
            }
        }
    }
    
    public func wikitextToMobileHTMLPreviewRequest(articleURL: URL, wikitext: String) throws -> URLRequest {
        guard
            let articleTitle = articleURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents,
            let url = configuration.pageContentServiceAPIURLComponentsForHost(articleURL.host, appending: ["transform", "wikitext", "to", "mobile-html", percentEncodedTitle]).url
        else {
            throw RequestError.invalidParameters
        }
        let params: [String: String] = ["wikitext": wikitext]
        let paramsJSON = try JSONEncoder().encode(params)
        var request = URLRequest(url: url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = paramsJSON
        request.httpMethod = "POST"
        return request
    }
    
    public func wikitextToHTMLRequest(articleURL: URL, wikitext: String, mobileHTMLOutput: MobileHTMLType) throws -> URLRequest {
        guard
            let articleTitle = articleURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents
        else {
            throw RequestError.invalidParameters
        }
        
        #if WMF_LOCAL_PAGE_CONTENT_SERVICE || WMF_APPS_LABS_PAGE_CONTENT_SERVICE
        // As of April 2020, the /transform/wikitext/to/html/{article} endpoint is only available on production, not local or staging PCS.
         guard let url = Configuration.production.pageContentServiceAPIURLComponentsForHost(articleURL.host, appending: ["transform", "wikitext", "to", "html", percentEncodedTitle]).url else {
             throw RequestError.invalidParameters
         }
         #else
         guard let url = configuration.pageContentServiceAPIURLComponentsForHost(articleURL.host, appending: ["transform", "wikitext", "to", "html", percentEncodedTitle]).url else {
            throw RequestError.invalidParameters
        }
         #endif

        let params: [String: String] = ["wikitext": wikitext]
        let headers = ["output-mode": mobileHTMLOutput.rawValue]
        return session.request(with: url, method: .post, bodyParameters: params, bodyEncoding: .json, headers: headers)
    }
    
    public func htmlToMobileHTMLRequest(articleURL: URL, html: String, mobileHTMLOutput: MobileHTMLType) throws -> URLRequest {
        guard
            let articleTitle = articleURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents,
            let url = configuration.pageContentServiceAPIURLComponentsForHost(articleURL.host, appending: ["transform", "html", "to", "mobile-html", percentEncodedTitle]).url
        else {
            throw RequestError.invalidParameters
        }

        let headers = ["output-mode": mobileHTMLOutput.rawValue]
        return session.request(with: url, method: .post, bodyParameters: html, bodyEncoding: .html, headers: headers)
    }

    public func wikitextToMobileHTMLRequest(articleURL: URL, wikitext: String, mobileHTMLOutput: MobileHTMLType = .contentAndReferences, completion: @escaping ((String?, URL?) -> Void)) throws {
        let mobileHtmlCompletionHandler = { (data: Data?, response: URLResponse?,  error: Error?) in
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(nil, nil)
                return
            }
            completion(html, response?.url)
        }
        let htmlRequestCompletionHandler = { (data: Data?, response: URLResponse?,  error: Error?) in
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(nil, nil)
                return
            }
            do {
                let mobileHtmlRequest = try self.htmlToMobileHTMLRequest(articleURL: articleURL, html: html, mobileHTMLOutput: mobileHTMLOutput)
                let mobileHtml = self.session.dataTask(with: mobileHtmlRequest, completionHandler: mobileHtmlCompletionHandler)
                mobileHtml?.resume()
            } catch {
                completion(nil, nil)
            }
        }
        let htmlRequest = try wikitextToHTMLRequest(articleURL: articleURL, wikitext: wikitext, mobileHTMLOutput: mobileHTMLOutput)
        let htmlTask = self.session.dataTask(with: htmlRequest, completionHandler: htmlRequestCompletionHandler)
        htmlTask?.resume()
    }
    
    public func mobileHTMLURL(articleURL: URL) throws -> URL {
        guard
            let articleTitle = articleURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents,
            let mobileHTMLURL = configuration.pageContentServiceAPIURLComponentsForHost(articleURL.host, appending: ["page", "mobile-html", percentEncodedTitle]).url
        else {
            throw RequestError.invalidParameters
        }
        
        return mobileHTMLURL
    }
    
    public func mediaListURL(articleURL: URL) throws -> URL {
        guard
            let articleTitle = articleURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents,
            let url = configuration.pageContentServiceAPIURLComponentsForHost(articleURL.host, appending: ["page", "media-list", percentEncodedTitle]).url
        else {
            throw RequestError.invalidParameters
        }
        
        return url
    }
    
    public func mobileHTMLMediaListRequest(articleURL: URL, cachePolicy: WMFCachePolicy? = nil) throws -> URLRequest {
        
        let url = try mediaListURL(articleURL: articleURL)
        
        if let urlRequest = urlRequest(from: url, cachePolicy: cachePolicy) {
            return urlRequest
        } else {
            throw ArticleFetcherError.unableToGenerateURLRequest
        }
    }
    
    public func mobileHTMLOfflineResourcesRequest(articleURL: URL, cachePolicy: WMFCachePolicy? = nil) throws -> URLRequest {
        guard
            let articleTitle = articleURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents,
            let url = configuration.pageContentServiceAPIURLComponentsForHost(articleURL.host, appending: ["page", "mobile-html-offline-resources", percentEncodedTitle]).url
        else {
            throw RequestError.invalidParameters
        }
        
        if let urlRequest = urlRequest(from: url, cachePolicy: cachePolicy) {
            return urlRequest
        } else {
            throw ArticleFetcherError.unableToGenerateURLRequest
        }
    }
    
    public func urlRequest(from url: URL, cachePolicy: WMFCachePolicy? = nil, headers: [String: String] = [:]) -> URLRequest? {
        
        let request = urlRequestFromPersistence(with: url, persistType: .article, cachePolicy: cachePolicy, headers: headers)
        
        return request
    }
    
    public func mobileHTMLRequest(articleURL: URL, scheme: String? = nil, cachePolicy: WMFCachePolicy? = nil) throws -> URLRequest {
        
        var url = try mobileHTMLURL(articleURL: articleURL)
        
        if let scheme = scheme {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.scheme = scheme
            url = urlComponents?.url ?? url
        }
        let acceptUTF8HTML = ["Accept": "text/html; charset=utf-8"]
        if let urlRequest = urlRequest(from: url, cachePolicy: cachePolicy, headers: acceptUTF8HTML) {
            return urlRequest
        } else {
            throw ArticleFetcherError.unableToGenerateURLRequest
        }
    }
    
    public func isCached(articleURL: URL, scheme: String? = nil, completion: @escaping (Bool) -> Void) {

        guard let request = try? mobileHTMLRequest(articleURL: articleURL, scheme: scheme) else {
            completion(false)
            return
        }
        
        return session.isCachedWithURLRequest(request, completion: completion)
    }
    
    //MARK: Bundled offline resources
    
    struct BundledOfflineResources {
        let baseCSS: URL
        let pcsCSS: URL
        let pcsJS: URL
    }
    
    let expectedNumberOfBundledOfflineResources = 3
    
    #if WMF_APPS_LABS_PAGE_CONTENT_SERVICE
     static let pcsBaseURI = "//\(Configuration.Domain.appsLabs)/api/v1/"
    #elseif WMF_LOCAL_PAGE_CONTENT_SERVICE
     static let pcsBaseURI = "//\(Configuration.Domain.localhost):8888/api/v1/"
    #else
     static let pcsBaseURI = "//\(Configuration.Domain.metaWiki)/api/rest_v1/"
    #endif
    
    func bundledOfflineResourceURLs() -> BundledOfflineResources? {
        guard
            let baseCSS = URL(string: "https:\(ArticleFetcher.pcsBaseURI)data/css/mobile/base"),
            let pcsCSS = URL(string: "https:\(ArticleFetcher.pcsBaseURI)data/css/mobile/pcs"),
            let pcsJS = URL(string: "https:\(ArticleFetcher.pcsBaseURI)data/javascript/mobile/pcs")
        else {
            return nil
        }
        return BundledOfflineResources(baseCSS: baseCSS, pcsCSS: pcsCSS, pcsJS: pcsJS)
    }
}
