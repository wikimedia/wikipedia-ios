
import Foundation

final class ImageFetcher: Fetcher {
    
    typealias RequestURL = URL
    typealias TemporaryFileURL = URL
    typealias MIMEType = String
    typealias DownloadCompletion = (Error?, RequestURL?, TemporaryFileURL?, MIMEType?) -> Void
    
    func downloadData(url: URL, completion: @escaping DownloadCompletion) -> URLSessionTask? {
        let task = session.downloadTask(with: url) { fileURL, response, error in
            self.handleDownloadTaskCompletion(url: url, fileURL: fileURL, response: response, error: error, completion: completion)
        }
        
        task.resume()
        return task
    }
}

private extension ImageFetcher {
    
    //tonitodo: track/untrack tasks
    func handleDownloadTaskCompletion(url: URL, fileURL: URL?, response: URLResponse?, error: Error?, completion: @escaping DownloadCompletion) {
        if let error = error {
            completion(error, url, nil, nil)
            return
        }
        guard let fileURL = fileURL, let response = response else {
            completion(Fetcher.unexpectedResponseError, url, nil, nil)
            return
        }
        if let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode != 200 && httpResponse.statusCode != 304) {
            completion(Fetcher.unexpectedResponseError, url, nil, nil)
            return
        }
        completion(nil, url, fileURL, response.mimeType)
    }
}
