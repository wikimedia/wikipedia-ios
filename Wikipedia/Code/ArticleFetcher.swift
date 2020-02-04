
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
    
    enum ImageScale: String {
        case x1 = "1x"
        case x1_5 = "1.5x"
        case x2 = "2x"
        
        init(with screenScale: CGFloat) {
            switch screenScale {
            case 3.0:
                self = .x2
            case 2.0:
                self = .x1_5
            default:
                self = .x1
            }
        }
        
        //let scaledSources = sources.filter { $0.scale == Scale.init(with: UIScreen.main.scale).rawValue }
    }
    
    struct ImageResult {
        let url: URL
        let variantId: String
        let variantGroupKey: String
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
    
    func fetchOfflineResourceURLs(siteURL: URL, articleTitle: String, completion: @escaping (Result<[URL], Error>) -> Void) -> URLSessionTask? {
        
        guard let stagingTaskURL = ArticleURLConverter.mobileHTMLURL(siteURL: siteURL, articleTitle: articleTitle, endpointType: .mobileHtmlOfflineResources, configuration: configuration, scheme: "https") else {
                    completion(.failure(ArticleFetcherError.failureToGenerateURL))
                    return nil
                }
        
        return session.jsonDecodableTask(with: stagingTaskURL) { (urlStrings: [String]?, response: URLResponse?, error: Error?) in
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
    
    func fetchMediaListURLs(siteURL: URL, articleTitle: String, completion: @escaping (Result<[ImageResult], Error>) -> Void) -> URLSessionTask? {
        
        guard let stagingTaskURL = ArticleURLConverter.mobileHTMLURL(siteURL: siteURL, articleTitle: articleTitle, endpointType: .mediaList, configuration: configuration, scheme: "https") else {
                    completion(.failure(ArticleFetcherError.failureToGenerateURL))
                    return nil
                }
        
        return session.jsonDecodableTask(with: stagingTaskURL) { (mediaList: MediaList?, response: URLResponse?, error: Error?) in
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
            
            var results: [ImageResult] = []
            for item in mediaList.items {
                let title = item.title
                
                guard let sources = item.sources else {
                    break
                }
                
                let innerResults = sources.map { (source) -> ImageResult? in
                    let scheme = siteURL.scheme ?? "https"
                    let finalString = "\(scheme):\(source.urlString)"
                    
                    if let url = URL(string: finalString) {
                        return ImageResult(url: url, variantId: source.scale, variantGroupKey: title)
                    }
                    
                    return nil
                }.compactMap { $0 }
                
                results.append(contentsOf: innerResults)
            }
            
            completion(.success(results))
        }
    }
}

private extension ArticleFetcher {
    
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
