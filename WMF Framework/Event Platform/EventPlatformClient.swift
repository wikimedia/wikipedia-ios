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
 *     Copyright 2020 Wikimedia Foundation
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
import CocoaLumberjackSwift
import WMFData

/**
 * Event Platform Client (EPC)
 *
 * Use `EPC.shared?.submit(stream, event, domain?, date?)` to submit ("log") events to
 * streams.
 *
 * iOS schemas will always include the following fields which are managed by EPC
 * and which will be assigned automatically by the library:
 * - `dt`: client-side timestamp of when event was originally submitted
 * - `app_install_id`: app install ID as in legacy EventLoggingService
 * - `app_session_id`: the ID of the session at the time of the event when it was
 *   originally submitted
 */
@objc public class EventPlatformClient: NSObject, SamplingControllerDelegate {


    // MARK: - Properties

    @objc public static let shared: EventPlatformClient = {
        return EventPlatformClient()
    }()

    let dataStore = MWKDataStore.shared()
    let samplingController: SamplingController
    let storageManager: StorageManager?
    let userSession = UserSession.shared

    var sessionID: String {
        return userSession.sessionID
    }
    
    public var sessionStartDate: Date? {
        return userSession.sessionStartDate
    }
        
    public func resetAll() {
        samplingController.removeAllSamplingCache()
        userSession.resetAll()
    }
    
    public func generateSessionID() {
        userSession.generateSessionID()
    }
    
    public func needsReset() -> Bool {
        return userSession.needsReset()
    }
    
    public func resetBackgroundTimestamp() {
        userSession.resetBackgroundTimestamp()
    }
    
    public func appDidBackground() {
        userSession.appDidBackground()
    }
    
    /**
     * Store events until the library is finished initializing
     *
     * The EPC library makes an HTTP request to a remote stream configuration service for information
     * about how to evaluate incoming event data. Until this initialization is complete, we store any incoming
     * events in this buffer.
     *
     * Only modify (append events to, remove events from) asynchronously via `queue.async`
     */
    private var inputBuffer: [(Data, Stream)] = []

    /**
     * Maximum number of events allowed in the input buffer
     */
    private let inbutBufferLimit = 128

    /**
     * Streams are the event stream identifiers that can be utilized with the EventPlatformClientLibrary. They should
     *  correspond to the `$id` of a schema in
     * [this repository](https://gerrit.wikimedia.org/g/schemas/event/secondary/).
     */
    public enum Stream: String, Codable {
        case editHistoryCompare = "ios.edit_history_compare"
        case remoteNotificationsInteraction = "ios.notification_interaction"
        case talkPagesInteraction = "ios.talk_page_interaction"
        case readingLists = "ios.reading_lists"
        case userHistory = "ios.user_history"
        case search = "ios.search"
        case sessions = "app_session"
        case settings = "ios.setting_action"
        case login = "ios.login_action"
        case navigation = "ios.navigation_events"
        case editAttempt = "eventlogging_EditAttemptStep"
        case watchlist = "ios.watchlists"
        case appDonorExperience = "app_donor_experience"
        case editInteraction = "ios.edit_interaction"
        case imageRecommendation = "android.image_recommendation_event"
    }
    
    /**
     * Schema specifies which schema (and specifically which version of that schema)
     * a given event conforms to. Analytics schemas can be found in the jsonschema directory of
     * [secondary repo](https://gerrit.wikimedia.org/g/schemas/event/secondary/).
     * As an example, if instrumenting client-side error logging, a possible
     * `$schema` would be `/mediawiki/client/error/1.0.0`. For the most part, the
     * `$schema` will start with `/analytics`, since there's where
     * analytics-related schemas are collected.
     */
    public enum Schema: String, Codable {
        case editHistoryCompare = "/analytics/mobile_apps/ios_edit_history_compare/2.2.0"
        case remoteNotificationsInteraction = "/analytics/mobile_apps/ios_notification_interaction/2.2.0"
        case talkPages = "/analytics/mobile_apps/ios_talk_page_interaction/2.1.0"
        case readingLists = "/analytics/mobile_apps/ios_reading_lists/2.2.0"
        case userHistory = "/analytics/mobile_apps/ios_user_history/1.1.0"
        case search = "/analytics/mobile_apps/ios_search/2.2.0"
        case sessions = "/analytics/mobile_apps/app_session/1.1.0"
        case settings = "/analytics/mobile_apps/ios_setting_action/1.1.0"
        case login = "/analytics/mobile_apps/ios_login_action/1.1.0"
        case navigation = "/analytics/mobile_apps/ios_navigation_events/1.1.0"
        case editAttempt = "/analytics/legacy/editattemptstep/2.0.3"
        case watchlist = "/analytics/mobile_apps/ios_watchlists/4.1.0"
        case appInteraction = "/analytics/mobile_apps/app_interaction/1.1.0"
        case imageRecommendation = "/analytics/mobile_apps/android_image_recommendation_event/1.1.0"
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
    private static var eventIntakeURI: URL {
        if WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs {
            URL(string: "https://intake-analytics-beta.wmflabs.org/v1/events")!
        } else {
            URL(string: "https://intake-analytics.wikimedia.org/v1/events")!
        }
    }

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
    private static let streamConfigsURI = URL(string: "https://meta.wikimedia.org/w/api.php?action=streamconfigs&format=json&constraints=destination_event_service=eventgate-analytics-external")!

    /**
     * An individual stream's configuration.
     */
    struct StreamConfiguration: Codable {
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


    private var isAnon: Bool {
        return !dataStore.authenticationManager.authStateIsPermanent
    }
    
    private var isTemp: Bool {
        return dataStore.authenticationManager.authStateIsTemporary
    }

    private var _primaryLanguage: String {
        if let appLanguage = dataStore.languageLinkController.appLanguage {
            return appLanguage.languageCode
        }
        return "en"
    }

    public var primaryLanguage: String {
        return _primaryLanguage
    }

    // MARK: - Methods

    public override init() {
        self.storageManager = StorageManager.shared
        self.samplingController = SamplingController()
        
        super.init()

        self.samplingController.delegate = self

        guard self.storageManager != nil else {
            DDLogError("EPC: Error initializing the storage manager. Event intake and submission will be disabled.")
            return
        }

        self.fetchStreamConfiguration(retries: 10, retryDelay: 30)
    }


    /**
     * Fetch stream configuration from stream configuration service
     * - Parameters:
     *   - retries: number of retries remaining
     *   - retryDelay: seconds between each attempt, increasing by 50% after
     *     every failed attempt
     */
    private func fetchStreamConfiguration(retries: Int, retryDelay: TimeInterval) {
        self.httpGet(url: EventPlatformClient.streamConfigsURI, completion: { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse, let data = data, httpResponse.statusCode == 200 else {
                DDLogWarn("EPC: Server did not respond adequately, will try \(EventPlatformClient.streamConfigsURI.absoluteString) again")

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
     * Processes fetched stream config
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
        guard let storageManager = self.storageManager else {
            DDLogError("Storage manager not initialized; this shouldn't happen!")
            return
        }
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
            while let (data, stream) = inputBufferPopFirst() {
                guard let config = streamConfigurations?[stream] else {
                    continue
                }
                guard samplingController.inSample(stream: stream, config: config) else {
                    continue
                }
                storageManager.push(data: data, stream: stream)
            }
        } catch let error {
            DDLogError("EPC: Problem processing JSON payload from response: \(error)")
        }
    }

    /**
     * Flush the queue of outgoing requests in a first-in-first-out,
     * fire-and-forget fashion
     */
    func postAllScheduled(_ completion: (() -> Void)? = nil) {
        guard let storageManager = self.storageManager else {
            completion?()
            return
        }

        let events = storageManager.popAll()
        if events.count == 0 {
            completion?()
            return
        }

        DDLogDebug("EPC: Processing all scheduled requests")
        let group = DispatchGroup()
        for event in events {
            group.enter()
            httpPost(url: EventPlatformClient.eventIntakeURI, body: event.data) { result in
                switch result {
                case .success:
                    storageManager.markPurgeable(event: event)
                    break
                case .failure(let error):
                    switch error {
                    case .networkingLibraryError:
                        /// Leave unmarked to retry on networking library failure
                        break
                    default:
                        /// Give up on events rejected by the server
                        DDLogError("EPC: The analytics service failed to process an event. A response code of 400 could indicate that the event didn't conform to provided schema. Check the error for more information.: \(error)")
                        storageManager.markPurgeable(event: event)
                        break
                    }
                }
                group.leave()
            }
        }
        group.notify(queue: queue) {
            completion?()
        }
    }
    
    /// Codable struct of additional metadata, embedded in the structure of EventBody and MinimalEventBody.
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
    
    /// MinimalEventBody is used to encode event data into the POST body of a request to the Modern Event Platform. It is the same as EventBody, minus some apps-specfic requirements like appInstallID, appSessionID, isAnon and primaryLanguage. It is used for posting to general cross-platform schemas like EditAttemptStep.
    struct MinimalEventBody<E>: Encodable where E: EventInterface {
        /// EventGate needs to know which version of the schema to validate against
        var meta: Meta

        /**
         * The top-level field `dt` is for recording the time the event
         * was generated. EventGate sets `meta.dt` during ingestion, so for
         * analytics events that field is used as "timestamp of reception" and
         * is used for partitioning the events in the database. See Phab:T240460
         * for more information.
         */
        let dt: Date
        
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
            case dt
            case event
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            do {
                try container.encode(meta, forKey: .meta)
                try container.encode(dt, forKey: .dt)
                try container.encode(E.schema, forKey: .schema)
                try event.encode(to: encoder)
            } catch let error {
                DDLogError("EPC: Error encoding event body: \(error)")
            }
        }
    }
    
    /// EventBody is used to encode event data into the POST body of a request to the Modern Event Platform
    struct EventBody<E>: Encodable where E: EventInterface {
        /// EventGate needs to know which version of the schema to validate against
        var meta: Meta

        let appInstallID: String

        /**
         * Generated events have the session ID attached to them before stream
         * config is available (in case they're generated offline) and before
         * they're cc'd to any other streams (once config is available).
         */
        let appSessionID: String

        /**
         * The top-level field `dt` is for recording the time the event
         * was generated. EventGate sets `meta.dt` during ingestion, so for
         * analytics events that field is used as "timestamp of reception" and
         * is used for partitioning the events in the database. See Phab:T240460
         * for more information.
         */
        let dt: Date
        
        /**
         * Event represents the client-provided event data.
         * The event is encoded at the top level of the resulting structure.
         * If any of the `CodingKeys` conflict with keys defined by `EventBody`,
         * the values from `event` will be used.
         */
        let event: E

        /**
         * Required field for all iOS schemas
         * False for logged in users
        **/

        let isAnon: Bool
        
        /**
         * Not a required field, but we want to send it for all iOS schemas
         * True if there are no stored credentials but we have a central auth username cookie.
        **/

        let isTemp: Bool

        /**
         * Required field for all iOS schemas
         * Represents the app's primary language
        **/
        let primaryLanguage: String

        enum CodingKeys: String, CodingKey {
            case schema = "$schema"
            case meta
            case appInstallID = "app_install_id"
            case appSessionID = "app_session_id"
            case dt
            case event
            case isAnon = "is_anon"
            case isTemp = "is_temp"
            case primaryLanguage = "primary_language"
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            do {
                try container.encode(meta, forKey: .meta)
                try container.encode(appInstallID, forKey: .appInstallID)
                try container.encode(appSessionID, forKey: .appSessionID)
                try container.encode(dt, forKey: .dt)
                try container.encode(E.schema, forKey: .schema)
                try container.encode(isAnon, forKey: .isAnon)
                try container.encode(isTemp, forKey: .isTemp)
                try container.encode(primaryLanguage, forKey: .primaryLanguage)
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
     * let event = TestEvent(test_string: "Explore Feed refreshed", test_map: sourceInfo)
     *
     * EventPlatformClient.shared?.submit(
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
    public func submit<E: EventInterface>(stream: Stream, event: E, domain: String? = nil, needsMinimal: Bool = false, completion: (() -> Void)? = nil) {
        let date = Date() // Record the date synchronously so there's no delay
        encodeQueue.async {
            self._submit(stream: stream, event: event, date: date, domain: domain, needsMinimal: needsMinimal)
            completion?()
        }
    }

    /// Private, synchronous version of `submit`.
    private func _submit<E: EventInterface>(stream: Stream, event: E, date: Date, domain: String? = nil, needsMinimal: Bool = false) {
        guard let storageManager = self.storageManager else {
            return
        }

        let userDefaults = UserDefaults.standard

        guard let appInstallID = userDefaults.wmf_appInstallId else {
            DDLogError("EPC: App install ID is unset. This shouldn't happen.")
            return
        }
        
        let meta = Meta(stream: stream, id: UUID(), domain: domain)
        let eventPayload: Encodable = needsMinimal ? MinimalEventBody<E>(meta: meta, dt: date, event: event) : EventBody<E>(meta: meta, appInstallID: appInstallID, appSessionID: sessionID, dt: date, event: event, isAnon: isAnon, isTemp: isTemp, primaryLanguage: primaryLanguage)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            #if DEBUG
            encoder.outputFormatting = .prettyPrinted
            #endif
            
            let data = try encoder.encode(eventPayload)
            
            #if DEBUG
            let jsonString = String(data: data, encoding: .utf8)!
            DDLogDebug("EPC: Scheduling event to be sent to \(EventPlatformClient.eventIntakeURI) with POST body:\n\(jsonString)")
            #endif
            
            guard let streamConfigs = streamConfigurations else {
                appendEventToInputBuffer(data: data, stream: stream)
                return
            }
            guard let config = streamConfigs[stream] else {
                DDLogDebug("EPC: Event submitted to '\(stream)' but only the following streams are configured: \(streamConfigs.keys.map(\.rawValue).joined(separator: ", "))")
                return
            }
            guard samplingController.inSample(stream: stream, config: config) else {
                DDLogDebug("EPC: Stream '\(stream.rawValue)' is not in sample")
                return
            }
            storageManager.push(data: data, stream: stream)
        } catch let error {
            DDLogError("EPC: \(error.localizedDescription)")
        }

    }
}

// MARK: Thread-safe accessors for collection properties
private extension EventPlatformClient {

    /**
     * Thread-safe synchronous retrieval of buffered events
     */
    func getInputBuffer() -> [(Data, Stream)] {
        queue.sync {
            return self.inputBuffer
        }
    }

    /**
     * Thread-safe synchronous buffering of an event
     * - Parameter event: event to be buffered
     */
    func appendEventToInputBuffer(data: Data, stream: Stream) {
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
            self.inputBuffer.append((data, stream))
        }
    }


    /**
     * Thread-safe synchronous removal of first buffered event
     * - Returns: a previously buffered event
     */
    func inputBufferPopFirst() -> (Data, Stream)? {
        queue.sync {
            if self.inputBuffer.isEmpty {
                return nil
            }
            return self.inputBuffer.remove(at: 0)
        }
    }
}

// MARK: NetworkIntegration

private extension EventPlatformClient {
    /// PostEventError describes the possible failure cases when POSTing an event
    enum PostEventError: Error {
        case networkingLibraryError(_ error: Error)
        case missingResponse
        case unexepectedResponse(_ httpCode: Int)
    }
    
    /**
     * HTTP POST
     * - Parameter body: Body of the POST request
     * - Parameter completion: callback invoked upon receiving the server response
     */
    private func httpPost(url: URL, body: Data? = nil, completion: @escaping ((Result<Void, PostEventError>) -> Void)) {
        DDLogDebug("EPC: Attempting to POST events")
        let request = dataStore.session.request(with: url, method: .post, bodyData: body, bodyEncoding: .json)
        let task = dataStore.session.dataTask(with: request, completionHandler: { (_, response, error) in
            let fail: (PostEventError) -> Void = { error in
                DDLogError("EPC: An error occurred sending the request: \(error)")
                completion(.failure(error))
            }
            if let error = error {
                fail(PostEventError.networkingLibraryError(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                fail(PostEventError.missingResponse)
                return
            }
            guard httpResponse.statusCode == 201 else {
                fail(PostEventError.unexepectedResponse(httpResponse.statusCode))
                return
            }
            completion(.success(()))
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
        let task = dataStore.session.dataTask(with: request, completionHandler: completion)
        task?.resume()
    }
}

// MARK: EventInterface

/**
 * Protocol for event data.
 * Currently only requires conformance to Codable.
 */
public protocol EventInterface: Codable {
    /**
     * Defines which schema this event conforms to.
     * Check the documentation for `EPC.Schema` for more information.
     */
    static var schema: EventPlatformClient.Schema { get }
}
