import Foundation
import CocoaLumberjackSwift

protocol SamplingControllerDelegate: AnyObject {
    var sessionID: String { get }
}

class SamplingController: NSObject {

    /**
     * Serial dispatch queue that enables working with properties in a thread-safe
     * way
     */
    private let queue = DispatchQueue(label: "EventPlatformClientSampling-" + UUID().uuidString)

    /**
     * Cache of "in sample" / "out of sample" determination for each stream
     *
     * The process of determining only has to happen the first time an event is
     * logged to a stream for which stream configuration is available. All other
     * times `in_sample` simply returns the cached determination.
     *
     * Only cache determinations asynchronously via `queue.async`
     */
    private var samplingCache: [EventPlatformClient.Stream: Bool] = [:]
    
    weak var delegate: SamplingControllerDelegate?

    /**
     * Compute a boolean function on a random identifier
     * - Parameter stream: name of the stream
     * - Parameter config: stream configuration for the provided stream name
     * - Returns: `true` if in sample or `false` otherwise
     *
     * The determinations are lazy and cached, so each stream's in-sample vs
     * out-of-sample determination is computed only once, the first time an event
     * is logged to that stream.ß
     *
     * Refer to sampling settings section in
     * [mw:Wikimedia Product/Analytics Infrastructure/Stream configuration](https://www.mediawiki.org/wiki/Wikimedia_Product/Analytics_Infrastructure/Stream_configuration)
     * for more information.
     */
    func inSample(stream: EventPlatformClient.Stream, config: EventPlatformClient.StreamConfiguration) -> Bool {
        if let cachedValue = getSamplingForStream(stream) {
            return cachedValue
        }

        guard let rate = config.sampling?.rate else {
            /*
             * If stream is present in streamConfigurations but doesn't have
             * sampling settings, it is always in-sample.
             */
            cacheSamplingForStream(stream, inSample: true)
            return true
        }

        /*
         * All platforms use session ID as the default identifier for determining
         * in- vs out-of-sample of events sent to streams. On the web, streams can
         * be set to use pageview token instead. On the apps, streams can be set
         * to use device token instead.
         */
        let sessionIdentifierType = "session"
        let deviceIdentifierType = "device"
        let identifierType = config.sampling?.identifier ?? sessionIdentifierType
        let appInstallID = UserDefaults.standard.wmf_appInstallId

        guard identifierType == sessionIdentifierType || identifierType == deviceIdentifierType else {
            DDLogWarn("EPC: Logged to stream which is not configured for sampling based on \(sessionIdentifierType) or \(deviceIdentifierType) identifier")
            cacheSamplingForStream(stream, inSample: false)
            return false
        }

        guard let identifier = identifierType == sessionIdentifierType ? delegate?.sessionID : appInstallID else {
            DDLogWarn("EPC: Missing token for determining in- vs out-of-sample. Falling back to out-of-sample.")
            cacheSamplingForStream(stream, inSample: false)
            return false
        }
        let result = determine(identifier, rate)
        cacheSamplingForStream(stream, inSample: result)
        return result
    }

    /**
     * Yields a deterministic (not stochastic) determination of whether the
     * provided `id` is in-sample or out-of-sample according to the `acceptance`
     * rate
     * - Parameter id: identifier to use for determining sampling
     * - Parameter acceptance: the desired proportion of many `token`-s being
     *   accepted
     *
     * The algorithm works in a "widen the net on frozen fish" fashion -- tokens
     * continue evaluating to true as the acceptance rate increases. For example,
     * a device determined to be in-sample for a stream "A" having rate 0.1 will
     * be determined to be in-sample for a stream "B" having rate 0.2, and its
     * events will show up in tables "A" and "B".
     */
    private func determine(_ id: String, _ acceptance: Double) -> Bool {
        guard let token = UInt32(id.prefix(8), radix: 16) else {
            return false
        }
        return (Double(token) / Double(UInt32.max)) < acceptance
    }

    /**
     * Thread-safe asynchronous caching of a stream's in-vs-out-of-sample
     * determination
     * - Parameter stream: name of stream to cache determination for
     * - Parameter inSample: whether the stream was determined to be in-sample
     *   this session
     */
    func cacheSamplingForStream(_ stream: EventPlatformClient.Stream, inSample: Bool) {
        queue.async {
            self.samplingCache[stream] = inSample
        }
    }

    /**
     * Thread-safe synchronous retrieval of a stream's cached in-vs-out-of-sample determination
     * - Parameter stream: name of stream to retrieve determination for from the cache
     * - Returns: `true` if stream was determined to be in-sample this session, `false` otherwise
     */
    func getSamplingForStream(_ stream: EventPlatformClient.Stream) -> Bool? {
        queue.sync {
            return self.samplingCache[stream]
        }
    }

    /**
     * Thread-safe asynchronous clearance of cached stream in-vs-out-of-sample determinations
     */
    func removeAllSamplingCache() {
        queue.async {
            self.samplingCache.removeAll()
        }
    }

}
