
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
        #if WMF_APPS_LABS_MOBILE_HTML
        super.init(session: Session.shared, configuration: Configuration.appsLabs)
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
        return performPageContentServiceGET(with: request, endpointType: .mobileHtmlOfflineResources, completion: { (result: Result<[String]?, Error>, response) in
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
            
        })
    }
    
    @discardableResult public func fetchMediaList(with request: URLRequest, completion: @escaping (Result<MediaList, Error>, HTTPURLResponse?) -> Void) -> URLSessionTask? {
        return performPageContentServiceGET(with: request, endpointType: .mediaList, completion: { (result: Result<MediaList?, Error>, response) in
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
        })
    }
    
    public func mobileHTMLPreviewRequest(articleURL: URL, wikitext: String) throws -> URLRequest {
        guard
            let articleTitle = articleURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents,
            let url = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(articleURL.host, appending: ["transform", "wikitext", "to", "mobile-html", percentEncodedTitle]).url
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
    
    public func mobileHTMLMediaListRequest(articleURL: URL, cachePolicy: URLRequest.CachePolicy? = nil) throws -> URLRequest {
        guard
            let articleTitle = articleURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents,
            let url = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(articleURL.host, appending: ["page", "media-list", percentEncodedTitle]).url
        else {
            throw RequestError.invalidParameters
        }
        
        if let urlRequest = urlRequest(from: url, cachePolicy: cachePolicy) {
            return urlRequest
        } else {
            throw ArticleFetcherError.unableToGenerateURLRequest
        }
    }
    
    public func mobileHTMLOfflineResourcesRequest(articleURL: URL, cachePolicy: URLRequest.CachePolicy? = nil) throws -> URLRequest {
        guard
            let articleTitle = articleURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents,
            let url = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(articleURL.host, appending: ["page", "mobile-html-offline-resources", percentEncodedTitle]).url
        else {
            throw RequestError.invalidParameters
        }
        
        if let urlRequest = urlRequest(from: url, cachePolicy: cachePolicy) {
            return urlRequest
        } else {
            throw ArticleFetcherError.unableToGenerateURLRequest
        }
    }
    
    public func urlRequest(from url: URL, cachePolicy: URLRequest.CachePolicy? = nil) -> URLRequest? {
        
        let request = urlRequestFromURL(url, type: .article, cachePolicy: cachePolicy)
        
        return request
    }
    
    public func mobileHTMLRequest(articleURL: URL, scheme: String? = nil, cachePolicy: URLRequest.CachePolicy? = nil) throws -> URLRequest {
        guard
            let articleTitle = articleURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents,
            var mobileHTMLURL = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(articleURL.host, appending: ["page", "mobile-html", percentEncodedTitle]).url
        else {
            throw RequestError.invalidParameters
        }
        
        if let scheme = scheme {
            var urlComponents = URLComponents(url: mobileHTMLURL, resolvingAgainstBaseURL: false)
            urlComponents?.scheme = scheme
            mobileHTMLURL = urlComponents?.url ?? mobileHTMLURL
        }
        
        if let urlRequest = urlRequest(from: mobileHTMLURL, cachePolicy: cachePolicy) {
            return urlRequest
        } else {
            throw ArticleFetcherError.unableToGenerateURLRequest
        }
    }
    
    public func isCached(articleURL: URL, scheme: String? = nil) -> Bool {

        guard let request = try? mobileHTMLRequest(articleURL: articleURL, scheme: scheme) else {
            return false
        }
        
        return session.isCachedWithURLRequest(request)
    }
    
    //MARK: Bundled offline resources
    
    struct BundledOfflineResources {
        let baseCSS: URL
        let pcsCSS: URL
        let pcsJS: URL
    }
    
    let expectedNumberOfBundledOfflineResources = 3
    
    func bundledOfflineResourceURLs() -> BundledOfflineResources? {

        #if WMF_APPS_LABS_MOBILE_HTML

            guard let baseCSS = URL(string: "https://apps.wmflabs.org/api/v1/data/css/mobile/base"),
                let pcsCSS = URL(string: "https://apps.wmflabs.org/api/v1/data/css/mobile/pcs"),
                let pcsJS = URL(string: "https://apps.wmflabs.org/api/v1/data/javascript/mobile/pcs") else {
                    return nil
            }

            return BundledOfflineResources(baseCSS: baseCSS, pcsCSS: pcsCSS, pcsJS: pcsJS)
        #else

           guard let baseCSS = URL(string: "https://meta.wikimedia.org/api/v1/data/css/mobile/base"),
                let pcsCSS = URL(string: "https://meta.wikimedia.org/api/v1/data/css/mobile/pcs"),
                let pcsJS = URL(string: "https://meta.wikimedia.org/api/v1/data/javascript/mobile/pcs") else {
                    return nil
            }

            return BundledOfflineResources(baseCSS: baseCSS, pcsCSS: pcsCSS, pcsJS: pcsJS)

        #endif
    }
}

private extension ArticleFetcher {
    
    @discardableResult func performPageContentServiceGET<T: Decodable>(with request: URLRequest, endpointType: EndpointType, completion: @escaping (Result<T, Error>, HTTPURLResponse?) -> Void) -> URLSessionTask? {
        
        return performMobileAppsServicesGET(for: request) { (result: T?, response, error) in
            guard let result = result else {
                completion(.failure(error ?? RequestError.unexpectedResponse), response as? HTTPURLResponse)
                return
            }
            completion(.success(result), response as? HTTPURLResponse)
        }
    }

}
