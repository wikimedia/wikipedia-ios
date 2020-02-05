
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
    
    func fetchResourceList(siteURL: URL, articleTitle: String, endpointType: EndpointType, completion: @escaping (Result<[URL], Error>) -> Void) -> URLSessionTask? {
        
        guard endpointType == .mediaList || endpointType == .mobileHtmlOfflineResources else {
            completion(.failure(ArticleFetcherError.invalidEndpointType))
            return nil
        }
        
//        guard let taskURL = ArticleFetcher.getURL(siteURL: siteURL, articleTitle: articleTitle, endpointType: endpointType, configuration: configuration) else {
//            completion(.failure(ArticleFetcherError.failureToGenerateURL))
//            return
//        }
        
        guard let stagingTaskURL = ArticleURLConverter.mobileHTMLURL(siteURL: siteURL, articleTitle: articleTitle, endpointType: endpointType, configuration: configuration, scheme: "https") else {
                    completion(.failure(ArticleFetcherError.failureToGenerateURL))
                    return nil
                }
        
        switch endpointType {
        case .mediaList:
            return fetchMediaListURLs(with: stagingTaskURL, siteURL: siteURL, completion: completion)
        case .mobileHtmlOfflineResources:
            return fetchOfflineResourceURLs(with: stagingTaskURL, siteURL: siteURL, completion: completion)
        default:
            break
        }
        
        return nil
    }
}

private extension ArticleFetcher {
    
    func fetchOfflineResourceURLs(with url: URL, siteURL: URL, completion: @escaping (Result<[URL], Error>) -> Void) -> URLSessionTask? {
        return session.jsonDecodableTask(with: url) { (urlStrings: [String]?, response: URLResponse?, error: Error?) in
            if let statusCode = (response as? HTTPURLResponse)?.statusCode,
                statusCode == 404 {
                completion(.failure(ArticleFetcherError.doesNotExist))
                return
            }
            
            if let error = error {
               completion(.failure(error))
               return
           }
            
            guard let urlStrings = urlStrings else {
                completion(.failure(ArticleFetcherError.missingData))
                return
            }
            
            let result = urlStrings.map { (urlString) -> URL? in
                let scheme = siteURL.scheme ?? "https"
                let finalString = "\(scheme):\(urlString)"
                return URL(string: finalString)
            }.compactMap{ $0 }
            
            completion(.success(result))
        }
    }
    
    func fetchMediaListURLs(with url: URL, siteURL: URL, completion: @escaping (Result<[URL], Error>) -> Void) -> URLSessionTask? {
        
        return session.jsonDecodableTask(with: url) { (mediaList: MediaList?, response: URLResponse?, error: Error?) in
            if let statusCode = (response as? HTTPURLResponse)?.statusCode,
                statusCode == 404 {
                completion(.failure(ArticleFetcherError.doesNotExist))
                return
            }
            
            if let error = error {
               completion(.failure(error))
               return
           }
            
            guard let mediaList = mediaList else {
                completion(.failure(ArticleFetcherError.missingData))
                return
            }
            
            let sources = mediaList.items.flatMap { (item) -> [MediaListItemSource] in
                return item.sources ?? []
            }
            
            let result = sources.map { (source) -> URL? in
                let scheme = siteURL.scheme ?? "https"
                let finalString = "\(scheme):\(source.urlString)"
                return URL(string: finalString)
            }.compactMap{ $0 }
            
            completion(.success(result))
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

fileprivate struct MediaListItemSource: Codable {
    let urlString: String
    let scale: String
    
    enum CodingKeys: String, CodingKey {
        case urlString = "src"
        case scale
    }
}

fileprivate enum MediaListItemType: String {
    case image
    case audio
    case video
}

fileprivate struct MediaListItem: Codable {
    let title: String
    let sectionID: Int
    let type: String
    let showInGallery: Bool
    let sources: [MediaListItemSource]?
    let audioType: String?
    enum CodingKeys: String, CodingKey {
        case title
        case sectionID = "section_id"
        case showInGallery
        case sources = "srcset"
        case type
        case audioType
    }
}

extension MediaListItem {
    var itemType: MediaListItemType? {
        return MediaListItemType(rawValue: type)
    }
}

fileprivate struct MediaList: Codable {
    let items: [MediaListItem]
}
