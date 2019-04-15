
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
                    self.activeSchemeTasks.remove(urlSchemeTask)
                    return
                }
                
                if let error = error {
                    urlSchemeTask.didFailWithError(error)
                    self.activeSchemeTasks.remove(urlSchemeTask)
                    return
                }
                
                if let response = response {
                    urlSchemeTask.didReceive(response)
                }
                
                if let data = data {
                    urlSchemeTask.didReceive(data)
                }
                urlSchemeTask.didFinish()
                self.activeSchemeTasks.remove(urlSchemeTask)
            }
        }
        
        activeSchemeTasks.add(urlSchemeTask)
        
        DispatchQueue.global(qos: .default).async {
        
            switch baseComponent {
            case FileHandler.basePath:
                self.fileHandler.handle(pathComponents: pathComponents, requestURL: requestURL, completion: localCompletionBlock)
            case ArticleSectionHandler.basePath:
                self.articleSectionHandler.handle(pathComponents: pathComponents, requestURL: requestURL, completion: localCompletionBlock)
            case APIHandler.basePath:
                
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                
                guard let apiURL = self.apiHandler.urlForPathComponents(pathComponents, requestURL: requestURL) else {
                    DispatchQueue.main.async {
                        urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
                        self.activeSchemeTasks.remove(urlSchemeTask)
                    }
                    return
                }
                
                self.kickOffDataTask(handler: self.apiHandler, url: apiURL, urlSchemeTask: urlSchemeTask)
               
            default:
                
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                
                guard let defaultURL = self.defaultHandler.urlForPathComponents(pathComponents, requestURL: requestURL) else {
                    DispatchQueue.main.async {
                        urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
                        self.activeSchemeTasks.remove(urlSchemeTask)
                    }
                    return
                }
                
                if let cachedResponse = self.defaultHandler.cachedResponseForURL(defaultURL) {
                    DispatchQueue.main.async {
                        urlSchemeTask.didReceive(cachedResponse.response)
                        urlSchemeTask.didReceive(cachedResponse.data)
                        urlSchemeTask.didFinish()
                        self.activeSchemeTasks.remove(urlSchemeTask)
                    }
                    return
                }
                
                self.kickOffDataTask(handler: self.defaultHandler, url: defaultURL, urlSchemeTask: urlSchemeTask)
            }
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread)
        guard let task = self.activeSessionTasks[urlSchemeTask.request] else {
            return
        }
        if task.state == .running {
            task.cancel()
        }
        self.activeSessionTasks.removeValue(forKey: urlSchemeTask.request)
        activeSchemeTasks.remove(urlSchemeTask)
    }
}

private extension SchemeHandler {
    func kickOffDataTask(handler: RemoteSubHandler, url: URL, urlSchemeTask: WKURLSchemeTask) {
        
        let callback = Session.Callback(response: { task, response in
            DispatchQueue.main.async {
                
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    let error = RequestError.from(code: httpResponse.statusCode) ?? .unknown
                    task.cancel()
                    self.activeSessionTasks.removeValue(forKey: urlSchemeTask.request)
                    urlSchemeTask.didFailWithError(error)
                    self.activeSchemeTasks.remove(urlSchemeTask)
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
                self.activeSessionTasks.removeValue(forKey: urlSchemeTask.request)
                self.activeSchemeTasks.remove(urlSchemeTask)
            }
        }) { task, error in
            DispatchQueue.main.async {
                
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                
                task.cancel()
                self.activeSessionTasks.removeValue(forKey: urlSchemeTask.request)
                urlSchemeTask.didFailWithError(error)
                self.activeSchemeTasks.remove(urlSchemeTask)
            }
        }
        
        DispatchQueue.main.async {
            guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                return
            }
            
            let dataTask = handler.dataTaskForURL(url, callback: callback)
            self.activeSessionTasks[urlSchemeTask.request] = dataTask
            dataTask.resume()
        }
    }
    
    func schemeTaskIsActive(urlSchemeTask: WKURLSchemeTask) -> Bool {
        var isActive: Bool = false
        
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                isActive = self.activeSchemeTasks.contains(urlSchemeTask)
            }
        } else {
            isActive = self.activeSchemeTasks.contains(urlSchemeTask)
        }
        
        return isActive
    }
}
