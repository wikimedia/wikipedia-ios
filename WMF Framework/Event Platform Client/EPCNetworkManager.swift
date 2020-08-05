
import Foundation

class EPCNetworkManager: EPCNetworkManaging {
    
    private let storageManager: EPCStorageManaging
    private let session: Session
    private let operationQueue: OperationQueue
    
    init(storageManager: EPCStorageManaging, session: Session = Session.shared) {
        self.storageManager = storageManager
        self.session = session
        
        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
    }
    
    func httpPost(url: URL, body: NSDictionary) {
        storageManager.createAndSavePost(with: url, body: body)
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
    
    func httpTryPost(_ completion: (() -> Void)? = nil) {
        let operation = AsyncBlockOperation { (operation) in
            
            self.storageManager.deleteStalePosts()
            let postItems = self.storageManager.fetchPostsForPosting()
            
            self.postItems(postItems) {
                operation.finish()
            }
        }
        
        operationQueue.addOperation(operation)
        guard let completion = completion else {
            return
        }
        let completionBlockOp = BlockOperation(block: completion)
        completionBlockOp.addDependency(operation)
        operationQueue.addOperation(completion)
    }
    
    private func postItems(_ items: [EPCPost], completion: @escaping () -> Void) {
        
        let taskGroup = WMFTaskGroup()
        
        var completedIDs = Set<NSManagedObjectID>()
        var failedIDs = Set<NSManagedObjectID>()
        
        for item in items {
            let moid = item.objectID
            guard let urlAndBody = storageManager.urlAndBodyOfPost(item) else {
                failedIDs.insert(moid)
                continue
            }
            taskGroup.enter()
            let userAgent = item.userAgent ?? WikipediaAppUtils.versionedUserAgent()
            submit(url: urlAndBody.url, payload: urlAndBody.body, userAgent: userAgent) { (error) in
                if let error = error {
                    if error != .network {
                        failedIDs.insert(moid)
                    }
                } else {
                    completedIDs.insert(moid)
                }
                taskGroup.leave()
            }
        }
        
        taskGroup.waitInBackground {
            if (completedIDs.count == items.count) {
                DDLogDebug("EPCNetworkManager: All records succeeded")
            } else {
                DDLogDebug("EPCNetworkManager: Some records failed")
            }
            self.storageManager.updatePosts(completedIDs: completedIDs, failedIDs: failedIDs)
            completion()
        }
    }
    
    private func submit(url: URL, payload: NSDictionary, userAgent: String, completion: @escaping (EventLoggingError?) -> Void) {

        var request = session.request(with: url, method: .post, bodyParameters: payload, bodyEncoding: .json)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let task = session.dataTask(with: request, completionHandler: { (_, response, error) in
            guard error == nil,
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode / 100 == 2 else {
                    if let error = error as NSError?, error.domain == NSURLErrorDomain {
                        completion(EventLoggingError.network)
                    } else {
                        completion(EventLoggingError.generic)
                    }
                    return
            }
            completion(nil)
        })
        task?.resume()
    }
    
}
