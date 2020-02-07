
import UIKit

enum ArticleFetcherError: Error {
    case doesNotExist
    case failureToGenerateURL
    case missingData
    case invalidEndpointType
}

@objc(WMFArticleFetcher)
final public class ArticleFetcher: Fetcher {
    
    public enum EndpointType: String {
        case summary
        case mediaList = "media-list"
        case mobileHtmlOfflineResources = "mobile-html-offline-resources"
        case mobileHTML = "mobile-html"
        case references = "references"
    }
    
    typealias RequestURL = URL
    typealias TemporaryFileURL = URL
    typealias MIMEType = String
    typealias DownloadCompletion = (Error?, RequestURL?, URLResponse?, TemporaryFileURL?, MIMEType?) -> Void
    
    func downloadData(url: URL, completion: @escaping DownloadCompletion) -> URLSessionTask? {
        let task = session.downloadTask(with: url) { fileURL, response, error in
            self.handleDownloadTaskCompletion(url: url, fileURL: fileURL, response: response, error: error, completion: completion)
        }
        task.resume()
        return task
    }
    
    @discardableResult func fetchResourceList(with articleURL: URL, endpointType: EndpointType, completion: @escaping (Result<[URL], Error>) -> Void) -> URLSessionTask? {
        
        guard endpointType == .mediaList || endpointType == .mobileHtmlOfflineResources else {
            completion(.failure(ArticleFetcherError.invalidEndpointType))
            return nil
        }
        
        switch endpointType {
        case .mediaList:
            return fetchMediaListURLs(with: articleURL, completion: completion)
        case .mobileHtmlOfflineResources:
            return fetchOfflineResourceURLs(with: articleURL, completion: completion)
        default:
            break
        }
        
        return nil
    }
    
    @discardableResult public func fetchMediaList(with articleURL: URL, completion: @escaping (Result<MediaList, Error>, HTTPURLResponse?) -> Void) -> URLSessionTask? {
        return performPageContentServiceGET(with: articleURL, endpointType: .mediaList, completion: completion)
    }

    @discardableResult public func fetchReferences(with articleURL: URL, completion: @escaping (Result<References, Error>, HTTPURLResponse?) -> Void) -> URLSessionTask? {
        return performPageContentServiceGET(with: articleURL, endpointType: .references, completion: completion)
    }
}

private extension ArticleFetcher {
    
    func fetchOfflineResourceURLs(with articleURL: URL, completion: @escaping (Result<[URL], Error>) -> Void) -> URLSessionTask? {
        return performPageContentServiceGET(with: articleURL, endpointType: .mobileHtmlOfflineResources, completion: { (result: Result<[String], Error>, response) in
            if let statusCode = response?.statusCode,
                statusCode == 404 {
                completion(.failure(ArticleFetcherError.doesNotExist))
                return
            }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let urlStrings):
                let result = urlStrings.map { (urlString) -> URL? in
                    let scheme = articleURL.scheme ?? "https"
                    let finalString = "\(scheme):\(urlString)"
                    return URL(string: finalString)
                }.compactMap{ $0 }
                
                completion(.success(result))
            }
            
        })
    }
    
    
    @discardableResult func performPageContentServiceGET<T: Decodable>(with articleURL: URL, endpointType: EndpointType, completion: @escaping (Result<T, Error>, HTTPURLResponse?) -> Void) -> URLSessionTask? {
        guard let title = articleURL.percentEncodedPageTitleForPathComponents else {
            completion(.failure(RequestError.invalidParameters), nil)
            return nil
        }
        let components = ["page", endpointType.rawValue, title]
        return performMobileAppsServicesGET(for: articleURL, pathComponents: components) { (result: T?, response, error) in
            guard let result = result else {
                completion(.failure(error ?? RequestError.unexpectedResponse), response as? HTTPURLResponse)
                return
            }
            completion(.success(result), response as? HTTPURLResponse)
        }
    }
    
    @discardableResult func fetchMediaListURLs(with articleURL: URL, completion: @escaping (Result<[URL], Error>) -> Void) -> URLSessionTask? {
        return fetchMediaList(with: articleURL) { (result, response) in
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
                    let scheme = articleURL.scheme ?? "https"
                    let finalString = "\(scheme):\(source.urlString)"
                    return URL(string: finalString)
                }.compactMap{ $0 }
                
                completion(.success(result))
            }
           
        }
    }
    
    func handleDownloadTaskCompletion(url: URL, fileURL: URL?, response: URLResponse?, error: Error?, completion: @escaping DownloadCompletion) {
        if let error = error {
            completion(error, url, response, nil, nil)
            return
        }
        guard let fileURL = fileURL, let unwrappedResponse = response else {
            completion(Fetcher.unexpectedResponseError, url, response, nil, nil)
            return
        }
        if let httpResponse = unwrappedResponse as? HTTPURLResponse, httpResponse.statusCode != 200 {
            completion(Fetcher.unexpectedResponseError, url, response, nil, nil)
            return
        }
        completion(nil, url, response, fileURL, unwrappedResponse.mimeType)
    }
}
