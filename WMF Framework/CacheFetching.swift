
import Foundation

protocol CacheFetching {
    typealias TemporaryFileURL = URL
    typealias MIMEType = String
    typealias DownloadCompletion = (Error?, URLRequest?, URLResponse?, TemporaryFileURL?, MIMEType?) -> Void
    
    func downloadData(urlRequest: URLRequest, completion: @escaping DownloadCompletion) -> URLSessionTask?
}

extension CacheFetching where Self:Fetcher {
    func downloadData(urlRequest: URLRequest, completion: @escaping CacheFetching.DownloadCompletion) -> URLSessionTask? {
        let task = session.downloadTask(with: urlRequest) { fileURL, response, error in
            self.handleDownloadTaskCompletion(urlRequest: urlRequest, fileURL: fileURL, response: response, error: error, completion: completion)
        }
        task.resume()
        return task
    }
    
    func handleDownloadTaskCompletion(urlRequest: URLRequest, fileURL: URL?, response: URLResponse?, error: Error?, completion: @escaping CacheFetching.DownloadCompletion) {
        
        if let error = error {
            completion(error, urlRequest, response, nil, nil)
            return
        }
        guard let fileURL = fileURL, let unwrappedResponse = response else {
            completion(Fetcher.unexpectedResponseError, urlRequest, response, nil, nil)
            return
        }
        if let httpResponse = unwrappedResponse as? HTTPURLResponse, httpResponse.statusCode != 200 {
            completion(Fetcher.unexpectedResponseError, urlRequest, response, nil, nil)
            return
        }
        completion(nil, urlRequest, response, fileURL, unwrappedResponse.mimeType)
    }
}
