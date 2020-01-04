
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
    typealias DownloadCompletion = (Error?, RequestURL?, TemporaryFileURL?, MIMEType?) -> Void
    
    func fetchMobileHTML(articleURL: URL, completion: @escaping DownloadCompletion) {
        
        guard let taskURL = ArticleURLConverter.mobileHTMLURL(desktopURL: articleURL, endpointType: .mobileHTML, configuration: configuration) else {
            completion(ArticleFetcherError.failureToGenerateURL, nil, nil, nil)
            return
        }
        
        downloadData(url: taskURL, completion: completion)
    }
    
    func downloadData(url: URL, completion: @escaping DownloadCompletion) {
        let task = session.downloadTask(with: url) { fileURL, response, error in
            self.handleDownloadTaskCompletion(url: url, fileURL: fileURL, response: response, error: error, completion: completion)
        }
        task.resume()
    }
    
    //tonitodo: track/untrack tasks
    func fetchResourceList(siteURL: URL, articleTitle: String, endpointType: EndpointType, completion: @escaping (Result<[URL], Error>) -> Void) {
        
        guard endpointType == .mediaList || endpointType == .mobileHtmlOfflineResources else {
            completion(.failure(ArticleFetcherError.invalidEndpointType))
            return
        }
        
//        guard let taskURL = ArticleFetcher.getURL(siteURL: siteURL, articleTitle: articleTitle, endpointType: endpointType, configuration: configuration) else {
//            completion(.failure(ArticleFetcherError.failureToGenerateURL))
//            return
//        }
        
        guard let stagingTaskURL = ArticleURLConverter.mobileHTMLURL(siteURL: siteURL, articleTitle: articleTitle, endpointType: endpointType, configuration: configuration, scheme: "https") else {
                    completion(.failure(ArticleFetcherError.failureToGenerateURL))
                    return
                }
        
        switch endpointType {
        case .mediaList:
            fetchMediaListURLs(with: stagingTaskURL, siteURL: siteURL, completion: completion)
        case .mobileHtmlOfflineResources:
            fetchOfflineResourceURLs(with: stagingTaskURL, siteURL: siteURL, completion: completion)
        default:
            break
        }
    }
}

private extension ArticleFetcher {
    
    func fetchOfflineResourceURLs(with url: URL, siteURL: URL, completion: @escaping (Result<[URL], Error>) -> Void) {
        session.jsonDecodableTask(with: url) { (urlStrings: [String]?, response: URLResponse?, error: Error?) in
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
    
    func fetchMediaListURLs(with url: URL, siteURL: URL, completion: @escaping (Result<[URL], Error>) -> Void) {
        
        session.jsonDecodableTask(with: url) { (mediaList: MediaList?, response: URLResponse?, error: Error?) in
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
                return item.sources
            }
            
            let result = sources.map { (source) -> URL? in
                let scheme = siteURL.scheme ?? "https"
                let finalString = "\(scheme):\(source.urlString)"
                return URL(string: finalString)
            }.compactMap{ $0 }
            
            completion(.success(result))
        }
    }
    
    //tonitodo: track/untrack tasks
    func handleDownloadTaskCompletion(url: URL, fileURL: URL?, response: URLResponse?, error: Error?, completion: @escaping DownloadCompletion) {
        if let error = error {
            completion(error, url, nil, nil)
            return
        }
        guard let fileURL = fileURL, let response = response else {
            completion(Fetcher.unexpectedResponseError, url, nil, nil)
            return
        }
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            completion(Fetcher.unexpectedResponseError, url, nil, nil)
            return
        }
        completion(nil, url, fileURL, response.mimeType)
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

fileprivate enum MediaListItemType: String, Codable {
    case image
}

fileprivate struct MediaListItem: Codable {
    let title: String
    let sectionID: Int
    let itemType: MediaListItemType
    let showInGallery: Bool
    let sources: [MediaListItemSource]
    
    enum CodingKeys: String, CodingKey {
        case title
        case sectionID = "section_id"
        case itemType = "type"
        case showInGallery
        case sources = "srcset"
    }
}

fileprivate struct MediaList: Codable {
    let items: [MediaListItem]
}
