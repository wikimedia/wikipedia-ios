
import WebKit

enum SchemeHandlerError: Error {
    case invalidParameters
    case createHTTPURLResponseFailure
    case unexpectedResponse
    
    public var errorDescription: String? {
         return CommonStrings.genericErrorDescription
    }
}

final class SchemeHandler: NSObject {
    @objc let scheme: String
    private let session: Session
    private var tasks: [URLRequest: URLSessionTask] = [:]
    private var queue: DispatchQueue = DispatchQueue(label: "SchemeHandlerQueue", qos: .default, attributes: [.concurrent], autoreleaseFrequency: .workItem, target: nil)
    
    private let cache: SchemeHandlerCache
    private let fileHandler: FileHandler
    private let articleSectionHandler: ArticleSectionHandler
    private let apiHandler: APIHandler
    private let defaultHandler: DefaultHandler
    
    @objc public static let shared = SchemeHandler(scheme: WMFURLSchemeHandlerScheme, session: Session.shared)
    
    required init(scheme: String, session: Session) {
        self.scheme = scheme
        self.session = session
        let cache = SchemeHandlerCache()
        self.cache = cache
        self.fileHandler = FileHandler(cacheDelegate: cache)
        self.articleSectionHandler = ArticleSectionHandler(cacheDelegate: cache)
        self.apiHandler = APIHandler(session: session)
        self.defaultHandler = DefaultHandler(session: session)
    }
   
    func setResponseData(data: Data?, contentType: String?, path: String, requestURL: URL) {
        var headerFields = [String: String](minimumCapacity: 1)
        if let contentType = contentType {
            headerFields["Content-Type"] = contentType
        }
        if let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: headerFields) {
            cache.cacheResponse(response, data: data, path: path)
        }
    }
    
    @objc(cacheSectionDataForArticle:)
    func cacheSectionData(for article: MWKArticle) {
        cache.cacheSectionData(for: article)
    }
}

extension SchemeHandler: WKURLSchemeHandler {
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        var request = urlSchemeTask.request
        guard let requestURL = request.url else {
            urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
            return
        }
        guard let components = NSURLComponents(url: requestURL, resolvingAgainstBaseURL: false) else {
            urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
            return
        }
        #if WMF_LOCAL
        components.scheme = components.host == "localhost" ? "http" : "https"
        #else
        components.scheme =  "https"
        #endif
        guard let pathComponents = (components.path as NSString?)?.pathComponents,
            pathComponents.count >= 2 else {
            urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
            return
        }
        
        let baseComponent = pathComponents[1]
        
        let localCompletionBlock: (URLResponse?, Data?, Error?) -> Void = { (response, data, error) in
            
            if response == nil && error == nil {
                urlSchemeTask.didFailWithError(SchemeHandlerError.unexpectedResponse)
                return
            }
            
            if let error = error {
                urlSchemeTask.didFailWithError(error)
                return
            }
            
            if let response = response {
                urlSchemeTask.didReceive(response)
            }
            
            if let data = data {
                urlSchemeTask.didReceive(data)
            }
            urlSchemeTask.didFinish()
        }
        
        switch baseComponent {
        case FileHandler.basePath:
            fileHandler.handle(pathComponents: pathComponents, requestURL: requestURL, completion: localCompletionBlock)
            
        case ArticleSectionHandler.basePath:
            articleSectionHandler.handle(pathComponents: pathComponents, requestURL: requestURL, completion: localCompletionBlock)
        case APIHandler.basePath:
            
            guard let apiURL = apiHandler.urlForPathComponents(pathComponents, requestURL: requestURL) else {
                urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
                return
            }
            
            kickOffDataTask(handler: apiHandler, url: apiURL, urlSchemeTask: urlSchemeTask)
           
        default:
            
            guard let defaultURL = defaultHandler.urlForPathComponents(pathComponents, requestURL: requestURL) else {
                urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
                return
            }
            
            if let cachedResponse = defaultHandler.cachedResponseForURL(defaultURL) {
                urlSchemeTask.didReceive(cachedResponse.response)
                urlSchemeTask.didReceive(cachedResponse.data)
                urlSchemeTask.didFinish()
                return
            }
            
            kickOffDataTask(handler: defaultHandler, url: defaultURL, urlSchemeTask: urlSchemeTask)
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        queue.async(flags: .barrier) {
            guard let task = self.tasks[urlSchemeTask.request] else {
                return
            }
            if task.state == .running {
                task.cancel()
            }
            self.tasks.removeValue(forKey: urlSchemeTask.request)
        }
    }
}

private extension SchemeHandler {
    func kickOffDataTask(handler: RemoteSubHandler, url: URL, urlSchemeTask: WKURLSchemeTask) {
        
        let callback = Session.Callback(response: { task, response in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let error = RequestError.from(code: httpResponse.statusCode) ?? .unknown
                task.cancel()
                urlSchemeTask.didFailWithError(error)
            } else {
                urlSchemeTask.didReceive(response)
            }
        }, data: { data in
            urlSchemeTask.didReceive(data)
        }, success: {
            urlSchemeTask.didFinish()
        }) { task, error in
            task.cancel()
            urlSchemeTask.didFailWithError(error)
        }
        
        let dataTask = handler.dataTaskForURL(url, callback: callback)
        self.queue.async(flags: .barrier) {
            self.tasks[urlSchemeTask.request] = dataTask
        }
        dataTask.resume()
    }
}
