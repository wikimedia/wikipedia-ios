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
        
        static let articleKeyQueryItemName = "articleKey"
        static let imageWidthQueryItemName = "imageWidth"
        
        static func appSchemeURL(for articleURL: URL, targetImageWidth: Int) -> URL? {
            guard let key = articleURL.wmf_articleDatabaseKey,
                let basePath = basePath else {
                    return nil
            }
            
            var components = baseURLComponents
            components.path = NSString.path(withComponents: ["/", basePath])
            
            let articleKeyQueryItem = URLQueryItem(name: articleKeyQueryItemName, value: key)
            let imageWidthString = String(format: "%lli", targetImageWidth)
            let imageWidthQueryItem = URLQueryItem(name: imageWidthQueryItemName, value: imageWidthString)
            components.queryItems = [articleKeyQueryItem, imageWidthQueryItem]
            return components.url
        }
        
        func handle(pathComponents: [String], requestURL: URL, completion: @escaping (URLResponse?, Data?, Error?) -> Void) {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let articleKey = (requestURL as NSURL).wmf_value(forQueryKey: ArticleSectionHandler.articleKeyQueryItemName) else {
                    completion(nil, nil, SchemeHandlerError.invalidParameters)
                    return
                }
                
                guard let article = self.cacheDelegate?.article(for: articleKey) else {
                    completion(nil, nil, SchemeHandlerError.invalidParameters)
                    return
                }
                
                guard let imageWidthString = (requestURL as NSURL).wmf_value(forQueryKey: ArticleSectionHandler.imageWidthQueryItemName),
                    (imageWidthString as NSString).integerValue > 0 else {
                        completion(nil, nil, SchemeHandlerError.invalidParameters)
                        return
                }
                
                let imageWidth = (imageWidthString as NSString).integerValue
                guard let json = WMFArticleJSONCompilationHelper.jsonData(for: article, withImageWidth: imageWidth) else {
                    completion(nil, nil, SchemeHandlerError.invalidParameters)
                    return
                }
                
                let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json; charset=utf-8"])
                completion(response, json, nil)
            }
        }
    }
}
