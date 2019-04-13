import Foundation

protocol ArticleSectionHandlerCacheDelegate: class {
    func article(for key: String) -> MWKArticle?
    func cacheSectionData(for article: MWKArticle)
}


extension SchemeHandler {
    final class ArticleSectionHandler: BaseSubHandler {
        
        weak var cacheDelegate: ArticleSectionHandlerCacheDelegate?
        
        required init(cacheDelegate: ArticleSectionHandlerCacheDelegate) {
            self.cacheDelegate = cacheDelegate
        }
        
        override class var basePath: String? {
            return "articleSectionData"
        }
        private var basePath: String? {
            return ArticleSectionHandler.basePath
        }
        
        static let articleKeyQueryItemName = "articleKey"
        static let imageWidthQueryItemName = "imageWidth"
        
        static func appSchemeUrl(for articleUrl: URL, targetImageWidth: Int) -> URL? {
            guard let key = articleUrl.wmf_articleDatabaseKey,
                let basePath = basePath else {
                    return nil
            }
            
            var components = baseUrlComponents
            components.path = NSString.path(withComponents: ["/", basePath])
            
            let articleKeyQueryItem = URLQueryItem(name: articleKeyQueryItemName, value: key)
            let imageWidthString = String(format: "%lli", targetImageWidth)
            let imageWidthQueryItem = URLQueryItem(name: imageWidthQueryItemName, value: imageWidthString)
            components.queryItems = [articleKeyQueryItem, imageWidthQueryItem]
            return components.url
        }
        
        func handle(pathComponents: [String], requestUrl: URL, completion: (URLResponse?, Data?, Error?) -> Void) {
            guard let articleKey = (requestUrl as NSURL).wmf_value(forQueryKey: ArticleSectionHandler.articleKeyQueryItemName) else {
                completion(nil, nil, SchemeHandlerError.invalidParameters)
                return
            }
            
            guard let article = cacheDelegate?.article(for: articleKey) else {
                completion(nil, nil, SchemeHandlerError.invalidParameters)
                return
            }
            
            guard let imageWidthString = (requestUrl as NSURL).wmf_value(forQueryKey: ArticleSectionHandler.imageWidthQueryItemName),
                (imageWidthString as NSString).integerValue > 0 else {
                    completion(nil, nil, SchemeHandlerError.invalidParameters)
                    return
            }
            
            let imageWidth = (imageWidthString as NSString).integerValue
            guard let json = WMFArticleJSONCompilationHelper.jsonData(for: article, withImageWidth: imageWidth) else {
                completion(nil, nil, SchemeHandlerError.invalidParameters)
                return
            }
            
            let response = HTTPURLResponse(url: requestUrl, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json; charset=utf-8"])
            completion(response, json, nil)
        }
    }
}
