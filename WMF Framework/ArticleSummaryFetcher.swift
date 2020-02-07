import Foundation

@objc(WMFArticleSummaryImage)
class ArticleSummaryImage: NSObject, Codable {
    let source: String
    let width: Int
    let height: Int
    var url: URL? {
        return URL(string: source)
    }
}

@objc(WMFArticleSummaryURLs)
class ArticleSummaryURLs: NSObject, Codable {
    let page: String?
    let revisions: String?
    let edit: String?
    let talk: String?
}

@objc(WMFArticleSummaryContentURLs)
class ArticleSummaryContentURLs: NSObject, Codable {
    let desktop: ArticleSummaryURLs?
    let mobile: ArticleSummaryURLs?
}

@objc(WMFArticleSummaryCoordinates)
class ArticleSummaryCoordinates: NSObject, Codable {
    @objc let lat: Double
    @objc let lon: Double
}

@objc(WMFArticleSummary)
public class ArticleSummary: NSObject, Codable {
    @objc public class Namespace: NSObject, Codable {
        let id: Int?
        let text: String?

        @objc public var number: NSNumber? {
            guard let id = id else {
                return nil
            }
            return NSNumber(value: id)
        }
    }
    let id: Int64?
    let revision: String?
    let timestamp: String?
    let index: Int?
    @objc let namespace: Namespace?
    let title: String?
    let displayTitle: String?
    let articleDescription: String?
    let extract: String?
    let extractHTML: String?
    let thumbnail: ArticleSummaryImage?
    let original: ArticleSummaryImage?
    @objc let coordinates: ArticleSummaryCoordinates?
    
    enum CodingKeys: String, CodingKey {
        case id = "pageid"
        case revision
        case index
        case namespace
        case title
        case timestamp
        case displayTitle = "displaytitle"
        case articleDescription = "description"
        case extract
        case extractHTML = "extract_html"
        case thumbnail
        case original = "originalimage"
        case coordinates
        case contentURLs = "content_urls"
    }
    
    let contentURLs: ArticleSummaryContentURLs
    
    var articleURL: URL? {
        guard let urlString = contentURLs.desktop?.page else {
            return nil
        }
        return URL(string: urlString)
    }
    
    var key: String? {
        return articleURL?.wmf_databaseKey // don't use contentURLs.desktop?.page directly as it needs to be standardized
    }
}


@objc(WMFArticleSummaryFetcher)
public class ArticleSummaryFetcher: Fetcher {
    @discardableResult public func fetchArticleSummaryResponsesForArticles(withKeys articleKeys: [String], priority: Float = URLSessionTask.defaultPriority, completion: @escaping ([String: ArticleSummary]) -> Void) -> [URLSessionTask] {
        
        var tasks: [URLSessionTask] = []
        articleKeys.asyncMapToDictionary(block: { (articleKey, asyncMapCompletion) in
            let task = fetchSummaryForArticle(with: articleKey, priority: priority, completion: { (responseObject, response, error) in
                asyncMapCompletion(articleKey, responseObject)
            })
            if let task = task {
                tasks.append(task)
            }
        }, completion: completion)
        
        return tasks
    }
    
    @objc(fetchSummaryForArticleWithKey:priority:completion:)
    @discardableResult public func fetchSummaryForArticle(with articleKey: String, priority: Float = URLSessionTask.defaultPriority, completion: @escaping (ArticleSummary?, URLResponse?, Error?) -> Swift.Void) -> URLSessionTask? {
        guard
            let articleURL = URL(string: articleKey),
            let title = articleURL.percentEncodedPageTitleForPathComponents
        else {
            completion(nil, nil, Fetcher.invalidParametersError)
            return nil
        }
        
        let pathComponents = ["page", "summary", title]
        return performMobileAppsServicesGET(for: articleURL, pathComponents: pathComponents, priority: priority) { (summary: ArticleSummary?, response: URLResponse?, error: Error?) in
            completion(summary, response, error)
        }
    }
}

