
import Foundation

class EPCNetworkManager: EPCNetworkManaging {

    private let session: Session

    /**
     * Serial dispatch queue that enables working with properties in a thread-safe
     * way
     */
    private let queue = DispatchQueue(label: "EPCNetworkManager-" + UUID().uuidString)
    /**
     * Holds events that have been scheduled for POSTing
     */
    private var outputBuffer: [(url: URL, body: NSDictionary)] = []
    
    init(session: Session = Session.shared) {
        self.session = session
    }

    func schedulePost(url: URL, body: NSDictionary) {
        appendPostToOutputBuffer((url: url, body: body))
    }
    
    func httpDownload(url: URL, completion: @escaping (Data?) -> Void) {
        httpDownload(url: url, retriesRemaining: 5, attemptDelay: 2, completion: completion)
    }

    /**
     * Download data over HTTP with capacity for retries
     * - Parameters:
     *   - url: where to request data from
     *   - retriesRemaining: maximum number of retries allowed for this download
     *     operation
     *   - attemptDelay: time between each retry
     *   - completion: what to do with the downloaded data
     *
     * The operation will be performed up to `retriesRemaining + 1` times.
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
        var queuedEvent: (url: URL, body: NSDictionary)?
        while !outputBufferIsEmpty() {
            queuedEvent = removeOutputBufferAtIndex(0)
            if let queuedEvent = queuedEvent {
                self.submit(url: queuedEvent.url, payload: queuedEvent.body)
            }
        }
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

private extension EPCNetworkManager {
    /**
     * Thread-safe asynchronous buffering of an event scheduled for POSTing
     * - Parameter post: a tuple consisting of an `NSDictionary` `body` to be
     *   POSTed to the `url`
     */
    func appendPostToOutputBuffer(_ post: (url: URL, body: NSDictionary)) {
        queue.async {
            self.outputBuffer.append(post)
        }
    }
    /**
     * Thread-safe synchronous check if any events have been scheduled
     * - Returns: `true` if there are no scheduled evdents, `false` otherwise
     */
    func outputBufferIsEmpty() -> Bool {
        queue.sync {
            return self.outputBuffer.isEmpty
        }
    }
    /**
     * Thread-safe synchronous removal of scheduled event at index
     * - Parameter index: The index from which to remove the scheduled event
     * - Returns: a previously scheduled event
     */
    func removeOutputBufferAtIndex(_ index: Int) -> (url: URL, body: NSDictionary)? {
        queue.sync {
            if self.outputBuffer.isEmpty || index >= self.outputBuffer.count {
                return nil
            }
            let post = self.outputBuffer.remove(at: index)
            return post
        }
    }
}
