
import Foundation

class EPCNetworkManager: EPCNetworkManaging {

    private let session: Session
    private let operationQueue: OperationQueue

    private var outputQueue = [(url: URL, body: NSDictionary)]()
    
    init(session: Session = Session.shared) {
        self.session = session
        
        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
    }

    func schedulePost(url: URL, body: NSDictionary) {
        outputQueue.append((url: url, body: body))
    }
    
    func httpDownload(url: URL, completion: @escaping (Data?) -> Void) {
        httpDownload(url: url, retriesRemaining: 5, attemptDelay: 2, completion: completion)
    }

    /**
     * Download data over HTTP with capacity for retries
     * - Parameters:
     *   - url: where to request data from
     *   - maxRetries: maximum number of retries allowed for this download operation
     *   - attemptDelay: time between each retry
     *   - completion: what to do with the downloaded data
     */
    private func httpDownload(url: URL, retriesRemaining: Int, attemptDelay: TimeInterval, completion: @escaping (Data?) -> Void) {

        if retriesRemaining < 0 {
            completion(nil)
            return
        }
        
        let task = session.dataTask(with: url) { (data, response, error) in
            
            let failureBlock = {
                dispatchOnMainQueueAfterDelayInSeconds(attemptDelay) {
                    self.httpDownload(url: url, retriesRemaining: retriesRemaining - 1, attemptDelay: attemptDelay, completion: completion)
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                let data = data else {
                    DDLogWarn("EPCNetworkManager: server did not respond adequately, will try \(url.absoluteString) again")
                failureBlock()
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                DDLogWarn("EPCNetworkManager: HTTP status of response was \(httpResponse.statusCode), will try \(url.absoluteString) again")
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

        let operation = AsyncBlockOperation { (operation) in

            var queuedEvent: (url: URL, body: NSDictionary)?
            while !self.outputQueue.isEmpty {
                queuedEvent = self.outputQueue.remove(at: 0)
                if let queuedEvent = queuedEvent {
                    self.submit(url: queuedEvent.url, payload: queuedEvent.body)
                }
            }

            operation.finish()
        }
        
        operationQueue.addOperation(operation)
    }

    private func submit(url: URL, payload: Any? = nil) {
        let request = session.request(with: url, method: .post, bodyParameters: payload, bodyEncoding: .json)
        let task = session.dataTask(with: request, completionHandler: { (_, response, error) in
            if error != nil {
                DDLogError("EPCNetworkManager: An error occurred sending the request")
            }
        })
        task?.resume()
    }

}
