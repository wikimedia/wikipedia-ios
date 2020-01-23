
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
    let scheme: String
    private let session: Session
    private var activeSessionTasks: [URLRequest: URLSessionTask] = [:]
    private var activeCacheOperations: [URLRequest: Operation] = [:]
    private var activeSchemeTasks = NSMutableSet(array: [])
    
    private let cacheQueue: OperationQueue = OperationQueue()
    var articleCacheController: CacheController?
    
    @objc public static let shared = SchemeHandler(scheme: "app", session: Session.shared)
    
    required init(scheme: String, session: Session) {
        self.scheme = scheme
        self.session = session
    }
}

extension SchemeHandler: WKURLSchemeHandler {
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread)
        
        let request = urlSchemeTask.request
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
        
        guard let defaultURL = components.url else {
            urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
            return
        }
        
        addSchemeTask(urlSchemeTask: urlSchemeTask)

        // IMPORTANT: Ensure the urlSchemeTask is not strongly captured by this block operation
        // Otherwise it will sometimes be deallocated on a non-main thread, causing a crash https://phabricator.wikimedia.org/T224113
        let op = BlockOperation { [weak urlSchemeTask] in
            if let cachedResponse = self.articleCacheController?.recentCachedURLResponse(for: defaultURL) {
                DispatchQueue.main.async {
                    guard let urlSchemeTask = urlSchemeTask else {
                        return
                    }
                    self.activeCacheOperations.removeValue(forKey: urlSchemeTask.request)
                    urlSchemeTask.didReceive(cachedResponse.response)
                    urlSchemeTask.didReceive(cachedResponse.data)
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
                self.kickOffDataTask(url: defaultURL, urlSchemeTask: urlSchemeTask)
            }
        }
        activeCacheOperations[urlSchemeTask.request] = op
        cacheQueue.addOperation(op)
        
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
    func kickOffDataTask(url: URL, urlSchemeTask: WKURLSchemeTask) {
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
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    let error = RequestError.from(code: httpResponse.statusCode) ?? .unknown
                    self.removeSessionTask(request: urlSchemeTask.request)
                    urlSchemeTask.didFailWithError(error)
                    self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
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
                urlSchemeTask.didFinish()
                self.removeSessionTask(request: urlSchemeTask.request)
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
            }
        }) { [weak urlSchemeTask] error in
            
            if let cachedResponse = self.articleCacheController?.persistedCachedURLResponse(for: url) {
                DispatchQueue.main.async {
                    guard let urlSchemeTask = urlSchemeTask else {
                        return
                    }
                    self.activeCacheOperations.removeValue(forKey: urlSchemeTask.request)
                    urlSchemeTask.didReceive(cachedResponse.response)
                    urlSchemeTask.didReceive(cachedResponse.data)
                    urlSchemeTask.didFinish()
                    self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
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
            }
        }
        
        let request = URLRequest(url: url)
        let dataTask = session.dataTask(with: request as URLRequest, callback: callback)
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
