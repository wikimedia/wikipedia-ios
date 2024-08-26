import WebKit

enum SchemeHandlerError: Error {
    case invalidParameters
    case createHTTPURLResponseFailure
    case unexpectedResponse
    
    public var errorDescription: String? {
         return CommonStrings.genericErrorDescription
    }
}

class SchemeHandler: NSObject {
    let scheme: String
    open var didReceiveDataCallback: ((WKURLSchemeTask, Data) -> Void)?
    private let session: Session
    private var activeSessionTasks: [URLRequest: URLSessionTask] = [:]
    private var activeCacheOperations: [URLRequest: Operation] = [:]
    private var activeSchemeTasks = NSMutableSet(array: [])
    
    private let cacheQueue: OperationQueue = OperationQueue()
    private let pageLoadMeasurementUrlString = "page/mobile-html/"
    
    var imageDidSuccessfullyLoad: (() -> Void)?
    
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
        
        switch Configuration.current.environment {
        case .local(let options):
            if options.contains(.localPCS) {
                components.scheme = components.host == Configuration.Domain.localhost ? "http" : "https"
            } else {
                components.scheme =  "https"
            }
        default:
            components.scheme =  "https"
        }
        
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
        var mutableRequest = originalRequest
        mutableRequest.url = newURL
        
        // set persistentCacheItemType in header if it doesn't already exist
        // set If-None-Match in header if it doesn't already exist
        
        let containsType = mutableRequest.allHTTPHeaderFields?[Header.persistentCacheItemType] != nil
        let containsIfNoneMatch = mutableRequest.allHTTPHeaderFields?[URLRequest.ifNoneMatchHeaderKey] != nil

        if !containsType {
            
            let typeHeaders: [String: String]
            if isMimeTypeImage(type: (newURL as NSURL).wmf_mimeTypeForExtension()) {
                typeHeaders = session.typeHeadersForType(.image)
            } else {
                typeHeaders = session.typeHeadersForType(.article)
            }
            
            for (key, value) in typeHeaders {
                mutableRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        guard !containsIfNoneMatch else {
            return mutableRequest
        }

        let additionalHeaders: [String: String]
        if isMimeTypeImage(type: (newURL as NSURL).wmf_mimeTypeForExtension()) {
            additionalHeaders = session.additionalHeadersForType(.image, urlRequest: mutableRequest)
        } else {
            additionalHeaders = session.additionalHeadersForType(.article, urlRequest: mutableRequest)
        }
        
        for (key, value) in additionalHeaders {
            mutableRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        return mutableRequest
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
        
        if ((urlSchemeTask.request.url?.absoluteString) ?? "").contains(pageLoadMeasurementUrlString) {
            SessionsFunnel.shared.setPageLoadStartTime()
        }
        
        let isImage = request.value(forHTTPHeaderField: Header.persistentCacheItemType) == Header.PersistItemType.image.rawValue
        
        let callback = Session.Callback(response: {  [weak urlSchemeTask] response in
            DispatchQueue.main.async {
                guard let urlSchemeTask = urlSchemeTask else {
                    return
                }
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, !HTTPStatusCode.isSuccessful(httpResponse.statusCode) {
                    let error = RequestError.from(code: httpResponse.statusCode)
                    self.removeSessionTask(request: urlSchemeTask.request)
                    urlSchemeTask.didFailWithError(error)
                    self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                    
                    if ((urlSchemeTask.request.url?.absoluteString) ?? "").contains(self.pageLoadMeasurementUrlString) {
                        SessionsFunnel.shared.clearPageLoadStartTime()
                    }
                } else {
                    
                    // May fix potential crashes if we have already called urlSchemeTask.didFinish() or webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) has already been called.
                    // https://developer.apple.com/documentation/webkit/wkurlschemetask/2890839-didreceive
                    guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                        return
                    }
                    
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
                self.didReceiveDataCallback?(urlSchemeTask, data)
            }
        }, success: { [weak urlSchemeTask, weak self] usedPermanentCache in
            
            guard let self else {
                return
            }
            
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
                
                if ((urlSchemeTask.request.url?.absoluteString) ?? "").contains(self.pageLoadMeasurementUrlString) {
                    
                    // To reduce inaccurate load times, do not consider load time if we had to lean on our local permanent cache (i.e. Saved Articles)
                    if usedPermanentCache {
                        SessionsFunnel.shared.clearPageLoadStartTime()
                    } else {
                        SessionsFunnel.shared.endPageLoadStartTime()
                    }
                }
                
                if isImage {
                    self.imageDidSuccessfullyLoad?()
                }
            }
            
        }, failure: { [weak urlSchemeTask] error in
            
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
                
                if ((urlSchemeTask.request.url?.absoluteString) ?? "").contains(self.pageLoadMeasurementUrlString) {
                    SessionsFunnel.shared.clearPageLoadStartTime()
                }
            }
            
        }, cacheFallbackError: { error in
            DispatchQueue.main.async {
                WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: false)
            }
        })
        
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
