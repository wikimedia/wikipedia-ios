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
public class EPC {

    struct Event {
        let stream: String
        let schema: String
        let data: [String: Any]
        let domain: String?
    }

    // MARK: - Properties

    // public static let shared = EPC() // singleton

    /**
     * Serial dispatch queue that makes `inputBuffer` and `samplingCache` thread-safe.
     */
    private let queue = DispatchQueue(label: "EventPlatformClient-" + UUID().uuidString)

    /**
     * See [wikitech:Event Platform/EventGate](https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate)
     * for more information. Specifically, the section on **eventgate-analytics-external**.
     */
    private let wmf_eventGateURI: String
    private let wmf_configURI: String
    /**
     * A safeguard against logging events while the app is in background state.
     */
    private var loggingEnabled: Bool
    /**
     * Holds each stream's configuration.
     */
    private var streamConfigurations: [String: [String: Any]]? = nil
    /**
     * Holds a map of which streams should be cc-ed when an event is logged to a particular stream.
     * See section on stream cc-ing in [mw:Wikimedia Product/Analytics Infrastructure/Stream configuration](https://www.mediawiki.org/wiki/Wikimedia_Product/Analytics_Infrastructure/Stream_configuration)
     */
    private var streamCopy = [String: [String]]()
    /**
     * Updated with every `log` call and when app enters background, used for determining if the
     * session has expired.
     */
    private var lastTimestamp: Date = Date()
    private var _sessionID: String? = nil
    
    private let iso8601Formatter: ISO8601DateFormatter

    /**
     * For persistent storage
     */
    private let storageManager: StorageManager

    /**
     * For handling HTTP requests
     */
    private let networkManager: NetworkManager

    /**
     * Store events until the library is finished initializing
     *
     * The EPC library makes an HTTP request to a remote stream configuration service for information
     * about how to evaluate incoming event data. Until this initialization is complete, we store any incoming
     * events in this buffer.
     *
     * Only modify (append events to, remove events from) asynchronously via `queue.async`
     */
    private var inputBuffer = [Event]()

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

    public init(network_manager: NetworkManager, storage_manager: StorageManager) {
        self.networkManager = network_manager
        self.storageManager = storage_manager

        wmf_eventGateURI = "https://intake-analytics.wikimedia.org/v1/events"
        wmf_configURI = "https://meta.wikimedia.org/w/api.php?action=streamconfigs&format=json"
        /* TODO: instead of baking in where to fetch stream configs from, fetch
         * from every language that the user has in their preferences, since
         * stream configurations can be deployed to all wikis and on a per-wiki
         * basis. Not sure how to merge configs for streams, though
         */
        iso8601Formatter = ISO8601DateFormatter()
        loggingEnabled = true

        recallBuffer()
        configure()
    }

    /**
     * Stores the input buffer of generated events in persistent storage and clears it
     */
    private func persistBuffer() {
        let inputBuffer = getInputBuffer()
        storageManager.setPersisted("epc_input_buffer", inputBuffer)
    }

    /**
     * Retrieves persisted input buffer and deletes it from storage
     *
     * Merges retrieved events with any existing events in `inputBuffer`.
     */
    private func recallBuffer() {
        storageManager.getPersisted("epc_input_buffer", completion: { value in
            guard let ib = value as? [Event] else {
                return
            }
            for event in ib {
                appendEventToInputBuffer(event)
            }
            storageManager.deletePersisted("epc_input_buffer")
        })
    }

    /**
     * This method is called by the application delegate in `applicationWillResignActive()` and
     * disables event logging.
     */
    public func appInBackground() {
        loggingEnabled = false
        lastTimestamp = Date()
    }
    /**
     * This method is called by the application delegate in `applicationDidBecomeActive()` and
     * re-enables event logging.
     *
     * If it has been more than 15 minutes since the app entered background state, a new session is started.
     */
    public func appInForeground() {
        loggingEnabled = true
        if sessionTimedOut() {
            beginNewSession()
        }
    }
    /**
     * This method is called by the application delegate in `applicationWillTerminate()`
     *
     * We do not persist session ID on app close because we have decided that a session ends when the
     * user (or the OS) has closed the app or when 15 minutes of inactivity have assed.
     */
    public func appWillClose() {
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
     * Unset the session
     */
    private func beginNewSession() -> Void {
        _sessionID = nil
        removeAllSamplingCache()
    }
    
    /**
    * Return a session identifier
    * - Returns: session ID
    *
    * The identifier is a string of 20 zero-padded hexadecimal digits representing a uniformly random
    * 80-bit integer.
    */
    private var sessionID: String {
        get {
            guard let sID = _sessionID else {
                let newID = generateID()
                _sessionID = newID
                return newID
            }

            return sID
        }
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
            networkManager.httpDownload(url: wmf_configURI, completion: {
                data in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Any]] else {
                        DDLogWarn("[EPC] Problem processing stream config from response")
                        return
                }
                setStreamConfig(from: json)
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

        streamConfigurations = config
        /*
         * Figure out which streams can be cc'd (e.g. edit ~> edit.growth).
         *
         * Stream cc-ing should be done only 1 level deep to avoid duplication.
         * For example, edits shouldn't cc edits.growth AND edits.growth.test,
         * since edits.growth.test would be cc'd by edits.growth.
         *
         * Instead of working stream by stream to find children streams for each
         * parent stream, we work backwards by constructing parent streams from
         * children streams. This enables children streams such as
         * 'edits.growth' to be cc'd when logging events to 'edits' even when
         * parent stream 'edits' is not present in the stream configuration.
         *
         * Refer to mw:Wikimedia_Product/Analytics_Infrastructure/Stream_configuration#Stream_cc-ing
         * for additional documentation.
         */
        for stream in config.keys {
            let s = stream.split(separator: ".")
            let nPrefixes = s.count - 1
            if nPrefixes > 1 {
                for i in 1...nPrefixes {
                    let child = s[0...i].joined(separator: ".")
                    let parent = s[0..<i].joined(separator: ".")
                    streamCopy.appendIfNew(key: parent, value: child)
                }
            } else if nPrefixes == 1 {
                streamCopy.appendIfNew(key: String(s[0]), value: stream)
            }
        }

        #if DEBUG
        do {
            let jsonString = try streamCopy.toPrettyPrintJSONString()
            DDLogDebug("[EPC] Map of streams to CC:\n\(jsonString)")
        } catch let error {
            DDLogError("[EPC] \(error.localizedDescription)")
        }
        #endif

        var cachedEvent: Event
        while !inputBufferIsEmpty() {
            cachedEvent = removeInputBufferAtIndex(0)
            self.log(stream: cachedEvent.stream,
                     schema: cachedEvent.schema,
                     data: cachedEvent.data,
                     domain: cachedEvent.domain)
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
    private func inSample(stream: String) -> Bool {

        guard let configs = streamConfigurations else {
            DDLogDebug("[EPC] Invalid state, must have streamConfigurations to check for inSample")
            return false
        }
        
        if let cachedValue = getSamplingCacheForKey(stream) {
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
            setSamplingCacheForKey(stream, value: true)
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
            setSamplingCacheForKey(stream, value: true)
            return true
        }

        /*
         * All platforms use session ID as the default identifier for
         * determining in- vs out-of-sample of events sent to streams. On the
         * web, streams can be set to use pageview token instead. On the apps,
         * streams can be set to use device token instead.
         */
        let identifierType = samplingConfig["identifier"] as? String ?? "session"

        guard identifierType == "session" || identifierType == "device" else {
            setSamplingCacheForKey(stream, value: false)
            return false
        }

        let identifier = identifierType == "session" ? sessionID : storageManager.deviceID
        let result = determine(identifier, rate)
        setSamplingCacheForKey(stream, value: result)
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
    public func log(stream: String, schema: String, data: [String: Any], domain: String? = nil) -> Void {
        guard loggingEnabled else {
            return
        }

        var meta: [String: String] = data["meta"] as? [String: String] ?? [:]

        if let domain = domain {
            meta["domain"] = domain
        }

        var data = data
        data["meta"] = meta

        /*
         * The top-level field `client_dt` is for recording the time the event
         * was generated. EventGate sets `meta.dt` during ingestion, so for
         * analytics events that field is used as "timestamp of reception" and
         * is used for partitioning the events in the database. See Phab:T240460
         * for more information.
         */
        if !data.keys.contains("client_dt") {
            let clientDateTime = Date()
            data["client_dt"] = iso8601Formatter.string(from: clientDateTime)
            lastTimestamp = clientDateTime
        }

        /*
         * Generated events have the session ID attached to them before stream
         * config is available (in case they're generated offline) and before
         * they're cc'd to any other streams (once config is available).
         */
        if !data.keys.contains("session_id") {
            data["session_id"] = sessionID
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
            let event = Event(stream: stream, schema: schema, data: data, domain: domain)
            appendEventToInputBuffer(event)
            return
        }

        // CC to other streams, even if this stream does not exist
        if let copiedStreams = streamCopy[stream] {
            for ccStream in copiedStreams {
                DDLogDebug("[EPC] CC-ing stream '\(ccStream)' from stream '\(stream)'")
                log(stream: ccStream, schema: schema, data: data, domain: domain)
            }
        }

        if !(streamConfigs.keys.contains(stream)) {
            return
        }

        if !inSample(stream: stream) {
            return
        }

        data["device_id"] = storageManager.deviceID
        /*
         * EventGate needs to know which version of the schema to validate
         * against (e.g. '/mediawiki/client/error/1.0.0')
         */
        data["$schema"] = schema

        meta["stream"] = stream
        /*
         * meta.id is *optional* and should only be done in case the client is
         * known to send duplicates of events, otherwise we don't need to
         * make the payload any heavier than it already is
         */
        meta["id"] = UUID().uuidString // UUID with RFC 4122 v4 random bytes
        data["meta"] = meta // update metadata

        do {
            let jsonString = try data.toJSONString()
            DDLogDebug("[EPC] Sending HTTP request to \(wmf_eventGateURI) with POST body: \(jsonString)")
            networkManager.httpPost(url: wmf_eventGateURI, body: jsonString)
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
    public func logger(schema: String) -> (String, [String: Any], String?) -> Void {
        func l(stream: String, data: [String: Any], domain: String? = nil) -> Void {
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
    public func logger(stream: String, schema: String, version: String) -> ([String: Any], String?) -> Void {
        func l(data: [String: Any], domain: String? = nil) -> Void {
            self.log(stream: stream, schema: schema, data: data, domain: domain)
        }
        return l
    }
    
    // input buffer helpers
    func getInputBuffer() -> [Event] {
        queue.sync {
            return self.inputBuffer
        }
    }
    
    func appendEventToInputBuffer(_ event: Event) {
        queue.async {
            self.inputBuffer.append(event)
        }
    }
    
    func inputBufferIsEmpty() -> Bool {
        queue.sync {
            return self.inputBuffer.isEmpty
        }
    }
    
    func removeInputBufferAtIndex(_ index: Int) -> Event {
        queue.sync {
            return self.inputBuffer.remove(at: index)
        }
    }
    
    //sampling cache helpers
    func setSamplingCacheForKey(_ key: String, value: Bool) {
        queue.async {
            self.samplingCache[key] = value
        }
    }
    
    func getSamplingCacheForKey(_ key: String) -> Bool? {
        queue.sync {
            return self.samplingCache[key]
        }
    }
    
    func removeAllSamplingCache() {
        queue.async {
            self.samplingCache.removeAll()
        }
    }
}
