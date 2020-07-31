
import Foundation

class EPCNetworkManager: EPCNetworkManaging {
    
    private let storageManager: EPCStorageManaging
    private let session: Session
    
    init(storageManager: EPCStorageManaging, session: Session = Session.shared) {
        self.storageManager = storageManager
        self.session = session
    }
    
    func httpPost(url: URL, body: NSDictionary) {
        storageManager.createAndSavePostItem(with: url, body: body)
    }
    
    func httpDownload(url: URL, completion: @escaping (Data?) -> Void) {
        httpDownload(url: url, attempt: 0, maxAttempts: 5, attemptDelay: 2, completion: completion)
    }
    
    private func httpDownload(url: URL, attempt: Int, maxAttempts: Int, attemptDelay: TimeInterval, completion: @escaping (Data?) -> Void) {
        
        guard attempt < maxAttempts else {
            completion(nil)
            return
        }
        
        let task = session.dataTask(with: url) { (data, response, error) in
            
            let failureBlock = {
                dispatchOnMainQueueAfterDelayInSeconds(attemptDelay) {
                    self.httpDownload(url: url, attempt: attempt + 1, maxAttempts: maxAttempts, attemptDelay: attemptDelay, completion: completion)
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                let data = data else {
                failureBlock()
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                failureBlock()
                return
            }
            
            guard error == nil else {
                failureBlock()
                return
            }
            
            completion(data)
        }
        task?.resume()
    }
    
    func httpTryPost() {
        
    }
    
    
}
