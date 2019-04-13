import Foundation

protocol FileHandlerCacheDelegate: class {
    func cachedResponse(for path: String) -> CachedURLResponse?
    func cacheResponse(_ response: URLResponse, data: Data?, for path: String)
}

extension SchemeHandler {
    final class FileHandler: BaseSubHandler {
        
        override class var basePath: String {
            return "fileProxy"
        }
        weak var cacheDelegate: FileHandlerCacheDelegate?
        
        required init(cacheDelegate: FileHandlerCacheDelegate) {
            self.cacheDelegate = cacheDelegate
        }
        
        func handle(pathComponents: [String], requestUrl: URL, completion: (URLResponse?, Data?, Error?) -> Void) {
            //todo: defensive checks around this
            let localPathComponents = pathComponents[2..<(pathComponents.count - 2)]
            let relativePath = NSString.path(withComponents: Array(localPathComponents))
            
            let notFoundResponse = HTTPURLResponse(url: requestUrl, statusCode: 404, httpVersion: nil, headerFields: nil)
            
            guard !relativePath.contains("..") else {
                if let notFoundResponse = notFoundResponse {
                    completion(notFoundResponse, nil, nil)
                }
                return
            }
            
            if let cachedResponse = cacheDelegate?.cachedResponse(for: relativePath) {
                completion(cachedResponse.response, cachedResponse.data, nil)
                return
            }
            
            let hostedFolderPath = WikipediaAppUtils.assetsPath()
            let fullPath = (hostedFolderPath as NSString).appendingPathComponent(relativePath)
            let localFileUrl = NSURL.init(fileURLWithPath: fullPath)
            
            let resourceValueForKey: (URLResourceKey) -> NSNumber? = { key in
                var value: AnyObject? = nil
                try? localFileUrl.getResourceValue(&value, forKey: key)
                return value as? NSNumber
            }
            
            guard let isRegularFile = resourceValueForKey(URLResourceKey.isRegularFileKey)?.boolValue, isRegularFile else {
                if let notFoundResponse = notFoundResponse {
                    completion(notFoundResponse, nil, nil)
                }
                return
            }
            
            let data = try? Data(contentsOf: localFileUrl as URL)
            var headerFields = Dictionary<String, String>.init(minimumCapacity: 1)
            let types = ["css": "text/css; charset=utf-8",
                         "html": "text/html; charset=utf-8",
                         "js": "application/javascript; charset=utf-8"
            ]
            if let pathExtension = localFileUrl.pathExtension {
                headerFields["Content-Type"] = types[pathExtension]
            }
            if let response = HTTPURLResponse(url: requestUrl, statusCode: 200, httpVersion: nil, headerFields: headerFields) {
                cacheDelegate?.cacheResponse(response, data: data, for: relativePath)
                completion(response, data, nil)
            } else {
                completion(nil, nil, SchemeHandlerError.createHTTPURLResponseFailure)
                return
            }
        }
    }
}
