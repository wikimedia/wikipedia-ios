
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
    
    @objc public static let shared = SchemeHandler(scheme: "app", session: Session.shared)
    
    required init(scheme: String, session: Session) {
        self.scheme = scheme
        self.session = session
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
        
        guard
            let requestURL = components.url,
            let request = urlRequestWithoutCustomScheme(from: originalRequest, newURL: requestURL)
        else {
            urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
            return
        }
        
        addSchemeTask(urlSchemeTask: urlSchemeTask)

        // IMPORTANT: Ensure the urlSchemeTask is not strongly captured by this block operation
        // Otherwise it will sometimes be deallocated on a non-main thread, causing a crash https://phabricator.wikimedia.org/T224113
        let op = BlockOperation { [weak urlSchemeTask] in
            DispatchQueue.main.async {
                guard let urlSchemeTask = urlSchemeTask else {
                    return
                }
                self.activeCacheOperations.removeValue(forKey: urlSchemeTask.request)
                self.kickOffDataTask(request: request, urlSchemeTask: urlSchemeTask)
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
    
    func urlRequestWithoutCustomScheme(from originalRequest: URLRequest, newURL: URL) -> URLRequest? {
        guard let mutableRequest = (originalRequest as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return nil
        }
        
        mutableRequest.url = newURL
        
        let maybeRequest = mutableRequest.copy() as? URLRequest
        
        //set persistentCacheItemType in header if it doesn't already exist
        //set If-None-Match in header if it doesn't already exist
        
        let containsType = mutableRequest.allHTTPHeaderFields?[Header.persistentCacheItemType] != nil
        let containsIfNoneMatch = mutableRequest.allHTTPHeaderFields?[URLRequest.ifNoneMatchHeaderKey] != nil

        if var request = maybeRequest {

            if !containsType {
                
                let typeHeaders: [String: String]
                if isMimeTypeImage(type: (newURL as NSURL).wmf_mimeTypeForExtension()) {
                    typeHeaders = session.typeHeadersForType(.image)
                } else {
                    typeHeaders = session.typeHeadersForType(.article)
                }
                
                for (key, value) in typeHeaders {
                    request.setValue(value, forHTTPHeaderField: key)
                }
            }
            
            guard !containsIfNoneMatch else {
                return request
            }

            let additionalHeaders: [String: String]
            if isMimeTypeImage(type: (newURL as NSURL).wmf_mimeTypeForExtension()) {
                additionalHeaders = session.additionalHeadersForType(.image, urlRequest: request)
            } else {
                additionalHeaders = session.additionalHeadersForType(.article, urlRequest: request)
            }
            
            for (key, value) in additionalHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            return request
        }

        return maybeRequest
    }
    
    func isMimeTypeImage(type: String) -> Bool {
        return type.hasPrefix("image")
    }
    
    func kickOffDataTask(request: URLRequest, urlSchemeTask: WKURLSchemeTask) {
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
                    let error = RequestError.from(code: httpResponse.statusCode)
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
        
        if let dataTask = session.dataTask(with: request, callback: callback) {
            addSessionTask(request: request, dataTask: dataTask)
            dataTask.resume()
        }
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
