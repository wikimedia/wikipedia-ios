
import UIKit

enum ArticleFetcherError: Error {
    case doesNotExist
    case failureToGenerateURL
    case missingData
    case invalidEndpointType
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
    
    private let cacheHeaderProvider: CacheHeaderProviding = ArticleCacheHeaderProvider()
    
    public enum EndpointType: String {
        case summary
        case mediaList = "media-list"
        case mobileHtmlOfflineResources = "mobile-html-offline-resources"
        case mobileHTML = "mobile-html"
        case references = "references"
    }
    
    @discardableResult func fetchResourceList(with request: URLRequest, endpointType: EndpointType, completion: @escaping (Result<[URL], Error>) -> Void) -> URLSessionTask? {
        
        guard endpointType == .mediaList || endpointType == .mobileHtmlOfflineResources else {
            completion(.failure(ArticleFetcherError.invalidEndpointType))
            return nil
        }
        
        switch endpointType {
        case .mediaList:
            return fetchMediaListURLs(with: request, completion: completion)
        case .mobileHtmlOfflineResources:
            return fetchOfflineResourceURLs(with: request, completion: completion)
        default:
            break
        }
        
        return nil
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
    
    public func mobileHTMLMediaListRequest(articleURL: URL, forceCache: Bool = false) throws -> URLRequest {
        guard
            let articleTitle = articleURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents,
            let url = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(articleURL.host, appending: ["page", "mobile-html-media-list", percentEncodedTitle]).url
        else {
            throw RequestError.invalidParameters
        }
        var request = URLRequest(url: url)
        let header = cacheHeaderProvider.requestHeader(urlRequest: request)
        
        for (key, value) in header {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if forceCache {
            request.cachePolicy = .returnCacheDataElseLoad
        }
        
        return request
    }
    
    public func mobileHTMLOfflineResourcesRequest(articleURL: URL, forceCache: Bool = false) throws -> URLRequest {
        guard
            let articleTitle = articleURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents,
            let url = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(articleURL.host, appending: ["page", "mobile-html-offline-resources", percentEncodedTitle]).url
        else {
            throw RequestError.invalidParameters
        }
        
        return urlRequest(from: url, forceCache: forceCache)
    }
    
    public func urlRequest(from url: URL, forceCache: Bool = false) -> URLRequest {
        
        var request = URLRequest(url: url)
        let header = cacheHeaderProvider.requestHeader(urlRequest: request)
        
        for (key, value) in header {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if forceCache {
            request.cachePolicy = .returnCacheDataElseLoad
        }
        
        return request
    }
    
    public func mobileHTMLRequest(articleURL: URL, forceCache: Bool = false, scheme: String? = nil) throws -> URLRequest {
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
        
        var request = URLRequest(url: mobileHTMLURL)
        let header = cacheHeaderProvider.requestHeader(urlRequest: request)
        
        for (key, value) in header {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if forceCache {
            request.cachePolicy = .returnCacheDataElseLoad
        }
        
        return request
    }
}

private extension ArticleFetcher {
    
    func fetchOfflineResourceURLs(with request: URLRequest, completion: @escaping (Result<[URL], Error>) -> Void) -> URLSessionTask? {
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
    
    @discardableResult func performPageContentServiceGET<T: Decodable>(with request: URLRequest, endpointType: EndpointType, completion: @escaping (Result<T, Error>, HTTPURLResponse?) -> Void) -> URLSessionTask? {
        
        return performMobileAppsServicesGET(for: request) { (result: T?, response, error) in
            guard let result = result else {
                completion(.failure(error ?? RequestError.unexpectedResponse), response as? HTTPURLResponse)
                return
            }
            completion(.success(result), response as? HTTPURLResponse)
        }
    }
    
    @discardableResult func fetchMediaListURLs(with request: URLRequest, completion: @escaping (Result<[URL], Error>) -> Void) -> URLSessionTask? {
        return fetchMediaList(with: request) { (result, response) in
            if let statusCode = response?.statusCode,
               statusCode == 404 {
               completion(.failure(ArticleFetcherError.doesNotExist))
               return
            }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let mediaList):
                let sources = mediaList.items.flatMap { (item) -> [MediaListItemSource] in
                    return item.sources ?? []
                }
                
                let result = sources.map { (source) -> URL? in
                    let scheme = request.url?.scheme ?? "https"
                    let finalString = "\(scheme):\(source.urlString)"
                    return URL(string: finalString)
                }.compactMap{ $0 }
                
                completion(.success(result))
            }
        }
    }
}
