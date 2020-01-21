
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
    private var activeCacheOperations: [URLRequest: Operation] = [:]
    private var activeSchemeTasks = NSMutableSet(array: [])
    
    private let fileCache: SchemeHandlerCache
    private let fileHandler: FileHandler
    private let defaultHandler: DefaultHandler
    private let cacheQueue: OperationQueue = OperationQueue()
    
    private let requestToResponseQueue = DispatchQueue(label: "com.wikimedia.schemeHandler.response")
    private var requestToResponse: [URLRequest: URLResponse] = [:]
    
    var cacheController: CacheController?
    var cachePolicy: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData //needed so we see a 304 to act on
    
    @objc public static let shared = SchemeHandler(scheme: WMFURLSchemeHandlerScheme, session: Session.shared)
    
    required init(scheme: String, session: Session) {
        self.scheme = scheme
        self.session = session
        let cache = SchemeHandlerCache()
        self.fileCache = cache
        self.fileHandler = FileHandler(cacheDelegate: cache)
        self.defaultHandler = DefaultHandler(session: session)
    }
    
    func setResponseData(data: Data?, contentType: String?, path: String, requestURL: URL) {
        var headerFields = [String: String](minimumCapacity: 1)
        if let contentType = contentType {
            headerFields["Content-Type"] = contentType
        }
        if let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: headerFields) {
            fileCache.cacheResponse(response, data: data, path: path)
        }
    }
}

extension SchemeHandler: WKURLSchemeHandler {
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread)
        
        let originalRequest = urlSchemeTask.request
        guard let originalRequestURL = originalRequest.url else {
            urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
            return
        }
        guard let components = NSURLComponents(url: originalRequestURL, resolvingAgainstBaseURL: false) else {
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
            fileHandler.handle(pathComponents: pathComponents, requestURL: originalRequestURL, completion: localCompletionBlock)
            
        default:
            
            guard let requestURL = defaultHandler.urlForPathComponents(pathComponents, requestURL: originalRequestURL),
                let request = cacheController?.newCachePolicyRequest(from: originalRequest as NSURLRequest, newURL: requestURL, cachePolicy: cachePolicy) else {
                    urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
                    removeSchemeTask(urlSchemeTask: urlSchemeTask)
                    return
            }
            
            // IMPORTANT: Ensure the urlSchemeTask is not strongly captured by this block operation
            // Otherwise it will sometimes be deallocated on a non-main thread, causing a crash https://phabricator.wikimedia.org/T224113
            let op = BlockOperation { [weak urlSchemeTask] in
                if self.cachePolicy == .returnCacheDataDontLoad {
                    DispatchQueue.main.async {
                        
                        guard let urlSchemeTask = urlSchemeTask else {
                            return
                        }
                        
                        self.activeCacheOperations.removeValue(forKey: urlSchemeTask.request)
                        
                        if let cachedResponse = self.cacheController?.cachedURLResponse(for: request) {
                            urlSchemeTask.didReceive(cachedResponse.response)
                            urlSchemeTask.didReceive(cachedResponse.data)
                        }
                        
                        urlSchemeTask.didFinish()
                        self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    guard let urlSchemeTask = urlSchemeTask else {
                        return
                    }
                    self.activeCacheOperations.removeValue(forKey: urlSchemeTask.request)
                    self.kickOffDataTask(handler: self.defaultHandler, request: request, urlSchemeTask: urlSchemeTask)
                }
            }
            activeCacheOperations[urlSchemeTask.request] = op
            cacheQueue.addOperation(op)
        }
        
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread)
        
        removeSchemeTask(urlSchemeTask: urlSchemeTask)
        
        if let task = activeSessionTasks[urlSchemeTask.request] {
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
        
        if let op = activeCacheOperations.removeValue(forKey: urlSchemeTask.request) {
            op.cancel()
        }
    }
}

private extension SchemeHandler {
    func kickOffDataTask(handler: RemoteSubHandler, request: URLRequest, urlSchemeTask: WKURLSchemeTask) {
        guard schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
            return
        }
       
        // IMPORTANT: Ensure the urlSchemeTask is not strongly captured by the callback blocks.
        // Otherwise it will sometimes be deallocated on a non-main thread, causing a crash https://phabricator.wikimedia.org/T224113
        let callback = Session.Callback(response: {  [weak urlSchemeTask] response in
            DispatchQueue.main.async {
                guard let urlSchemeTask = urlSchemeTask else {
                    return
                }
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                
                print("🚵🏻‍♂️\((response as? HTTPURLResponse)?.allHeaderFields)")
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    
                    if httpResponse.statusCode == 304,
                        let cachedResponse = self.cacheController?.cachedURLResponse(for: request) {
                        urlSchemeTask.didReceive(response)
                        urlSchemeTask.didReceive(cachedResponse.data)
                    } else {
                        let error = RequestError.from(code: httpResponse.statusCode) ?? .unknown
                        self.removeSessionTask(request: urlSchemeTask.request)
                        urlSchemeTask.didFailWithError(error)
                        self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                    }
                } else {
                    urlSchemeTask.didReceive(response)
                    self.mapResponseToRequest(request: request, response: response)
                }
            }
        }, data: { [weak urlSchemeTask] data in
            
            DispatchQueue.main.async {
                
                guard let urlSchemeTask = urlSchemeTask else {
                    return
                }
                
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                
                urlSchemeTask.didReceive(data)
                
                if let response = self.response(for: request) {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                }
            }
        }, success: { [weak urlSchemeTask] in
            DispatchQueue.main.async {
                guard let urlSchemeTask = urlSchemeTask else {
                    return
                }
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                urlSchemeTask.didFinish()
                self.removeSessionTask(request: urlSchemeTask.request)
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                self.removeMapResponseToRequest(request: request)
            }
        }) { [weak urlSchemeTask] error in
            
            if let cachedResponse = self.cacheController?.cachedURLResponseUponError(for: request) {
                DispatchQueue.main.async {
                    guard let urlSchemeTask = urlSchemeTask else {
                        return
                    }
                    self.activeCacheOperations.removeValue(forKey: urlSchemeTask.request)
                    urlSchemeTask.didReceive(cachedResponse.response)
                    urlSchemeTask.didReceive(cachedResponse.data)
                    urlSchemeTask.didFinish()
                    self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                    self.removeMapResponseToRequest(request: request)
                }
                return
            }
            
            DispatchQueue.main.async {
                
                guard let urlSchemeTask = urlSchemeTask else {
                    return
                }
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                self.removeSessionTask(request: urlSchemeTask.request)
                urlSchemeTask.didFailWithError(error)
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                self.removeMapResponseToRequest(request: request)
            }
        }
        
        let dataTask = handler.dataTaskForRequest(request, callback: callback)
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
    
    func mapResponseToRequest(request: URLRequest, response: URLResponse) {
        requestToResponseQueue.async { [weak self] in
            self?.requestToResponse[request] = response
            
        }
    }
    
    func response(for request: URLRequest) -> URLResponse? {
        requestToResponseQueue.sync {
            return self.requestToResponse[request]
        }
    }
    
    func removeMapResponseToRequest(request: URLRequest) {
        requestToResponseQueue.async { [weak self] in
            self?.requestToResponse.removeValue(forKey: request)
        }
    }
}
