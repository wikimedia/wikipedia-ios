
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
    
    private let notModifiedQueue = DispatchQueue(label: "org.wikimedia.schemeHandler.notModified")
    private var notModifiedRequests = Set<URLRequest>()
    
    var cacheController: CacheController?
    var forceCache: Bool = false
    
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
                let request = cacheController?.newCachePolicyRequest(from: originalRequest as NSURLRequest, newURL: requestURL) else {
                    urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
                    removeSchemeTask(urlSchemeTask: urlSchemeTask)
                    return
            }
            
            // IMPORTANT: Ensure the urlSchemeTask is not strongly captured by this block operation
            // Otherwise it will sometimes be deallocated on a non-main thread, causing a crash https://phabricator.wikimedia.org/T224113
            let op = BlockOperation { [weak urlSchemeTask] in
                
                //forceCache will be true for ArticleViewControllers when coming from Navigation State Controller. In this case stale data is fine.
                if self.forceCache {
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
  
        //tonitodo: delete if we stop seeming to need it.
//        let isReally304Response = {(request: URLRequest, response: HTTPURLResponse) -> Bool in
//
//            let emptyURLCache = URLCache.shared.cachedResponse(for: request) == nil
//            if let responseEtag = (response as HTTPURLResponse).allHeaderFields[HTTPURLResponse.etagHeaderKey] as? String,
//            let requestIfNoneMatch = request.allHTTPHeaderFields?[HTTPURLResponse.ifNoneMatchHeaderKey],
//            responseEtag == requestIfNoneMatch,
//                emptyURLCache == true {
//                return true
//            }
//
//            return false
//        }
        
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
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode != 200 {
                        
                        if httpResponse.statusCode == 304 {
                            urlSchemeTask.didReceive(response)
                            self.addNotModifiedRequest(request: request)
                        } else {
                            let error = RequestError.from(code: httpResponse.statusCode) ?? .unknown
                            urlSchemeTask.didFailWithError(error)
                            self.removeSessionTask(request: urlSchemeTask.request)
                            self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                        }
                        
                    } else {
                        
                        urlSchemeTask.didReceive(response)
                        
                        //Session sometimes change 304 statuses to 200, handling that case here
                        //tonitodo: delete if we don't seem to need
//                        if isReally304Response(request, httpResponse) {
//                            self.addNotModifiedRequest(request: request)
//                        }
//
                    }
                    
                } else {
                    
                    urlSchemeTask.didReceive(response)
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
            }
        }, success: { [weak urlSchemeTask] in
            DispatchQueue.main.async {
            
                guard let urlSchemeTask = urlSchemeTask else {
                    return
                }
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                
                if self.isNotModified(request: request) {
                    if let cachedResponse = self.cacheController?.cachedURLResponse(for: request) {
                        urlSchemeTask.didReceive(cachedResponse.data)
                    }
                    self.removeNotModifiedRequest(request: request)
                }
                
                urlSchemeTask.didFinish()
                self.removeSessionTask(request: urlSchemeTask.request)
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
            }
        }) { [weak urlSchemeTask] error in
            DispatchQueue.main.async {
                
                guard let urlSchemeTask = urlSchemeTask else {
                    return
                }
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                    
                if let cachedResponse = self.cacheController?.cachedURLResponse(for: request) {
                
                    urlSchemeTask.didReceive(cachedResponse.response)
                    urlSchemeTask.didReceive(cachedResponse.data)
                    
                    urlSchemeTask.didFinish()
                } else {
                    urlSchemeTask.didFailWithError(error)
                }
            
                self.removeSessionTask(request: urlSchemeTask.request)
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
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
    
    func addNotModifiedRequest(request: URLRequest) {
        notModifiedQueue.async { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self.notModifiedRequests.insert(request)
        }
    }
    
    func removeNotModifiedRequest(request: URLRequest) {
        notModifiedQueue.async { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self.notModifiedRequests.remove(request)
        }
    }
    
    func isNotModified(request: URLRequest) -> Bool {
        notModifiedQueue.sync {
            
            return notModifiedRequests.contains(request)
        }
    }
}
