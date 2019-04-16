import Foundation

protocol FileHandlerCacheDelegate: class {
    func cachedResponse(for path: String) -> CachedURLResponse?
    func cacheResponse(_ response: URLResponse, data: Data?, path: String)
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
        
        func handle(pathComponents: [String], requestURL: URL, completion: @escaping (URLResponse?, Data?, Error?) -> Void) {
            DispatchQueue.global(qos: .userInitiated).async {
                guard pathComponents.count >= 2 else {
                    completion(nil, nil, SchemeHandlerError.invalidParameters)
                    return
                }
                
                let localPathComponents = pathComponents[2..<(pathComponents.count)]
                let relativePath = NSString.path(withComponents: Array(localPathComponents))
                
                let notFoundResponse = HTTPURLResponse(url: requestURL, statusCode: 404, httpVersion: nil, headerFields: nil)
                
                guard !relativePath.contains("..") else {
                    if let notFoundResponse = notFoundResponse {
                        completion(notFoundResponse, nil, nil)
                    }
                    return
                }
                
                if let cachedResponse = self.cacheDelegate?.cachedResponse(for: relativePath) {
                    completion(cachedResponse.response, cachedResponse.data, nil)
                    return
                }
                
                let hostedFolderPath = WikipediaAppUtils.assetsPath()
                let fullPath = (hostedFolderPath as NSString).appendingPathComponent(relativePath)
                let localFileURL = NSURL.init(fileURLWithPath: fullPath)
                
                let resourceValueForKey: (URLResourceKey) -> NSNumber? = { key in
                    var value: AnyObject? = nil
                    try? localFileURL.getResourceValue(&value, forKey: key)
                    return value as? NSNumber
                }
                
                guard let isRegularFile = resourceValueForKey(URLResourceKey.isRegularFileKey)?.boolValue, isRegularFile else {
                    if let notFoundResponse = notFoundResponse {
                        completion(notFoundResponse, nil, nil)
                    }
                    return
                }
                
                let data = try? Data(contentsOf: localFileURL as URL)
                var headerFields = [String: String](minimumCapacity: 1)
                let types = ["css": "text/css; charset=utf-8",
                             "html": "text/html; charset=utf-8",
                             "js": "application/javascript; charset=utf-8"
                ]
                if let pathExtension = localFileURL.pathExtension {
                    headerFields["Content-Type"] = types[pathExtension]
                }
                if let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: headerFields) {
                    self.cacheDelegate?.cacheResponse(response, data: data, path: relativePath)
                    completion(response, data, nil)
                } else {
                    completion(nil, nil, SchemeHandlerError.createHTTPURLResponseFailure)
                }
            }
        }
    }
}
