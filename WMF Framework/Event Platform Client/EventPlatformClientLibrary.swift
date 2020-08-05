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
 * The static public API via the `shared` singleton allows callers to log events. Use `log` to submit an
 * event to a specific stream, cc'ing derivative streams automatically. For additional information on
 * instrumentation with the Modern Event Platform and the Event Platform Client libraries, please refer to the
 * following resources:
 * - [mw:Wikimedia Product/Analytics Infrastructure/Event Platform Client](https://www.mediawiki.org/wiki/Wikimedia_Product/Analytics_Infrastructure/Event_Platform_Client)
 * - [wikitech:Event Platform/Instrumentation How To](https://wikitech.wikimedia.org/wiki/Event_Platform/Instrumentation_How_To)
 *
 * **Note**: Events generated while offline are persisted between sessions until stream configuration has
 * been downloaded and the events can be properly processed.
 *
 * ## Logging API
 *
 * - `log(stream, schema, version, data, domain?)` to log events; can be called before
 *   configuration is available or even offline
 * - `logger(schema, version)` to generate a shortcut to `log` for logging multiple events using the
 *   same schema version, without having to specify those in every call
 * - `logger(stream, schema, version)` to generate a shortcut to `log` for logging multiple
 *   events using the same stream name and schema version, without having to specify those in every call
 *
 * ## Dependencies
 *
 * EPC relies on some functionality to be made available to it by the rest of the application. It depends on:
 * - a `NetworkManager` which can `HTTP POST` requests and download data
 * - a `StorageManager` which can persist data and recall or delete persisted data
 *
 * We describe the desired behaviors for both of those in EventPlatformClientProtocols.swift
 */

class EPCBufferEvent: NSObject, NSCoding {
    
    func encode(with coder: NSCoder) {
        
        coder.encode(self.stream, forKey: "stream")
        coder.encode(self.schema, forKey: "schema")
        coder.encode(self.data, forKey: "data")
        coder.encode(self.domain, forKey: "domain")
    }
    
    required convenience init?(coder: NSCoder) {
        guard let stream = coder.decodeObject(forKey: "stream") as? String,
            let schema = coder.decodeObject(forKey: "schema") as? String,
            let data = coder.decodeObject(forKey: "data") as? [String : NSCoding]
            else {
                return nil
        }
        
        let domain = coder.decodeObject(forKey: "domain") as? String
        
        self.init(stream: stream, schema: schema, data: data, domain: domain)
    }
    
    let stream: String
    let schema: String
    let data: [String: NSCoding]
    let domain: String?
    
    init(stream: String, schema: String, data: [String: NSCoding], domain: String?) {
        self.stream = stream
        self.schema = schema
        self.data = data
        self.domain = domain
    }
}

@objc (WMFEventPlatformClient)
public class EPC: NSObject {

    // MARK: - Properties

    @objc(sharedInstance) public static let shared: EPC? = {
        guard let storageManager = EPCStorageManager.shared else {
            return nil
        }
        
        let networkManager = EPCNetworkManager(storageManager: storageManager)
        return EPC(networkManager: networkManager, storageManager: storageManager)
    }()

    /**
     * Serial dispatch queue that properties thread-safe
     */
    private let queue = DispatchQueue(label: "EventPlatformClient-" + UUID().uuidString)

    /**
     * See [wikitech:Event Platform/EventGate](https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate)
     * for more information. Specifically, the section on **eventgate-analytics-external**.
     */
    private let eventGateURI: URL
    private let configURI: URL
    
    /**
    * Key constants
    */
    private let inputBufferKey = "epc_input_buffer"
    
    /**
     * A safeguard against logging events while the app is in background state
     */
    private var loggingEnabled: Bool {
           get {
               queue.sync {
                   return _loggingEnabled
               }
           }
        set {
            queue.async {
                self._loggingEnabled = newValue
            }
        }
    }
    private var _loggingEnabled: Bool = true
    
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
     * For persistent storage
     */
    private let storageManager: EPCStorageManaging

    /**
     * For handling HTTP requests
     */
    private let networkManager: EPCNetworkManaging

    /**
     * Store events until the library is finished initializing
     *
     * The EPC library makes an HTTP request to a remote stream configuration service for information
     * about how to evaluate incoming event data. Until this initialization is complete, we store any incoming
     * events in this buffer.
     *
     * Only modify (append events to, remove events from) asynchronously via `queue.async`
     */
    private var inputBuffer: NSArray = []

    /**
     * Cache of "in sample" / "out of sample" determination for each stream
     *
     * The process of determining only has to happen the first time an event is logged to a stream for
     * which stream configuration is available. All other times `in_sample` simply returns the cached
     * determination.
     *
     * Only cache determinations asynchronously via `queue.async`
     */
    private var samplingCache: [String: Bool] = [String: Bool]()

    // MARK: - Methods

    private init?(networkManager: EPCNetworkManaging, storageManager: EPCStorageManaging) {
        self.networkManager = networkManager
        self.storageManager = storageManager
        
        guard let eventGateURI = URL(string: "https://intake-analytics.wikimedia.org/v1/events"),
            let configURI = URL(string: "https://meta.wikimedia.org/w/api.php?action=streamconfigs&format=json") else {
                DDLogError("EventPlatformClientLibrary - Unable to instantiate uris")
                return nil
        }

        self.eventGateURI = eventGateURI
        self.configURI = configURI
        
        /* TODO: instead of baking in where to download stream configs from, we
         * may need to download from every language that the user has in their
         * preferences, since stream configurations can be deployed to all wikis
         * and on a per-wiki basis. Would need to merge somehow, though!
         */
        iso8601Formatter = ISO8601DateFormatter()
        
        super.init()

        loggingEnabled = true
        recallBuffer()
        configure()
    }

    /**
     * Stores the input buffer of generated events in persistent storage and clears it
     */
    private func persistBuffer() {
        let inputBuffer = getInputBuffer()
        storageManager.setPersisted(inputBufferKey, inputBuffer)
    }

    /**
     * Retrieves persisted input buffer and deletes it from storage
     *
     * Merges retrieved events with any existing events in `inputBuffer`.
     */
    private func recallBuffer() {
        
        guard let events = storageManager.getPersisted(inputBufferKey) as? [EPCBufferEvent] else {
            return
        }
        
        for event in events {
            appendEventToInputBuffer(event)
        }
        
        storageManager.deletePersisted(inputBufferKey)
    }

    /**
     * This method is called by the application delegate in `applicationWillResignActive()` and
     * disables event logging.
     */
    @objc public func appInBackground() {
        loggingEnabled = false
        lastTimestamp = Date()
    }
    /**
     * This method is called by the application delegate in `applicationDidBecomeActive()` and
     * re-enables event logging.
     *
     * If it has been more than 15 minutes since the app entered background state, a new session is started.
     */
    @objc public func appInForeground() {
        loggingEnabled = true
        if sessionTimedOut() {
            resetSession()
        }
    }
    /**
     * This method is called by the application delegate in `applicationWillTerminate()`
     *
     * We do not persist session ID on app close because we have decided that a session ends when the
     * user (or the OS) has closed the app or when 15 minutes of inactivity have assed.
     */
    @objc public func appWillClose() {
        loggingEnabled = false
        persistBuffer()
    }

    /**
     * Generates a new identifier using the same algorithm as EPC libraries for web and Android
     */
    private func generateID() -> String {
        var id: String = ""
        for _ in 1...8 {
            id += String(format: "%04x", arc4random_uniform(65535))
        }
        return id
    }
    
    /**
    * Called when user toggles logging permissions in Settings.
    * This assumes storageManager's deviceID will be reset separately by a different owner (EventLoggingService's reset method)
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
     * A new session ID is required if it has been more than 15 minutes since the user was last active
     * (e.g. when app entered background).
     */
    private func sessionTimedOut() -> Bool {
        /*
         * A TimeInterval value is always specified in seconds.
         */
        return lastTimestamp.timeIntervalSinceNow < -900
    }

    /**
     * Download stream configuration and use it to instantiate `CONFIG` asynchronously when a network
     * manager is available
     */
    private func configure() -> Void {
        /*
         * Assume that the network manager will keep trying to download the
         * stream configuration and that it will hold off on trying to download
         * if there is no connectivity.
         */

        if streamConfigurations == nil {
            networkManager.httpDownload(url: configURI, completion: {
                data in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Any]] else {
                        DDLogWarn("[EPC] Problem processing stream config from response")
                        return
                }
                self.setStreamConfig(from: json)
            })
        }
    }

    /**
     * Called by `configure`'s completion handler after stream configuration has been downloaded and
     * processed into a dictionary
     */
    private func setStreamConfig(from config: [String : [String : Any]]) -> Void {

        #if DEBUG
        do {
            let jsonString = try config.toPrettyPrintJSONString()
            DDLogDebug("[EPC] Loaded stream configurations:\n\(jsonString)")
        } catch let error {
            DDLogError("[EPC] \(error.localizedDescription)")
        }
        #endif

        // example retrieved config: {"streams":{"test.event":[],"test.event.sampled":{"sampling":{"rate":0.1}}}}
        guard let _ = config["streams"] as? [String: [String: Any]] else {
            DDLogWarn("[EPC] Problem processing downloaded stream configurations")
            return;
        }

        // Make them available to any newly logged events before flushing buffer
        self.streamConfigurations = config
        
        // Process event buffer after making stream configs and cc map available
        var cachedEvent: EPCBufferEvent?
        while !inputBufferIsEmpty() {
            cachedEvent = removeInputBufferAtIndex(0)
            if let cachedEvent = cachedEvent {
                self.log(stream: cachedEvent.stream,
                schema: cachedEvent.schema,
                data: cachedEvent.data,
                domain: cachedEvent.domain)
            }
        }
    }

    /**
     * Yields a deterministic (not stochastic) determination of whether the provided `id` is
     * in-sample or out-of-sample according to the `acceptance` rate
     * - Parameter id: either session ID generated with `generateID` or the app install ID
     * generated with `UUID().uuidString`
     * - Parameter acceptance: the desired proportion of many `token`-s being accepted
     *
     * The algorithm works in a "widen the net on frozen fish" fashion -- tokens continue evaluating to
     * true as the acceptance rate increases. For example, a device determined to be in-sample for a
     * stream "A" having rate 0.1 will be determined to be in-sample for a stream "B" having rate 0.2,
     * and its events will show up in tables "A" and "B".
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
     * The determinations are lazy and cached, so each stream's in-sample vs out-of-sample determination
     * is computed only once, the first time an event is logged to that stream.
     *
     * Refer to sampling settings section in
     * [mw:Wikimedia Product/Analytics Infrastructure/Stream configuration](https://www.mediawiki.org/wiki/Wikimedia_Product/Analytics_Infrastructure/Stream_configuration)
     * for more information.
     */
    private func inSample(stream: String, deviceID: String) -> Bool {

        guard let configs = streamConfigurations else {
            DDLogDebug("[EPC] Invalid state, must have streamConfigurations to check for inSample")
            return false
        }

        if let cachedValue = getSamplingForStream(stream) {
            return cachedValue
        }

        guard let config = configs[stream] else {
            DDLogError("[EPC] Invalid state, stream '\(stream)' must be present in streamConfigurations to check for inSample")
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
             * If stream doesn't have a rate, assume 1.0 (always in-sample).
             * Cache this determination for any future use.
             */
            cacheSamplingForStream(stream, inSample: true)
            return true
        }

        /*
         * All platforms use session ID as the default identifier for
         * determining in- vs out-of-sample of events sent to streams. On the
         * web, streams can be set to use pageview token instead. On the apps,
         * streams can be set to use device token instead.
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
     * Log an event to a stream
     * - Parameters:
     *      - stream: Name of the event stream to send the event to
     *      - schema: Name and version of schema that the instrumentation conforms to
     *      - data: A dictionary of event data, appropriate for schema version
     *      - domain: An optional domain to include for the even
     *
     * Regarding `schema`, the instrumentation needs to specify which schema (and specifically which
     * version of that schema) it conforms to. Analytics schemas can be found in the jsonschema directory of
     * [secondary repo](https://gerrit.wikimedia.org/r/plugins/gitiles/schemas/event/secondary/)
     *
     * As an example, if instrumenting client-side error logging, a possible `schema` would be
     * `/mediawiki/client/error/1.0.0`. For the most part, the `schema` will start with
     * `/analytics`, since there's where analytics-related schemas are collected.
     *
     * Regarding `domain`: this is *optional* and should be used when event needs to be attrributed to a
     * particular wiki (Wikidata, Wikimedia Commons, a specific edition of Wikipedia, etc.). If the language is
     * NOT relevant in the context, `domain` can be safely omitted. Using "domain" rather than "language"
     * is consistent with the other platforms and allows for the possibility of setting a non-Wikipedia domain
     * like "commons.wikimedia.org" and "wikidata.org" for multimedia/metadata-related in-app analytics.
     *
     * Cases where instrumentation would set a `domain`:
     * - reading or editing an article
     * - managing watchlist
     * - interacting with feed
     * - searching
     *
     * Cases where it might not be necessary for instrumentation to set a `domain`:
     * - changing settings
     * - managing reading lists
     * - navigating map of nearby articles
     * - multi-lingual features like Suggested Edits
     * - marking session start/end; in which case schema and `data` should have a `languages` field
     *   where user's list of languages can be stored, although it might make sense to set it to the domain
     *   associated with the user's 1st preferred language – in which case use
     *   `MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL()!.host!`
     */
    @objc public func log(stream: String, schema: String, data: [String: NSCoding], domain: String? = nil) -> Void {
        guard loggingEnabled, storageManager.sharingUsageData else {
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
            lastTimestamp = clientDateTime
        }

        /*
         * Generated events have the session ID attached to them before stream
         * config is available (in case they're generated offline) and before
         * they're cc'd to any other streams (once config is available).
         */
        let sessionIDKey = "session_id"
        if !data.keys.contains(sessionIDKey) {
            data[sessionIDKey] = sessionID as NSCoding
        }

        #if DEBUG
        do {
            let jsonString = try data.toPrettyPrintJSONString()
            DDLogDebug("[EPC] Event logged to stream '\(stream)' (schema: \(schema):\n\(jsonString)")
        } catch let error {
            DDLogError("[EPC] \(error.localizedDescription)")
        }
        #endif

        guard let streamConfigs = streamConfigurations else {
            let event = EPCBufferEvent(stream: stream, schema: schema, data: data, domain: domain)
            appendEventToInputBuffer(event)
            return
        }

        if !(streamConfigs.keys.contains(stream)) {
            return
        }

        guard let deviceID = storageManager.deviceID else {
            DDLogError("EPCStorageManager is missing it's deviceID. Fallbacking to not in sample.")
            return
        }
        
        if !inSample(stream: stream, deviceID: deviceID) {
            return
        }

        data["device_id"] = deviceID as NSCoding
        /*
         * EventGate needs to know which version of the schema to validate
         * against (e.g. '/mediawiki/client/error/1.0.0')
         */
        data["$schema"] = schema as NSCoding

        meta["stream"] = stream as NSCoding
        /*
         * meta.id is *optional* and should only be done in case the client is
         * known to send duplicates of events, otherwise we don't need to
         * make the payload any heavier than it already is
         */
        meta["id"] = UUID().uuidString as NSCoding // UUID with RFC 4122 v4 random bytes
        data[metaKey] = meta as NSCoding // update metadata

        do {
            let jsonString = try data.toJSONString()
            DDLogDebug("[EPC] Sending HTTP request to \(eventGateURI) with POST body: \(jsonString)")
            networkManager.httpPost(url: eventGateURI, body: data as NSDictionary)
        } catch let error {
            DDLogError("[EPC] \(error.localizedDescription)")
        }
    }

    /**
     * Generate a reusable event logger with a specific schema version
     * - Parameter schema: Versioned name of the schema the stream (and any cc'd streams) conforms to
     * - Returns: A function with the following parameters: `stream` (string),  `data` (dictionary), and
     * `domain` (optional string). This is just a shortcut to `EPC.shared.log()` but without having to
     * specify the schema name and version in every call.
     */
    @objc public func logger(schema: String) -> (String, [String: NSCoding], String?) -> Void {
        func l(stream: String, data: [String: NSCoding], domain: String? = nil) -> Void {
            self.log(stream: stream, schema: schema, data: data, domain: domain)
        }
        return l
    }

    /**
     * Generate a reusable event logger with a specific schema version and stream
     * - Parameters:
     *      - stream: Name of the event stream to send the event to
     *      - schema: Versioned name of the schema the stream (and any cc'd streams) conforms to
     * - Returns: A function with the following parameters: `data` (dictionary), and `domain`
     * (optional string). This is just a shortcut to `EPC.shared.log()` but without having to specify the
     * stream, schema name, and schema version in every call.
    */
    @objc public func logger(stream: String, schema: String, version: String) -> ([String: NSCoding], String?) -> Void {
        func l(data: [String: NSCoding], domain: String? = nil) -> Void {
            self.log(stream: stream, schema: schema, data: data, domain: domain)
        }
        return l
    }
    
    /**
     * Passthrough method to tell networkManager to attempt to post it's queued events
     * - Parameters:
     *      - completion: Completion block to be called once posts complete
    */
    @objc public func httpTryPost(completion: (() -> Void)?) {
        networkManager.httpTryPost(completion)
    }

}

//MARK: Thread-safe accessors for collection properties

private extension EPC {
    
    func getInputBuffer() -> NSArray {
        queue.sync {
            return self.inputBuffer
        }
    }

    func appendEventToInputBuffer(_ event: EPCBufferEvent) {
        queue.async {
            let mutableInputBuffer = NSMutableArray(array: self.inputBuffer)
            mutableInputBuffer.add(event)
            self.inputBuffer = NSArray(array: mutableInputBuffer)
        }
    }

    func inputBufferIsEmpty() -> Bool {
        queue.sync {
            return self.inputBuffer.count == 0
        }
    }

    func removeInputBufferAtIndex(_ index: Int) -> EPCBufferEvent? {
        queue.sync {
            let mutableInputBuffer = NSMutableArray(array: self.inputBuffer)
            let object = mutableInputBuffer.object(at: index) as? EPCBufferEvent
            mutableInputBuffer.removeObject(at: index)
            self.inputBuffer = NSArray(array: mutableInputBuffer)
            return object
        }
    }
    
    func cacheSamplingForStream(_ stream: String, inSample: Bool) {
        queue.async {
            self.samplingCache[stream] = inSample
        }
    }

    func getSamplingForStream(_ stream: String) -> Bool? {
        queue.sync {
            return self.samplingCache[stream]
        }
    }

    func removeAllSamplingCache() {
        queue.async {
            self.samplingCache.removeAll()
        }
    }
}

//MARK: PeriodicWorker

extension EPC: PeriodicWorker {
    public func doPeriodicWork(_ completion: @escaping () -> Void) {
        networkManager.httpTryPost(completion)
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
