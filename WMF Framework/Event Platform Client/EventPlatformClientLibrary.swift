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
 * AUTHORS
 *     Mikhail Popov <mpopov@wikimedia.org>
 *     Jason Linehan <jlinehan@wikimedia.org>
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
 * **Note**: have not been able to get this into Dictionary+JSON.swift without getting "inaccessible due to
 * 'internal' protection level" error when actually trying to use these methods.
 */
extension Dictionary {
    /**
     * This enables us to pass a `[String: Any]` dictionary to`EPC.shared.log()` from anywhere
     * in the app.
     *  - Returns: JSON string representation of the object
     */
    var jsonDescription: String {
        get {
            let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [])
            let jsonString = String(data: jsonData!, encoding: .utf8)!
            return jsonString
        }
    }
    var prettyPrintJSON: String {
        get {
            let jsonData = try? JSONSerialization.data(
                withJSONObject: self,
                options: [JSONSerialization.WritingOptions.prettyPrinted]
            )
            let jsonString = String(data: jsonData!, encoding: .utf8)!
            return jsonString
        }
    }
}

extension Dictionary where Key == String, Value == [String] {
    /**
     * Convenience function that appends `value` to an existing string array, but only if that value does not
     * already exist in the array
     * - Parameter key: key under which to find or create the string array
     * - Parameter value: value to append to the string array or use as the first value of a new one
     */
    mutating func append_if_new(key: String, value: String) {
        if self.keys.contains(key) {
            if !self[key]!.contains(value) {
                self[key]!.append(value)
            }
        } else {
            self[key] = [value]
        }
    }
}

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

    // MARK: - Properties

    public static let shared = EPC() // singleton

    /**
     * See [wikitech:Event Platform/EventGate](https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate)
     * for more information. Specifically, the section on **eventgate-analytics-external**.
     */
    private let EVENTGATE_URI: String
    private let CONFIG_URI: String
    /**
     * `ENABLED` is a safeguard against logging events while the app is in background state.
     */
    private var ENABLED: Bool
    private var CONFIG: [String: [String: Any]]? = nil
    private var COPIED = [String: [String]]()
    /**
     * Updated with every `log` call, used for determining if session expired.
     */
    private var LAST_TS: Date = Date()
    private var SESSION_ID: String? = nil
    private var DEVICE_ID: String? = nil
    private let ISO8601_FORMATTER: ISO8601DateFormatter

    /**
     * For persistent storage
     */
    private var storage_manager: StorageManager?

    /**
     * For handling HTTP requests
     */
    private var network_manager: NetworkManager?

    /**
     * Store events until the library is finished initializing
     *
     * The EPC library makes an HTTP request to a remote stream configuration service for information
     * about how to evaluate incoming event data. Until this initialization is complete, we store any incoming
     * events in this buffer.
     */
    private var input_buffer = [(stream: String, schema: String, data: [String: Any], domain: String?)]()

    /**
     * Cache of "in sample" / "out of sample" determination for each stream
     *
     * The process of determining only has to happen the first time an event is logged to a stream for
     * which stream configuration is available. All other times `in_sample` simply returns the cached
     * determination.
     */
    private var cache: [String: Bool] = [String: Bool]()

    // MARK: - Methods

    private init() {
        EVENTGATE_URI = "https://intake-analytics.wikimedia.org/v1/events"
        CONFIG_URI = "https://meta.wikimedia.org/w/api.php?action=streamconfigs&format=json"
        ISO8601_FORMATTER = ISO8601DateFormatter()
        ENABLED = true
    }

    /**
     * Tell which storage manager EPC should use
     *
     * ERROR: Method cannot be declared public because its parameter uses an internal type
     */
    public func set_storage_manager(_ sm: StorageManager) {
        storage_manager = sm
        recall_buffer()
    }

    /**
     * Tell which network manager EPC should use
     *
     * ERROR: Method cannot be declared public because its parameter uses an internal type
     */
    public func set_network_manager(_ nm: NetworkManager) {
        network_manager = nm
        configure()
    }

    /**
     * Stores the input buffer of generated events in persistent storage and clears it
     */
    private func persist_buffer() {
        storage_manager?.set_persisted("epc_input_buffer", input_buffer)
    }

    /**
     * Retrieves persisted input buffer and deletes it from storage
     *
     * Merges retrieved events with any existing events in `input_buffer`.
     */
    private func recall_buffer() {
        storage_manager?.get_persisted("epc_input_buffer", completion: {
            value in
            if value != nil {
                let ib = value as! [(stream: String, schema: String, domain: String, data: [String: Any])]
                for e in ib {
                    input_buffer.append(e)
                }
                storage_manager!.del_persisted("epc_input_buffer")
            }
        })
    }

    /**
     * This method is called by the application delegate in `applicationWillResignActive()` and
     * disables event logging.
     */
    public func app_in_background() {
        ENABLED = false
    }
    /**
     * This method is called by the application delegate in `applicationDidBecomeActive()` and
     * re-enables event logging.
     *
     * If it has been more than 15 minutes since the app entered background state, a new session is started.
     */
    public func app_in_foreground() {
        ENABLED = true
        if session_timed_out() {
            begin_new_session()
        }
    }
    /**
     * This method is called by the application delegate in `applicationWillTerminate()`
     *
     * We do not persist session ID on app close because we have decided that a session ends when the
     * user (or the OS) has closed the app or when 15 minutes of inactivity have assed.
     */
    public func app_will_close() {
        ENABLED = false
        persist_buffer()
    }

    /**
     * Generates a new identifier using the same algorithm as EPC libraries for web and Android
     */
    private func generate_id() -> String {
        var id: String = ""
        for _ in 1...8 {
            id += String(format: "%04x", arc4random_uniform(65535))
        }
        return id
    }

    /**
     * Unset the session
     */
    private func begin_new_session() -> Void {
        SESSION_ID = nil
        cache.removeAll()
    }

    /**
     * Generate a session identifier
     * - Returns: session ID
     *
     * The identifier is a string of 20 zero-padded hexadecimal digits representing a uniformly random
     * 80-bit integer.
     */
    public func session_id() -> String {
        if SESSION_ID == nil {
            SESSION_ID = generate_id()
        }
        return SESSION_ID!
    }

    /**
     * Returns the app install ID stored on the device
     */
    public func device_id() -> String {
        if DEVICE_ID == nil {
            DEVICE_ID = EventLoggingService.shared?.appInstallID!
        }
        return DEVICE_ID!
    }

    /**
     * Check if session expired, based on last active timestamp
     *
     * A new session ID is required if it has been more than 15 minutes since the user was last active
     * (e.g. when app entered background).
     */
    private func session_timed_out() -> Bool {
        /*
         * A TimeInterval value is always specified in seconds.
         */
        return LAST_TS.timeIntervalSinceNow < -900
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
        if CONFIG == nil {
            network_manager!.http_download(url: CONFIG_URI, completion: {
                data in
                let from_json = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: [String: Any]]
                if from_json != nil {
                    self.set_stream_config(from_json!)
                } else {
                    print("Problem processing stream config from response")
                }
            })
        }
    }

    /**
     * Called by `configure`'s completion handler after stream configuration has been downloaded and
     * processed into a dictionary
     */
    private func set_stream_config(_ config: [String : [String : Any]]) -> Void {
        print("[EPC] Loaded stream configuration:\n\(config.prettyPrintJSON)")
        CONFIG = config
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
            let n_prefixes = s.count - 1
            if n_prefixes > 1 {
                for i in 1...n_prefixes {
                    let child = s[0...i].joined(separator: ".")
                    let parent = s[0..<i].joined(separator: ".")
                    COPIED.append_if_new(key: parent, value: child)
                }
            } else if n_prefixes == 1 {
                COPIED.append_if_new(key: String(s[0]), value: stream)
            }
        }
        print("[EPC] Stream cc-ing:\n\(COPIED.prettyPrintJSON)")
        if CONFIG != nil && input_buffer.count > 0 {
            var cached_event: (stream: String, schema: String, data: [String: Any], domain: String?)? = input_buffer.remove(at: 0)
            while cached_event != nil {
                log(stream: cached_event!.stream,
                    schema: cached_event!.schema,
                    data: cached_event!.data, domain: cached_event!.domain)
                cached_event = input_buffer.remove(at: 0) // next
            }
        }
    }

    /**
     * Yields a deterministic (not stochastic) determination of whether the provided `id` is
     * in-sample or out-of-sample according to the `acceptance` rate
     * - Parameter id: either session ID generated with `generate_id` or the app install ID
     * generated with `UUID().uuidString`
     * - Parameter acceptance: the desired proportion of many `token`-s being accepted
     *
     * The algorithm works in a "widen the net on frozen fish" fashion -- tokens continue evaluating to
     * true as the acceptance rate increases. For example, a device determined to be in-sample for a
     * stream "A" having rate 0.1 will be determined to be in-sample for a stream "B" having rate 0.2,
     * and its events will show up in tables "A" and "B".
     */
    private func determine(_ id: String, _ acceptance: Double) -> Bool {
        let token: UInt32 = UInt32(id.prefix(8), radix: 16)!
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
    private func in_sample(stream: String) -> Bool {

        if !cache.keys.contains(stream) {
            let stream_entry: [String: Any] = CONFIG![stream]!
            if stream_entry.keys.contains("config") {
                let stream_config = stream_entry["config"] as! [String: Any]
                if stream_config.keys.contains("sampling") {
                    let sampling_config = stream_config["sampling"] as! [String: Any]
                    /*
                     * If cache does not have a determination for stream,
                     * generate one.
                     */
                    if !sampling_config.keys.contains("rate") {
                        /*
                         * If stream doesn't have a rate, assume 1.0 (always
                         * in-sample). Cache this determination for any future
                         * use.
                         */
                        cache[stream] = true
                    } else {
                        /*
                         * All platforms use session ID as the default
                         * identifier for determining in- vs out-of-sample of
                         * events sent to streams. On the web, streams can be
                         * set to use pageview token instead. On the apps,
                         * streams can be set to use device token instead.
                         */
                        var identifier = "session"
                        if sampling_config.keys.contains("identifier") {
                            identifier = sampling_config["identifier"] as! String
                            if identifier != "session" && identifier != "device" {
                                cache[stream] = false
                                return false
                            }
                            identifier = identifier == "session" ? session_id() : device_id()
                            let rate = sampling_config["rate"]! as! Double
                            cache[stream] = determine(identifier, rate)
                        } // end if there's identifier in sampling config
                    } // end if there's rate in sampling config
                } // end if there's a sampling config
            } // end if there's a config
        } // end if there's no cached determination
        return cache[stream]!
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
        if !ENABLED {
            return
        }
        var meta: [String: String]
        if data.keys.contains("meta") {
            meta = data["meta"]! as! [String: String]
        } else {
            meta = [String: String]()
        }
        if domain != nil {
            meta["domain"] = domain!
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
            LAST_TS = Date()
            data["client_dt"] = ISO8601_FORMATTER.string(from: LAST_TS)
        }

        /*
         * Generated events have the session ID attached to them before stream
         * config is available (in case they're generated offline) and before
         * they're cc'd to any other streams (once config is available).
         */
        if !data.keys.contains("session_id") {
            data["session_id"] = session_id()
        }

        if CONFIG == nil {
            input_buffer.append((stream, schema, data, domain))
            return
        } else {
            // CC to other streams, even if this stream does not exist
            if COPIED.keys.contains(stream) {
                for cc_stream in COPIED[stream]! {
                    log(stream: cc_stream, schema: schema, data: data, domain: domain)
                }
            }
            if !(CONFIG!.keys.contains(stream)) {
                return
            }
        }

        if !in_sample(stream: stream) {
            return
        }

        data["device_id"] = device_id()
        /*
         * EventGate needs to know which version of the schema to validate
         * against (e.g. '/mediawiki/client/error/1.0.0')
         */
        data["$schema"] = schema

        meta["stream"] = stream
        /*
         * meta.id is optional and should only be done in case the client is
         * known to send duplicates of events, otherwise we don't need to
         * make the payload any heavier than it already is
         */
        meta["id"] = UUID().uuidString // UUID with RFC 4122 v4 random bytes
        data["meta"] = meta // update metadata

        network_manager!.http_post(url: EVENTGATE_URI, body: data.jsonDescription)

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

}
