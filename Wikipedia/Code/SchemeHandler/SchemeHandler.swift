
import WebKit

enum SchemeHandlerError: Error {
    case invalidParameters
    case createHTTPURLResponseFailure
    case handlerValidationFailure
    
    var localizedDescription: String {
        return NSLocalizedString("An unexpected error has occurred.", comment: "¯\\_(ツ)_/¯")
    }
}

class SchemeHandler: NSObject {
    @objc let scheme: String
    let session: Session
    var tasks: [URLRequest: URLSessionTask] = [:]
    var queue: DispatchQueue = DispatchQueue(label: "SchemeHandlerQueue", qos: .default, attributes: [.concurrent], autoreleaseFrequency: .workItem, target: nil)
    
    private let schemeHandlerCache: SchemeHandlerCache
    private let fileHandler: FileHandler
    private let articleSectionHandler: ArticleSectionHandler
    private let apiHandler: APIHandler
    private let defaultHandler: DefaultHandler
    
    //todo: take out singletons?
    @objc public static let shared = SchemeHandler(scheme: SchemeHandler.defaultScheme, session: Session.shared)
    @objc static let defaultScheme = "wmfapp"
    
    required init(scheme: String, session: Session) {
        self.scheme = scheme
        self.session = session
        let schemeHandlerCache = SchemeHandlerCache()
        self.schemeHandlerCache = schemeHandlerCache
        self.fileHandler = FileHandler(cacheDelegate: schemeHandlerCache)
        self.articleSectionHandler = ArticleSectionHandler(cacheDelegate: schemeHandlerCache)
        self.apiHandler = APIHandler(session: session)
        self.defaultHandler = DefaultHandler(session: session)
    }
   
    func setResponseData(data: Data?, contentType: String?, path: String, requestURL: URL) {
        var headerFields = Dictionary<String, String>.init(minimumCapacity: 1)
        if let contentType = contentType {
            headerFields["Content-Type"] = contentType
        }
        if let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: headerFields) {
            schemeHandlerCache.cacheResponse(response, data: data, for: path)
        }
    }
    
    //todo: better objc name
    @objc func cacheSectionData(for article: MWKArticle) {
        schemeHandlerCache.cacheSectionData(for: article)
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
            pathComponents.count >= 2,
            let url = components.url else { //todo: understand when we should pass in url vs requestURL
            urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
            return
        }
        
        let baseComponent = pathComponents[1]
        
        //------local resource dry closures
        let localCompletionBlock: (URLResponse?, Data?, Error?) -> Void = { (response, data, error) in
            
            if response == nil && error == nil {
                urlSchemeTask.didFailWithError(SchemeHandlerError.handlerValidationFailure)
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
        
        //------remote resource dry closures
        
        let evaluationBlock: (((error: Error?, task: URLSessionTask?)) -> Void) = { (evaluation) in
            //todo: handle if both error and task are nil
            if let error = evaluation.error {
                urlSchemeTask.didFailWithError(error)
                return
            }
            
            if let task = evaluation.task {
                self.queue.async(flags: .barrier) {
                    self.tasks[urlSchemeTask.request] = task
                }
                task.resume()
            }
        }
        
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
        
        switch baseComponent {
        case FileHandler.basePath:
            fileHandler.handle(pathComponents: pathComponents, requestUrl: requestURL, completion: localCompletionBlock)
            
        case ArticleSectionHandler.basePath:
            articleSectionHandler.handle(pathComponents: pathComponents, requestUrl: requestURL, completion: localCompletionBlock)
        case APIHandler.basePath:
            let evaluation = apiHandler.dataTaskForPathComponents(pathComponents, requestUrl: requestURL, callback: callback)
            
            evaluationBlock(evaluation)
           
        default:
            
            let evaluation = defaultHandler.dataTaskForPathComponents(pathComponents, requestUrl: requestURL, cachedCompletionHandler: { (response, data) in
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
            }, callback: callback)
            
            evaluationBlock(evaluation)
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


