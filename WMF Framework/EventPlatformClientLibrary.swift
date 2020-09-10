/*
 * Event Platform Client (EPC)
 *
 * DESCRIPTION
 *     Collects events in an input buffer, adds some metadata, places them in an
 *     ouput buffer where they are periodically bursted to a remote endpoint via
 *     HTTP POST.
 *
 *     Designed for use with Wikipedia iOS application producing events to a
 *     stream intake service.
 *
 * LICENSE NOTICE
 *     Copyright 2019 Wikimedia Foundation
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are
 *     met:
 *
 *     1. Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *
 *     2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 *     IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 *     THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *     PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 *     CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *     EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *     PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *     PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *     LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *     NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *     SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation

/**
 * Event Platform Client (EPC)
 *
 * Use `EPC.shared?.submit(stream, event, domain?, date?)` to submit ("log") events to
 * streams.
 *
 * iOS schemas will always include the following fields which are managed by EPC
 * and which will be assigned automatically by the library:
 * - `client_dt`: client-side timestamp of when event was originally submitted
 * - `app_install_id`: app install ID as in legacy EventLoggingService
 * - `app_session_id`: the ID of the session at the time of the event when it was
 *   originally submitted
 */
@objc (WMFEventPlatformClient)
public class EPC: NSObject {    
    // MARK: - Properties

    @objc(sharedInstance) public static let shared: EPC? = {
        guard let legacyEventLoggingService = EventLoggingService.shared else {
            DDLogError("EPCStorageManager: Unable to get pull legacy EventLoggingService instance for instantiating EPCStorageManager")
            return nil
        }

        return EPC(legacyEventLoggingService: legacyEventLoggingService)
    }()
    
    /**
     * Streams are the event stream identifiers that can be utilized with the EventPlatformClientLibrary. They should
     *  correspond to the `$id` of a schema in
     * [this repository](https://gerrit.wikimedia.org/g/schemas/event/secondary/).
     */
    public enum Stream: String, Codable {
        case editHistoryCompare = "ios.edit_history_compare"
    }

    /**
     * Serial dispatch queue that enables working with properties in a thread-safe
     * way
     */
    private let queue = DispatchQueue(label: "EventPlatformClient-" + UUID().uuidString)

    /**
     * Serial dispatch queue for encoding data on a background thread
     */
    private let encodeQueue = DispatchQueue(label: "EventPlatformClientEncode-" + UUID().uuidString, qos: .background)

    /**
     * Where to send events to for intake
     *
     * See [wikitech:Event Platform/EventGate](https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate)
     * for more information. Specifically, the section on
     * **eventgate-analytics-external**.  This service uses the stream
     * configurations from Meta wiki as its source of truth.
     */
    private let streamIntakeServiceURI: URL
    /**
     * MediaWiki API endpoint which returns stream configurations as JSON
     *
     * Streams are configured via [mediawiki-config/wmf-config/InitialiseSettings.php](https://gerrit.wikimedia.org/g/operations/mediawiki-config/+/master/wmf-config/InitialiseSettings.php)
     *
     * The config changes are deployed in [backport windows](https://wikitech.wikimedia.org/wiki/Backport_windows)
     * by scheduling on the [Deployments](https://wikitech.wikimedia.org/wiki/Deployments)
     * page. Stream configurations are made available for external consumption via
     * MediaWiki API via [Extension:EventStreamConfig](https://gerrit.wikimedia.org/g/mediawiki/extensions/EventStreamConfig/)
     *
     * In production, we use [Meta wiki](https://meta.wikimedia.org/wiki/Main_Page)
     * [streamconfigs endpoint](https://meta.wikimedia.org/w/api.php?action=help&modules=streamconfigs)
     * with the constraint that the `destination_event_service` is configured to
     * be "eventgate-analytics-external" (to filter out irrelevant streams from
     * the returned list of stream configurations).
     */
    private let streamConfigServiceURI: URL

    /**
     * An individual stream's configuration.
     */
    private struct StreamConfiguration: Codable {
        let sampling: Sampling?
        struct Sampling: Codable {
            let rate: Double?
            let identifier: String?
        }
    }
    
    /**
     * Holds each stream's configuration.
     */
    private var streamConfigurations: [Stream: StreamConfiguration]? {
        get {
            queue.sync {
                return _streamConfigurations
            }
        }
        set {
            queue.async {
                self._streamConfigurations = newValue
            }
        }
    }
    private var _streamConfigurations: [Stream: StreamConfiguration]? = nil
    
    /**
     * Updated when app enters background, used for determining if the session has
     * expired.
     */
    private var lastTimestamp: Date = Date()
    
    /**
     * Return a session identifier
     * - Returns: session ID
     *
     * The identifier is a string of 20 zero-padded hexadecimal digits
     * representing a uniformly random 80-bit integer.
     */
    private var sessionID: String {
        get {
            queue.sync {
                guard let sID = _sessionID else {
                    let newID = generateID()
                    _sessionID = newID
                    return newID
                }

                return sID
            }
        }
    }
    private var _sessionID: String?

    /**
     * For retrieving app install ID and "share usage data" preference
     */
    private let legacyEventLoggingService: EventLoggingService

    /**
     * Store events until the library is finished initializing
     *
     * The EPC library makes an HTTP request to a remote stream configuration
     * service for information about how to evaluate incoming event data. Until
     * this initialization is complete, we store any incoming events in this
     * buffer.
     *
     * Only modify (append events to, remove events from) *synchronously* via
     * `queue.sync`
     */
    private var inputBuffer: [(stream: Stream, data: Data)] = []

    /**
     * Maximum number of events allowed in the input buffer
     */
    private let inbutBufferLimit = 128

    /**
     * Holds events that have been scheduled for POSTing
     */
    private var outputBuffer: [(url: URL, body: Data)] = []

    /**
     * Cache of "in sample" / "out of sample" determination for each stream
     *
     * The process of determining only has to happen the first time an event is
     * logged to a stream for which stream configuration is available. All other
     * times `in_sample` simply returns the cached determination.
     *
     * Only cache determinations asynchronously via `queue.async`
     */
    private var samplingCache: [Stream: Bool] = [:]

    /**
     * Install ID, used for streams configured with
     * `sampling.identifier: "device"` and assigning to `app_install_id` field
     * in event data
     */
    private var installID: String? {
        return legacyEventLoggingService.appInstallID
    }

    /**
     * Whether user has opted in to sharing usage data with us
     */
    private var sharingUsageData: Bool {
        return legacyEventLoggingService.isEnabled
    }

    // MARK: - Methods

    private init?(legacyEventLoggingService: EventLoggingService) {
        self.legacyEventLoggingService = legacyEventLoggingService

        /* The streams that will be retrieved from the API will be the ones that
         * specify "eventgate-analytics-external" for destination_event_service
         * in the config. This serves two purposes: (1) lightens the payload, as
         * the full stream config includes irrelevant streams (e.g. MediaWiki
         * events and client-side error logging), and (2) we ensure that only
         * streams with that destination are logged to, since
         * eventgate-analytics-external is set up as a public endpoint at
         * intake-analytics.wikimedia.org, where both EventLogging and this
         * library send analytics events to.
         */
        guard let streamIntakeServiceURI = URL(string: "https://intake-analytics.wikimedia.org/v1/events"),
            let streamConfigServiceURI = URL(string: "https://meta.wikimedia.org/w/api.php?action=streamconfigs&format=json&constraints=destination_event_service=eventgate-analytics-external") else {
                DDLogError("EPC: Unable to instantiate URIs for stream intake and stream config services")
                return nil
        }

        self.streamIntakeServiceURI = streamIntakeServiceURI
        self.streamConfigServiceURI = streamConfigServiceURI
        
        super.init()

        self.fetchStreamConfiguration(retries: 10, retryDelay: 30)
    }

    /**
     * This method is called by the application delegate in
     * `applicationWillResignActive()` and disables event logging.
     */
    @objc public func appInBackground() {
        lastTimestamp = Date()
    }
    /**
     * This method is called by the application delegate in
     * `applicationDidBecomeActive()` and re-enables event logging.
     *
     * If it has been more than 15 minutes since the app entered background state,
     * a new session is started.
     */
    @objc public func appInForeground() {
        if sessionTimedOut() {
            resetSession()
        }
    }
    /**
     * This method is called by the application delegate in
     * `applicationWillTerminate()`
     *
     * We do not persist session ID on app close because we have decided that a
     * session ends when the user (or the OS) has closed the app or when 15
     * minutes of inactivity have passed.
     */
    @objc public func appWillClose() {
        // Placeholder for any onTerminate logic
    }

    /**
     * Generates a new identifier using the same algorithm as EPC libraries for
     * web and Android
     */
    private func generateID() -> String {
        var id: String = ""
        for _ in 1...5 {
            id += String(format: "%04x", arc4random_uniform(65535))
        }
        return id
    }
    
    /**
     * Called when user toggles logging permissions in Settings
     *
     * This assumes storageManager's deviceID will be reset separately by a
     * different owner (EventLoggingService's `reset()` method)
     */
    @objc public func reset() {
        resetSession()
    }

    /**
     * Unset the session
     */
    private func resetSession() -> Void {
        queue.async {
            self._sessionID = nil
        }
        removeAllSamplingCache()
    }

    /**
     * Check if session expired, based on last active timestamp
     *
     * A new session ID is required if it has been more than 15 minutes since the
     * user was last active (e.g. when app entered background).
     */
    private func sessionTimedOut() -> Bool {
        /*
         * A TimeInterval value is always specified in seconds.
         */
        return lastTimestamp.timeIntervalSinceNow < -900
    }

    /**
     * Fetch stream configuration from stream configuration service
     * - Parameters:
     *   - retries: number of retries remaining
     *   - retryDelay: seconds between each attempt, increasing by 50% after
     *     every failed attempt
     */
    private func fetchStreamConfiguration(retries: Int, retryDelay: TimeInterval) {
        self.httpGet(url: self.streamConfigServiceURI, completion: { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse, let data = data, httpResponse.statusCode == 200 else {
                DDLogWarn("EPC: Server did not respond adequately, will try \(self.streamConfigServiceURI.absoluteString) again")

                if retries > 0 {
                    dispatchOnMainQueueAfterDelayInSeconds(retryDelay) {
                        self.fetchStreamConfiguration(retries: retries - 1, retryDelay: retryDelay * 1.5)
                    }
                } else {
                    DDLogWarn("EPC: Ran out of retries when attempting to download stream configs")
                }

                return
            }

            self.loadStreamConfiguration(data)
        })
    }

    /**
     * Processes fetched stream config to local Dictionary
     * - Parameter data: JSON-serialized stream configuration
     *
     * Example of a retrieved config:
     * ``` js
     * {
     *   "streams": {
     *     "test.instrumentation.sampled": {
     *       "sampling": {
     *         "rate":0.1
     *       }
     *     },
     *     "test.instrumentation": {},
     *   }
     * }
     * ```
     */
    private func loadStreamConfiguration(_ data: Data) {
        #if DEBUG
        if let raw = String.init(data: data, encoding: String.Encoding.utf8) {
            DDLogDebug("EPC: Downloaded stream configs (raw): \(raw)")
        }
        #endif
        struct StreamConfigurationsJSON: Codable {
            let streams: [String: StreamConfiguration]
        }
        do {
            let json = try JSONDecoder().decode(StreamConfigurationsJSON.self, from: data)

            // Make them available to any newly logged events before flushing
            // buffer (this is set using serial queue but asynchronously)
            streamConfigurations = json.streams.reduce(into: [:], { (result, kv) in
                guard let stream = Stream(rawValue: kv.key) else {
                    return
                }
                result?[stream] = kv.value
            })

            // Process event buffer after making stream configs available
            // NOTE: If any event is re-submitted while streamConfigurations
            // is still being set (asynchronously), they will just go back to
            // input buffer.
            while let event = inputBufferPopFirst() {
                guard inSample(stream: event.stream) else {
                    continue
                }
                appendPostToOutputBuffer((url: streamIntakeServiceURI, body: data))
            }
        } catch let error {
            DDLogError("EPC: Problem processing JSON payload from response: \(error)")
        }
    }

    /**
     * Flush the queue of outgoing requests in a first-in-first-out,
     * fire-and-forget fashion
     */
    private func postAllScheduled(_ completion: (() -> Void)? = nil) {
        DDLogDebug("EPC: Posting all scheduled requests")
        let group = DispatchGroup()
        while let item = outputBufferPopFirst() {
            group.enter()
            httpPost(url: item.url, body: item.body) {
                group.leave()
            }
        }
        group.notify(queue: queue) {
            completion?()
        }
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
     * Compute a boolean function on a random identifier
     * - Parameter stream: name of the stream
     * - Returns: `true` if in sample or `false` otherwise
     *
     * The determinations are lazy and cached, so each stream's in-sample vs
     * out-of-sample determination is computed only once, the first time an event
     * is logged to that stream.
     *
     * Refer to sampling settings section in
     * [mw:Wikimedia Product/Analytics Infrastructure/Stream configuration](https://www.mediawiki.org/wiki/Wikimedia_Product/Analytics_Infrastructure/Stream_configuration)
     * for more information.
     */
    private func inSample(stream: Stream) -> Bool {

        guard let configs = streamConfigurations else {
            DDLogDebug("EPC: Invalid state, must have streamConfigurations to check for inSample")
            return false
        }

        if let cachedValue = getSamplingForStream(stream) {
            return cachedValue
        }

        guard let config = configs[stream] else {
            let error = """
            EPC: Invalid state, stream '\(stream)' must be present in streamConfigurations to check for inSample
            but found only: \(configs.keys.map(\.rawValue).joined(separator: ", "))
            """
            DDLogError(error)
            return false
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

        guard identifierType == sessionIdentifierType || identifierType == deviceIdentifierType else {
            DDLogDebug("EPC: Logged to stream which is not configured for sampling based on \(sessionIdentifierType) or \(deviceIdentifierType) identifier")
            cacheSamplingForStream(stream, inSample: false)
            return false
        }

        guard let identifier = identifierType == sessionIdentifierType ? sessionID : self.installID else {
            DDLogError("EPC: Missing token for determining in- vs out-of-sample. Fallbacking to not in sample.")
            cacheSamplingForStream(stream, inSample: false)
            return false
        }
        let result = determine(identifier, rate)
        cacheSamplingForStream(stream, inSample: result)
        return result
    }

    /// EventBody is used to encod event data into the POST body of a request to the Modern Event Platform
    struct EventBody<E>: Encodable where E: EventInterface {
        /// EventGate needs to know which version of the schema to validate against
        let meta: Meta
        struct Meta: Codable {
            let stream: Stream
            /**
             * meta.id is *optional* and should only be done in case the client is
             * known to send duplicates of events, otherwise we don't need to
             * make the payload any heavier than it already is
             */
            let id: UUID
            let domain: String?
        }
        let appInstallID: String
        /**
         * Generated events have the session ID attached to them before stream
         * config is available (in case they're generated offline) and before
         * they're cc'd to any other streams (once config is available).
         */
        let appSessionID: String
        /**
         * The top-level field `client_dt` is for recording the time the event
         * was generated. EventGate sets `meta.dt` during ingestion, so for
         * analytics events that field is used as "timestamp of reception" and
         * is used for partitioning the events in the database. See Phab:T240460
         * for more information.
         */
        let clientDT: Date
        
        /**
         * Event represents the client-provided event data.
         * The event is encoded at the top level of the resulting structure.
         * If any of the `CodingKeys` conflict with keys defined by `EventBody`,
         * the values from `event` will be used.
         */
        let event: E
        
        enum CodingKeys: String, CodingKey {
            case schema = "$schema"
            case meta
            case appInstallID = "app_install_id"
            case appSessionID = "app_session_id"
            case clientDT = "client_dt"
            case event
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            do {
                try container.encode(meta, forKey: .meta)
                try container.encode(appInstallID, forKey: .appInstallID)
                try container.encode(appSessionID, forKey: .appSessionID)
                try container.encode(clientDT, forKey: .clientDT)
                try container.encode(E.schema, forKey: .schema)
                try event.encode(to: encoder)
            } catch let error {
                DDLogError("EPC: Error encoding event body: \(error)")
            }
        }
    }
    
    /**
     * Submit an event according to the given stream's configuration.
     * - Parameters:
     *      - stream: The stream to submit the event to
     *      - event: The event data
     *      - domain: Optional domain to include for the event (without protocol)
     *      - date: Optional date for the event. This corresponds to the `client_dt`.
     *
     * An example call:
     * ```
     * struct TestEvent: EventInterface {
     *   static let schema = "/analytics/mobile_apps/test/1.0.0"
     *   let test_string: String
     *   let test_map: SourceInfo
     *   struct SourceInfo: Codable {
     *       let file: String
     *       let method: String
     *   }
     * }
     *
     * let sourceInfo = TestEvent.SourceInfo(file: "Features/Feed/ExploreViewController.swift", method: "refreshControlActivated")
     * let event = TestEvent(test_string: "Explore Feeed refreshed", test_map: sourceInfo)
     *
     * EPC.shared?.submit(
     *   stream: .test, // Defined in `EPC.Stream`
     *   event: event
     * )
     * ```
     *
     * Regarding `domain`: this is *optional* and should be used when event needs
     * to be attrributed to a particular wiki (Wikidata, Wikimedia Commons, a
     * specific edition of Wikipedia, etc.). If the language is NOT relevant in
     * the context, `domain` can be safely omitted. Using "domain" rather than
     * "language" is consistent with the other platforms and allows for the
     * possibility of setting a non-Wikipedia domain like "commons.wikimedia.org"
     * and "wikidata.org" for multimedia/metadata-related in-app analytics.
     * Instrumentation code should use the `host` property of a `URL` as the value
     * for this parameter.
     *
     * Cases where instrumentation would set a `domain`:
     * - reading or editing an article
     * - managing watchlist
     * - interacting with feed
     * - searching
     *
     * Cases where it might not be necessary for the instrument to set a `domain`:
     * - changing settings
     * - managing reading lists
     * - navigating map of nearby articles
     * - multi-lingual features like Suggested Edits
     * - marking session start/end; in which case schema and `data` should have a
     *   `languages` field where user's list of languages can be stored, although
     *   it might make sense to set it to the domain associated with the user's
     *   1st preferred language – in which case use
     *   `MWKLanguageLinkController.sharedInstance().appLanguage.siteURL().host`
     */
    public func submit<E: EventInterface>(stream: Stream, event: E, domain: String? = nil, date: Date? = nil) {
        encodeQueue.async {
            self._submit(stream: stream, event: event, domain: domain, date: date)
        }
    }

    /// Private, synchronous version of `submit`.
    private func _submit<E: EventInterface>(stream: Stream, event: E, domain: String? = nil, date: Date? = nil){
        guard sharingUsageData else {
            return
        }
        guard let appInstallID = installID else {
            DDLogDebug("EPC: Could not retrieve app install ID")
            return
        }
        let meta = EventBody<E>.Meta(stream: stream, id: UUID(), domain: domain)

        let eventPayload = EventBody(meta: meta, appInstallID: appInstallID, appSessionID: sessionID, clientDT: date ?? Date(), event: event)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            #if DEBUG
            encoder.outputFormatting = .prettyPrinted
            #endif
            
            let jsonData = try encoder.encode(eventPayload)
            
            #if DEBUG
            let jsonString = String(data: jsonData, encoding: .utf8)!
            DDLogDebug("EPC: Scheduling event to be sent to \(streamIntakeServiceURI) with POST body:\n\(jsonString)")
            #endif
            
            guard let streamConfigs = streamConfigurations else {
                let inputBufferedEvent: (stream: Stream, data: Data) = (stream: stream, data: jsonData)
                appendEventToInputBuffer(inputBufferedEvent)
                return
            }
            
            guard streamConfigs.keys.contains(stream) else {
                DDLogDebug("EPC: Event submitted to '\(stream)' but only the following streams are configured: \(streamConfigs.keys.map(\.rawValue).joined(separator: ", "))")
                return
            }
            
            guard inSample(stream: stream) else {
                return
            }
            
            appendPostToOutputBuffer((url: streamIntakeServiceURI, body: jsonData))
        } catch let error {
            DDLogError("EPC: \(error.localizedDescription)")
        }
    }
}

//MARK: Thread-safe accessors for collection properties

private extension EPC {

    /**
     * Thread-safe synchronous retrieval of buffered events
     */
    func getInputBuffer() -> [(stream: Stream, data: Data)] {
        queue.sync {
            return self.inputBuffer
        }
    }

    /**
     * Thread-safe synchronous buffering of an event
     * - Parameter event: event to be buffered
     */
    func appendEventToInputBuffer(_ event: (stream: Stream, data: Data)) {
        queue.sync {
            /*
             * Check if input buffer has reached maximum allowed size. Practically
             * speaking, there should not have been over a hundred events
             * generated when the user first launches the app and before the
             * stream configuration has been downloaded and becomes available. In
             * such a case we're just going to start clearing out the oldest
             * events to make room for new ones.
             */
            if self.inputBuffer.count == self.inbutBufferLimit {
                _ = self.inputBuffer.remove(at: 0)
            }
            self.inputBuffer.append(event)
        }
    }

    /**
     * Thread-safe synchronous removal of first buffered event
     * - Returns: a previously buffered event
     */
    func inputBufferPopFirst() -> (stream: Stream, data: Data)? {
        queue.sync {
            if self.inputBuffer.isEmpty {
                return nil
            }
            return self.inputBuffer.remove(at: 0)
        }
    }

    /**
     * Thread-safe asynchronous caching of a stream's in-vs-out-of-sample
     * determination
     * - Parameter stream: name of stream to cache determination for
     * - Parameter inSample: whether the stream was determined to be in-sample
     *   this session
     */
    func cacheSamplingForStream(_ stream: Stream, inSample: Bool) {
        queue.async {
            self.samplingCache[stream] = inSample
        }
    }

    /**
     * Thread-safe synchronous retrieval of a stream's cached in-vs-out-of-sample determination
     * - Parameter stream: name of stream to retrieve determination for from the cache
     * - Returns: `true` if stream was determined to be in-sample this session, `false` otherwise
     */
    func getSamplingForStream(_ stream: Stream) -> Bool? {
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

    /**
     * Thread-safe asynchronous buffering of an event scheduled for POSTing
     * - Parameter post: a tuple consisting of an `NSDictionary` `body` to be
     *   POSTed to the `url`
     */
    func appendPostToOutputBuffer(_ post: (url: URL, body: Data)) {
        queue.async {
            self.outputBuffer.append(post)
        }
    }
    
    /**
     * Thread-safe synchronous removal of first scheduled event
     * - Returns: a previously scheduled event
     */
    func outputBufferPopFirst() -> (url: URL, body: Data)? {
        queue.sync {
            if self.outputBuffer.isEmpty {
                return nil
            }
            return self.outputBuffer.remove(at: 0)
        }
    }
}

//MARK: NetworkIntegration

private extension EPC {
    /**
     * HTTP POST
     * - Parameter url: Where to POST data (`body`) to
     * - Parameter body: Body of the POST request
     */
    private func httpPost(url: URL, body: Data? = nil, completion: (() -> Void)? = nil) {
        DDLogDebug("EPC: Attempting to POST data to \(url.absoluteString)")
        let request = Session.shared.request(with: url, method: .post, bodyData: body, bodyEncoding: .json)
        let task = Session.shared.dataTask(with: request, completionHandler: { (_, response, error) in
            if error != nil {
                DDLogError("EPC: An error occurred sending the request")
            }
            completion?()
        })
        task?.resume()
    }
    /**
     * HTTP GET
     * - Parameter url: Where to GET data from
     * - Parameter completion: What to do with gotten data
     */
    private func httpGet(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        DDLogDebug("EPC: Attempting to GET data from \(url.absoluteString)")
        var request = URLRequest.init(url: url) // httpMethod = "GET" by default
        request.setValue(WikipediaAppUtils.versionedUserAgent(), forHTTPHeaderField: "User-Agent")
        let task = Session.shared.dataTask(with: request, completionHandler: completion)
        task?.resume()
    }
}

//MARK: PeriodicWorker

extension EPC: PeriodicWorker {
    public func doPeriodicWork(_ completion: @escaping () -> Void) {
        self.postAllScheduled(completion)
    }
}

//MARK: BackgroundFetcher

extension EPC: BackgroundFetcher {
    public func performBackgroundFetch(_ completion: @escaping (UIBackgroundFetchResult) -> Void) {
        doPeriodicWork {
            completion(.noData)
        }
    }
}

// MARK: EventInterface

/**
 * Protocol for event data.
 * Currently only requires conformance to Codable.
 */
public protocol EventInterface: Codable {
    /**
     * Schema specifies which schema (and specifically which version of that schema)
     * a given event conforms to. Analytics schemas can be found in the jsonschema directory of
     * [secondary repo](https://gerrit.wikimedia.org/g/schemas/event/secondary/).
     * As an example, if instrumenting client-side error logging, a possible
     * `$schema` would be `/mediawiki/client/error/1.0.0`. For the most part, the
     * `$schema` will start with `/analytics`, since there's where
     * analytics-related schemas are collected.
     */
    static var schema: String { get }
}
