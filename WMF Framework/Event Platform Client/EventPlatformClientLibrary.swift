/*
 * Event Platform Client (EPC)
 *
 * DESCRIPTION
 *     Collects events in an input buffer, adds some metadata, places them in an
 *     ouput buffer where they are periodically bursted to a remote endpoint via
 *     HTTP POST.
 *
 *     Designed for use with Wikipedia iOS application producing events to the
 *     EventGate intake service.
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
 * The static public API via the `shared` singleton allows callers to log events.
 * Use `log` to submit an event to a specific stream. For additional information
 * on instrumentation with the Modern Event Platform and the Event Platform Client
 * libraries, please refer to the following resources:
 * - [mw:Wikimedia Product/Analytics Infrastructure/Event Platform Client](https://www.mediawiki.org/wiki/Wikimedia_Product/Analytics_Infrastructure/Event_Platform_Client)
 * - [wikitech:Event Platform/Instrumentation How To](https://wikitech.wikimedia.org/wiki/Event_Platform/Instrumentation_How_To)
 *
 * ## Logging API
 *
 * Use `EPC.shared?.submit(stream, data, domain?)` to submit (log) events to
 * streams, making sure to include `$schema` in the event `data`. This interface
 * is consistent with Event Platform Client for MediaWiki:
 * `mw.eventLog.submit( streamName, eventData )`. The `$schema` field in event
 * `data` must use the `$id` of a schema in [this repository](https://gerrit.wikimedia.org/g/schemas/event/secondary/)
 *
 * For example:
 *
 * ```
 * EPC.shared?.submit(
 *   stream: "test.instrumentation",
 *   data: [
 *     "$schema": "/analytics/test/1.0.0" as NSCoding,
 *     "test_string": "Explore Feed refreshed" as NSCoding,
 *     "test_map": [
 *       "file": "Features/Feed/ExploreViewController.swift",
 *       "method":"refreshControlActivated"
 *     ] as NSCoding
 *   ]
 * )
 * ```
 *
 * With Objective-C:
 *
 * ```
 * [[WMFEventPlatformClient sharedInstance] submitWithStream:@"test.instrumentation"
 *                                                    data:@{@"$schema": @"/analytics/test/1.0.0",
 *                                                           @"test_string": @"Opened Settings screen",
 *                                                           @"test_map":@{
 *                                                                   @"file": @"Application/App View Controller/WMFAppViewController.m",
 *                                                                   @"method": @"showSettingsWithSubViewController()"}}
 *                                                    domain: nil];
 * ```
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
        
        let networkManager = EPCNetworkManager()
        return EPC(networkManager: networkManager, legacyEventLoggingService: legacyEventLoggingService)
    }()

    /**
     * Serial dispatch queue that enables working with properties in a thread-safe
     * way
     */
    private let queue = DispatchQueue(label: "EventPlatformClient-" + UUID().uuidString)

    /**
     * See [wikitech:Event Platform/EventGate](https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate)
     * for more information. Specifically, the section on **eventgate-analytics-external**.
     */
    private let streamIntakeServiceURI: URL
    /**
     * Endpoint which returns stream configurations as JSON
     *
     * Streams are configured via [mediawiki-config/wmf-config/InitialiseSettings.php](https://gerrit.wikimedia.org/r/plugins/gitiles/operations/mediawiki-config/+/master/wmf-config/InitialiseSettings.php), deployed in a
     * [backport window](https://wikitech.wikimedia.org/wiki/Backport_windows)
     * and made available for external consumption via MediaWiki API via
     * [Extension:EventStreamConfig](https://gerrit.wikimedia.org/g/mediawiki/extensions/EventStreamConfig/)
     *
     * In production, we use [Meta wiki](https://meta.wikimedia.org/wiki/Main_Page)'s
     * [streamconfigs endpoint](https://meta.wikimedia.org/w/api.php?action=help&modules=streamconfigs)
     */
    private let streamConfigServiceURI: URL

    /**
     * Holds each stream's configuration.
     */
    private var streamConfigurations: [String: [String: Any]]? {
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
    private var _streamConfigurations: [String: [String: Any]]? = nil
    
    /**
     * Updated with every `log` call and when app enters background, used for determining if the
     * session has expired.
     */
    private var lastTimestamp: Date {
        get {
            queue.sync {
                return _lastTimeStamp
            }
        }
        set {
            queue.async {
                self._lastTimeStamp = newValue
            }
        }
    }
    private var _lastTimeStamp: Date = Date()
    
    /**
    * Return a session identifier
    * - Returns: session ID
    *
    * The identifier is a string of 20 zero-padded hexadecimal digits representing a uniformly random
    * 80-bit integer.
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

    private let iso8601Formatter: ISO8601DateFormatter

    /**
     * For retrieving app install ID and "share usage data" preference
     */
    private let legacyEventLoggingService: EventLoggingService

    /**
     * For handling HTTP requests
     */
    private let networkManager: EPCNetworkManaging

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
    private var inputBuffer: [(stream: String, data: [String: NSCoding], domain: String?)] = []

    /**
     * Maximum number of events allowed in the input buffer
     */
    private let inbutBufferLimit = 128

    /**
     * Cache of "in sample" / "out of sample" determination for each stream
     *
     * The process of determining only has to happen the first time an event is
     * logged to a stream for which stream configuration is available. All other
     * times `in_sample` simply returns the cached determination.
     *
     * Only cache determinations asynchronously via `queue.async`
     */
    private var samplingCache: [String: Bool] = [String: Bool]()

    // MARK: - Methods

    private init?(networkManager: EPCNetworkManaging, legacyEventLoggingService: EventLoggingService) {
        self.networkManager = networkManager
        self.legacyEventLoggingService = legacyEventLoggingService

        /* The streams that will be retrieved from the API will be the ones that
         * specify "eventgate-analytics-external" for destination_event_service
         * in the config. This serves two purposes: (1) lightens the payload, as
         * the full stream config includes irrelevant streams (e.g. MediaWiki
         * events and client-side error logging), and (2) we ensure that only
         * streams with that destination are logged to, since eventgate-analytics-external
         * is set up as a public endpoint at intake-analytics.wikimedia.org,
         * where both EventLogging and this library send analytics events to.
         *
         * = URIs =
         * streamIntakeServiceURIs:
         *  - Production: https://intake-analytics.wikimedia.org/v1/events
         *  - Test 1: https://pai-test.wmflabs.org/events
         *  - Test 2: https://epc-test.wmcloud.org/v1/events
         *
         * Note: events sent to 'Test 1' can be viewed at https://pai-test.wmflabs.org/view
         *
         * streamConfigServiceURIs:
         *  - Production: https://meta.wikimedia.org/w/api.php?action=streamconfigs&format=json&constraints=destination_event_service=eventgate-analytics-external
         *  - Test 1: https://pai-test.wmflabs.org/streams
         *  - Test 2: https://epc-test.wmcloud.org/w/api.php?action=streamconfigs&format=json
         */
        guard let streamIntakeServiceURI = URL(string: "https://intake-analytics.wikimedia.org/v1/events"),
            let streamConfigServiceURI = URL(string: "https://pai-test.wmflabs.org/streams") else {
                DDLogError("EventPlatformClientLibrary - Unable to instantiate uris")
                return nil
        }

        self.streamIntakeServiceURI = streamIntakeServiceURI
        self.streamConfigServiceURI = streamConfigServiceURI

        iso8601Formatter = ISO8601DateFormatter()
        
        super.init()

        configure()
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

    private var installID: String? {
        return legacyEventLoggingService.appInstallID
    }

    private var sharingUsageData: Bool {
        return legacyEventLoggingService.isEnabled
    }

    /**
     * Download stream configuration and use it to instantiate
     * `streamConfigurations` asynchronously when a network manager is available
     */
    private func configure() -> Void {
        /*
         * Assume that the network manager will keep trying to download the
         * stream configuration and that it will hold off on trying to download
         * if there is no connectivity.
         */

        if streamConfigurations == nil {
            networkManager.httpDownload(url: streamConfigServiceURI, completion: {
                data in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: [String: Any]]] else {
                        DDLogWarn("EPC: Problem processing JSON payload from response")
                        return
                }
                #if DEBUG
                if let raw = String.init(data: data, encoding: String.Encoding.utf8) {
                    DDLogDebug("EPC: Downloaded stream configs (raw): \(raw)")
                }
                #endif
                // example retrieved config: {"streams":{"test.event":{},"test.event.sampled":{"sampling":{"rate":0.1}}}}
                guard let streamConfigs = json["streams"] else {
                    DDLogWarn("EPC: Problem extracting stream configs")
                    return
                }

                #if DEBUG
                do {
                    let jsonString = try streamConfigs.toPrettyPrintJSONString()
                    DDLogDebug("EPC: Processed stream configurations:\n\(jsonString)")
                } catch let error {
                    DDLogError("EPC: \(error.localizedDescription)")
                }
                #endif

                // Make them available to any newly logged events before flushing buffer
                self.streamConfigurations = streamConfigs

                // Process event buffer after making stream configs and cc map available
                // TODO: update this to use the tuple instead of EPCBufferEvent
                var cachedEvent: (stream: String, data: [String: NSCoding], domain: String?)?
                while !self.inputBufferIsEmpty() {
                    cachedEvent = self.removeInputBufferAtIndex(0)
                    if let cachedEvent = cachedEvent {
                        self.submit(stream: cachedEvent.stream,
                                    data: cachedEvent.data,
                                    domain: cachedEvent.domain)
                    }
                }

            })
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
     * - Parameter deviceID: device identifier (aka app install ID), found in `EPCStorageManager`
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
    private func inSample(stream: String, deviceID: String) -> Bool {

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
            but found only: \(configs.keys.joined(separator: ", "))
            """
            DDLogError(error)
            return false
        }

        guard let samplingConfig = config["sampling"] as? [String: Any] else {
            /*
             * If stream is present in streamConfigurations but doesn't have
             * sampling settings, it is always in-sample.
             */
            cacheSamplingForStream(stream, inSample: true)
            return true
        }

        /*
         * If cache does not have a determination for stream, generate one.
         */
        guard let rate = samplingConfig["rate"] as? Double else {
            /*
             * If stream doesn't have a rate, assume 1.0 (always in-sample). Cache
             * this determination for any future use.
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
        let identifierType = samplingConfig["identifier"] as? String ?? sessionIdentifierType

        guard identifierType == sessionIdentifierType || identifierType == deviceIdentifierType else {
            cacheSamplingForStream(stream, inSample: false)
            return false
        }

        let identifier = identifierType == sessionIdentifierType ? sessionID : deviceID
        let result = determine(identifier, rate)
        cacheSamplingForStream(stream, inSample: result)
        return result
    }

    /**
     * Submit an event according to the given stream's configuration.
     * - Parameters:
     *      - stream: Name of the stream to submit the event to
     *      - data: A dictionary of event data, with appropriate `$schema`
     *      - domain: Optional domain to include for the event (without protocol)
     *
     * Regarding `$schema`: the instrumentation needs to specify which schema (and
     * specifically which version of that schema) it conforms to. Analytics
     * schemas can be found in the jsonschema directory of
     * [secondary repo](https://gerrit.wikimedia.org/g/schemas/event/secondary/)
     *
     * As an example, if instrumenting client-side error logging, a possible
     * `$schema` would be `/mediawiki/client/error/1.0.0`. For the most part, the
     * `$schema` will start with `/analytics`, since there's where
     * analytics-related schemas are collected. An example call:
     *
     * ```
     * EPC.shared?.submit( "test.instrumentation", [ "$schema": "/analytics/test/1.0.0" as NSCoding ] )
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
    @objc public func submit(stream: String, data: [String: NSCoding], domain: String? = nil) -> Void {
        guard self.sharingUsageData else {
            return
        }

        /*
         * EventGate needs to know which version of the schema to validate against
         */
        let schemaKey = "$schema"
        guard data.keys.contains(schemaKey) else {
            DDLogError("EPC: Event data is missing the required '$schema' field")
            return
        }

        let metaKey = "meta"
        var meta: [String: NSCoding] = data[metaKey] as? [String: NSCoding] ?? [:]

        if let domain = domain {
            meta["domain"] = domain as NSCoding
        }

        var data = data
        data[metaKey] = meta as NSCoding

        /*
         * The top-level field `client_dt` is for recording the time the event
         * was generated. EventGate sets `meta.dt` during ingestion, so for
         * analytics events that field is used as "timestamp of reception" and
         * is used for partitioning the events in the database. See Phab:T240460
         * for more information.
         */
        let clientDtKey = "client_dt"
        if !data.keys.contains(clientDtKey) {
            let clientDateTime = Date()
            data[clientDtKey] = iso8601Formatter.string(from: clientDateTime) as NSCoding
        }

        /*
         * Generated events have the session ID attached to them before stream
         * config is available (in case they're generated offline) and before
         * they're cc'd to any other streams (once config is available).
         */
        let sessionIDKey = "app_session_id"
        if !data.keys.contains(sessionIDKey) {
            data[sessionIDKey] = sessionID as NSCoding
        }

        #if DEBUG
        do {
            let jsonString = try data.toPrettyPrintJSONString()
            DDLogDebug("EPC: Event logged to stream '\(stream)':\n\(jsonString)")
        } catch let error {
            DDLogError("EPC: \(error.localizedDescription)")
        }
        #endif

        guard let streamConfigs = streamConfigurations else {
            let event: (stream: String, data: [String: NSCoding], domain: String?) = (stream: stream, data: data, domain: domain)
            appendEventToInputBuffer(event)
            return
        }

        if !(streamConfigs.keys.contains(stream)) {
            DDLogDebug("EPC: Event logged to '\(stream)' but only the following streams are configured: \(streamConfigs.keys.joined(separator: ", "))")
            return
        }

        guard let installID = self.installID else {
            DDLogError("EPC: Missing install ID. Fallbacking to not in sample.")
            return
        }
        
        if !inSample(stream: stream, deviceID: installID) {
            return
        }

        data["app_install_id"] = installID as NSCoding

        meta["stream"] = stream as NSCoding
        /*
         * meta.id is *optional* and should only be done in case the client is
         * known to send duplicates of events, otherwise we don't need to
         * make the payload any heavier than it already is
         */
        meta["id"] = UUID().uuidString as NSCoding
        data[metaKey] = meta as NSCoding // update metadata

        do {
            #if DEBUG
            let jsonString = try data.toJSONString()
            DDLogDebug("EPC: Scheduling event to be sent to \(streamIntakeServiceURI) with POST body: \(jsonString)")
            #endif
            networkManager.schedulePost(url: streamIntakeServiceURI, body: data as NSDictionary)
        } catch let error {
            DDLogError("EPC: \(error.localizedDescription)")
        }
    }
    
    /**
     * Passthrough method to tell `networkManager` to attempt to post its
     * scheduled events
     */
    @objc public func httpTryPost() {
        networkManager.httpTryPost()
    }

}

//MARK: Thread-safe accessors for collection properties

private extension EPC {

    /**
     * Thread-safe synchronous retrieval of buffered events
     */
    func getInputBuffer() -> [(stream: String, data: [String: NSCoding], domain: String?)] {
        queue.sync {
            return self.inputBuffer
        }
    }

    /**
     * Thread-safe synchronous buffering of an event
     * - Parameter event: event to be buffered
     */
    func appendEventToInputBuffer(_ event: (stream: String, data: [String: NSCoding], domain: String?)) {
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
                self.inputBuffer.remove(at: 0)
            }
            self.inputBuffer.append(event)
        }
    }

    /**
     * Thread-safe synchronous check if any events have been buffered
     * - Returns: `true` if there are no buffered events, `false` if there are
     */
    func inputBufferIsEmpty() -> Bool {
        queue.sync {
            return self.inputBuffer.count == 0
        }
    }

    /**
     * Thread-safe synchronous removal of buffered event at index
     * - Parameter index: The index from which to remove the buffered event in
     *   the event buffer.
     * - Returns: a previously buffered event
     */
    func removeInputBufferAtIndex(_ index: Int) -> (stream: String, data: [String: NSCoding], domain: String?)? {
        queue.sync {
            return self.inputBuffer.remove(at: index)
        }
    }

    /**
     * Thread-safe asynchronous caching of a stream's in-vs-out-of-sample
     * determination
     * - Parameter stream: name of stream to cache determination for
     * - Parameter inSample: whether the stream was determined to be in-sample
     *   this session
     */
    func cacheSamplingForStream(_ stream: String, inSample: Bool) {
        queue.async {
            self.samplingCache[stream] = inSample
        }
    }

    /**
     * Thread-safe synchronous retrieval of a stream's cached in-vs-out-of-sample determination
     * - Parameter stream: name of stream to retrieve determination for from the cache
     * - Returns: `true` if stream was determined to be in-sample this session, `false` otherwise
     */
    func getSamplingForStream(_ stream: String) -> Bool? {
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

//MARK: PeriodicWorker

extension EPC: PeriodicWorker {
    public func doPeriodicWork(_ completion: @escaping () -> Void) {
        networkManager.httpTryPost()
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
