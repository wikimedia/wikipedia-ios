
import Foundation

public protocol CacheFetching {
    typealias TemporaryFileURL = URL
    typealias MIMEType = String
    typealias DownloadCompletion = (Error?, URLRequest?, URLResponse?, TemporaryFileURL?, MIMEType?) -> Void
    typealias DataCompletion = (Result<Data, Error>) -> Void
    
    func downloadData(urlRequest: URLRequest, completion: @escaping DownloadCompletion) -> URLSessionTask?
    func data(for urlRequest: URLRequest, completion: @escaping DataCompletion) -> URLSessionTask?
}

extension CacheFetching where Self:Fetcher {
    public func downloadData(urlRequest: URLRequest, completion: @escaping CacheFetching.DownloadCompletion) -> URLSessionTask? {
        let task = session.downloadTask(with: urlRequest) { fileURL, response, error in
            self.handleDownloadTaskCompletion(urlRequest: urlRequest, fileURL: fileURL, response: response, error: error, completion: completion)
        }
        task?.resume()
        return task
    }
    
    func handleDownloadTaskCompletion(urlRequest: URLRequest, fileURL: URL?, response: URLResponse?, error: Error?, completion: @escaping CacheFetching.DownloadCompletion) {
        
        if let error = error {
            completion(error, urlRequest, response, nil, nil)
            return
        }
        guard let unwrappedResponse = response else {
            completion(RequestError.unexpectedResponse, urlRequest, response, nil, nil)
            return
        }
        if let httpResponse = unwrappedResponse as? HTTPURLResponse, httpResponse.statusCode != 200 {
            if httpResponse.statusCode == 304 {
                completion(RequestError.notModified, urlRequest, response, nil, nil)
            } else {
                completion(RequestError.unexpectedResponse, urlRequest, response, nil, nil)
            }
            return
        }
        completion(nil, urlRequest, response, fileURL, unwrappedResponse.mimeType)
    }
    
    @discardableResult public func data(for urlRequest: URLRequest, completion: @escaping DataCompletion) -> URLSessionTask? {
        let task = session.dataTask(with: urlRequest) { (data, urlResponse, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data {
                completion(.success(data))
            }
        }
        
        task?.resume()
        return task
    }
}
