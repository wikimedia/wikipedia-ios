
import Foundation

final class ImageFetcher: Fetcher {
    
    typealias RequestURL = URL
    typealias TemporaryFileURL = URL
    typealias MIMEType = String
    typealias DownloadCompletion = (Error?, RequestURL?, URLResponse?, TemporaryFileURL?, MIMEType?) -> Void
    
    private let cacheHeaderProvider: CacheHeaderProviding
    
    init(session: Session = Session.shared, configuration: Configuration = Configuration.current, cacheController: CacheController) {
        self.cacheHeaderProvider = cacheController.headerProvider
        super.init(session: session, configuration: configuration)
    }
    
    @objc required public init(session: Session, configuration: Configuration) {
        fatalError("init(session:configuration:) has not been implemented")
    }
    
    func downloadData(url: URL, completion: @escaping DownloadCompletion) -> URLSessionTask? {
        let task = session.downloadTask(with: url) { fileURL, response, error in
            self.handleDownloadTaskCompletion(url: url, fileURL: fileURL, response: response, error: error, completion: completion)
        }
        
        task.resume()
        return task
    }
    
    func request(for url: URL, forceCache: Bool = false) -> URLRequest {

        var request = URLRequest(url: url)
        let header = cacheHeaderProvider.requestHeader(url: url, forceCache: forceCache)
        
        for (key, value) in header {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
}

private extension ImageFetcher {
    
    //tonitodo: track/untrack tasks
    func handleDownloadTaskCompletion(url: URL, fileURL: URL?, response: URLResponse?, error: Error?, completion: @escaping DownloadCompletion) {
        if let error = error {
            completion(error, url, response, nil, nil)
            return
        }
        guard let fileURL = fileURL, let unwrappedResponse = response else {
            completion(Fetcher.unexpectedResponseError, url, response, nil, nil)
            return
        }
        if let httpResponse = unwrappedResponse as? HTTPURLResponse, (httpResponse.statusCode != 200 && httpResponse.statusCode != 304) {
            completion(Fetcher.unexpectedResponseError, url, response, nil, nil)
            return
        }
        completion(nil, url, response, fileURL, unwrappedResponse.mimeType)
    }
}
