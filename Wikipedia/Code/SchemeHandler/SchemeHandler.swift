
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
    private var activeSessionTasks: [URLRequest: URLSessionTask] = [:]
    private var activeSchemeTasks = NSMutableSet(array: [])
    
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
        assert(Thread.isMainThread)
        
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
            DispatchQueue.main.async {
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                
                if response == nil && error == nil {
                    urlSchemeTask.didFailWithError(SchemeHandlerError.unexpectedResponse)
                    self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                    return
                }
                
                if let error = error {
                    urlSchemeTask.didFailWithError(error)
                    self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                    return
                }
            
                if let response = response {
                    urlSchemeTask.didReceive(response)
                }
                
                if let data = data {
                    urlSchemeTask.didReceive(data)
                }
                urlSchemeTask.didFinish()
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
            }
        }
        
        addSchemeTask(urlSchemeTask: urlSchemeTask)
        
        switch baseComponent {
        case FileHandler.basePath:
            fileHandler.handle(pathComponents: pathComponents, requestURL: requestURL, completion: localCompletionBlock)
        case ArticleSectionHandler.basePath:
            articleSectionHandler.handle(pathComponents: pathComponents, requestURL: requestURL, completion: localCompletionBlock)
        case APIHandler.basePath:
            guard let apiURL = apiHandler.urlForPathComponents(pathComponents, requestURL: requestURL) else {
                 urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
                removeSchemeTask(urlSchemeTask: urlSchemeTask)
                return
            }
            kickOffDataTask(handler: apiHandler, url: apiURL, urlSchemeTask: urlSchemeTask)
        default:
            guard let defaultURL = defaultHandler.urlForPathComponents(pathComponents, requestURL: requestURL) else {
                urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
                removeSchemeTask(urlSchemeTask: urlSchemeTask)
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                if let cachedResponse = self.defaultHandler.cachedResponseForURL(defaultURL) {
                    DispatchQueue.main.async {
                        urlSchemeTask.didReceive(cachedResponse.response)
                        urlSchemeTask.didReceive(cachedResponse.data)
                        urlSchemeTask.didFinish()
                        self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.kickOffDataTask(handler: self.defaultHandler, url: defaultURL, urlSchemeTask: urlSchemeTask)
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread)
        
        removeSchemeTask(urlSchemeTask: urlSchemeTask)
        
        guard let task = activeSessionTasks[urlSchemeTask.request] else {
            return
        }
        
        removeSessionTask(request: urlSchemeTask.request)
        
        switch task.state {
        case .canceling:
            fallthrough
        case .completed:
            break
        default:
            task.cancel()
        }
    }
}

private extension SchemeHandler {
    func kickOffDataTask(handler: RemoteSubHandler, url: URL, urlSchemeTask: WKURLSchemeTask) {
        guard schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
            return
        }
        
        let callback = Session.Callback(response: {  response in
            DispatchQueue.main.async {
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    let error = RequestError.from(code: httpResponse.statusCode) ?? .unknown
                    self.removeSessionTask(request: urlSchemeTask.request)
                    urlSchemeTask.didFailWithError(error)
                    self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                } else {
                    urlSchemeTask.didReceive(response)
                }
            }
        }, data: { data in
            DispatchQueue.main.async {
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                urlSchemeTask.didReceive(data)
            }
        }, success: {
            DispatchQueue.main.async {
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                urlSchemeTask.didFinish()
                self.removeSessionTask(request: urlSchemeTask.request)
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
            }
        }) { error in
            DispatchQueue.main.async {
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                self.removeSessionTask(request: urlSchemeTask.request)
                urlSchemeTask.didFailWithError(error)
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
            }
        }
        
        let dataTask = handler.dataTaskForURL(url, callback: callback)
        addSessionTask(request: urlSchemeTask.request, dataTask: dataTask)
        dataTask.resume()
    }
    
    func schemeTaskIsActive(urlSchemeTask: WKURLSchemeTask) -> Bool {
        assert(Thread.isMainThread)
        return activeSchemeTasks.contains(urlSchemeTask)
    }
    
    func removeSchemeTask(urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread)
        activeSchemeTasks.remove(urlSchemeTask)
    }
    
    func removeSessionTask(request: URLRequest) {
        assert(Thread.isMainThread)
        activeSessionTasks.removeValue(forKey: request)
    }
    
    func addSchemeTask(urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread)
        activeSchemeTasks.add(urlSchemeTask)
    }
    
    func addSessionTask(request: URLRequest, dataTask: URLSessionTask) {
        assert(Thread.isMainThread)
        activeSessionTasks[request] = dataTask
    }
}
