
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
    var taskQueue: DispatchQueue = DispatchQueue(label: "SchemeHandlerTaskQueue", qos: .default, attributes: [.concurrent], autoreleaseFrequency: .workItem, target: nil)
    
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
            
            guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                return
            }
            
            if response == nil && error == nil {
                DispatchQueue.main.async {
                    urlSchemeTask.didFailWithError(SchemeHandlerError.unexpectedResponse)
                }
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                return
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    urlSchemeTask.didFailWithError(error)
                }
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                return
            }
        
            DispatchQueue.main.async {
                if let response = response {
                    urlSchemeTask.didReceive(response)
                }
                
                if let data = data {
                    urlSchemeTask.didReceive(data)
                }
                urlSchemeTask.didFinish()
            }
            self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
        }
        
        addSchemeTask(urlSchemeTask: urlSchemeTask)
        
        DispatchQueue.global(qos: .userInitiated).async {
        
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
                    }
                    self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                    return
                }
                
                if let cachedResponse = self.defaultHandler.cachedResponseForURL(defaultURL) {
                    DispatchQueue.main.async {
                        urlSchemeTask.didReceive(cachedResponse.response)
                        urlSchemeTask.didReceive(cachedResponse.data)
                        urlSchemeTask.didFinish()
                    }
                    self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                    return
                }
                
                self.kickOffDataTask(handler: self.defaultHandler, url: defaultURL, urlSchemeTask: urlSchemeTask)
            }
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        taskQueue.async(flags: .barrier) {
            guard let task = self.activeSessionTasks[urlSchemeTask.request] else {
                return
            }
            if task.state == .running {
                task.cancel()
            }
            self.activeSessionTasks.removeValue(forKey: urlSchemeTask.request)
            self.activeSchemeTasks.remove(urlSchemeTask)
        }
    }
}

private extension SchemeHandler {
    func kickOffDataTask(handler: RemoteSubHandler, url: URL, urlSchemeTask: WKURLSchemeTask) {
        
        let callback = Session.Callback(response: { task, response in
                
            guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let error = RequestError.from(code: httpResponse.statusCode) ?? .unknown
                task.cancel()
                self.removeSessionTask(request: urlSchemeTask.request)
                DispatchQueue.main.async {
                    urlSchemeTask.didFailWithError(error)
                }
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
            } else {
                DispatchQueue.main.async {
                    urlSchemeTask.didReceive(response)
                }
            }
        }, data: { data in
            
            guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                return
            }
            DispatchQueue.main.async {
                urlSchemeTask.didReceive(data)
            }
        }, success: {
            
            guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                return
            }
            
            DispatchQueue.main.async {
                urlSchemeTask.didFinish()
            }
            self.removeSessionTask(request: urlSchemeTask.request)
            self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
            
        }) { task, error in
                
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                
                task.cancel()
                self.removeSessionTask(request: urlSchemeTask.request)
                DispatchQueue.main.async {
                    urlSchemeTask.didFailWithError(error)
                }
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
        }
            guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                return
            }
            
            let dataTask = handler.dataTaskForURL(url, callback: callback)
            self.addSessionTask(request: urlSchemeTask.request, dataTask: dataTask)
            dataTask.resume()
    }
    
    func schemeTaskIsActive(urlSchemeTask: WKURLSchemeTask) -> Bool {
        var isActive = false
        taskQueue.sync {
            isActive = self.activeSchemeTasks.contains(urlSchemeTask)
        }
        return isActive
    }
    
    func removeSchemeTask(urlSchemeTask: WKURLSchemeTask) {
        taskQueue.async(flags: .barrier) {
            self.activeSchemeTasks.remove(urlSchemeTask)
        }
    }
    
    func removeSessionTask(request: URLRequest) {
        taskQueue.async(flags: .barrier) {
            self.activeSessionTasks.removeValue(forKey: request)
        }
    }
    
    func addSchemeTask(urlSchemeTask: WKURLSchemeTask) {
        taskQueue.async(flags: .barrier) {
            self.activeSchemeTasks.add(urlSchemeTask)
        }
    }
    
    func addSessionTask(request: URLRequest, dataTask: URLSessionTask) {
        taskQueue.async(flags: .barrier) {
            self.activeSessionTasks[request] = dataTask
        }
    }
}
