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
 * Storage manager provides EPC with the ability to persist data and retrieve persisted data, asynchronously.
 *
 * The storage manager needs to be able to handle persistent storage of any type of value. When storing a
 * session identifier, for example, it needs to store a `String`. When storing queued-up, to-be-sent events
 * when entering background, it needs to store `[Event]`. When storing raw logged events, they can look
 * be dictionaries-within-dictionaries. Fortunately, the types within those dictionaries are always
 * encodable/decodable (e.g. `String`, `Int`, `Bool`, `Double` and arrays of those types).
 *
 * Additionally, it makes the app's install ID available to EPC as `installID` for including in events and
 * determining sampling for streams configured to use the "device" identifier (as opposed to those configured
 * to use the "session" identifier).
 */
public protocol EPCStorageManaging {
    //used by EPC
    func setPersisted(_ key: String, _ value: NSCoding)
    func deletePersisted(_ key: String)
    func getPersisted(_ key: String) -> NSCoding?
    var installID: String? { get }
    var sharingUsageData: Bool { get }
    
    //used by EPCNetworkManager
    func createAndSavePost(with url: URL, body: NSDictionary)
    func updatePosts(completedIDs: Set<NSManagedObjectID>, failedIDs: Set<NSManagedObjectID>)
    func deleteStalePosts()
    func fetchPostsForPosting() -> [EPCPost]
    func urlAndBodyOfPost(_ post: EPCPost) -> (url: URL, body: NSDictionary)?
}

/**
 * Network manager provides EPC with the ability to interact with the network, asynchronously.
 *
 * It can perform fire-and-forget HTTP requests via `HTTP POST`. Additionally, the network manager can
 * also be used to download data. Refer to
 * [mw:Wikimedia Product/Analytics Infrastructure/Event Platform Client](https://www.mediawiki.org/wiki/Wikimedia_Product/Analytics_Infrastructure/Event_Platform_Client)
 * for additional information.
 *
 * ## Requirements
 * The network manager should:
 * - be smart enough to queue up outgoing HTTP requests when there is no network connectivity; that is, if
 *   the stream configuration has been downloaded before the connection was lost, EPC may still submit
 *   events to the network manager (EPC has no awareness of network status) and it is up to the manager
 *   to hold on to those events until they can be properly sent
 * - be able to persist queued up requests (when they're events sent by EPC) when the app will be closed,
 *   so that we don't lose analytics events generated and queued up between when the network goes offline
 *   and the app is closed
 * - be smart about queuing up outgoing HTTP requests and sending them in bursts at some prespecified
 *   interval, to not wake up the radio for every individual request whenever possible
 * - technically, EventGate can accept batches of bundled events (up to a certain POST body byte length), so
 *   it is possible to make fewer overall requests by sending them in batches at the expense of a heavier
 *   payload in each request
 * - when being used to download (e.g. fetch the stream configuration from MediaWiki API), the network
 *   manager should retry if there is an error, except if the response has a 404 status code (e.g. EPC is
 *   misconfigured, the stream config URI needs to be fixed/updated, and, optionally/preferably, the error
 *   should be logged)
 *
 * **Note**: if the device is offline from app's launch to app's close, EPC will keep any generated events in
 * its internal queue. Events are not submitted to the network manager if there is no stream configuration
 * (which needs to be downloaded separately).
 */
public protocol EPCNetworkManaging {
    /**
     * For fire-and-forget via `HTTP POST` (e.g. for sending events to EventGate endpoint)
     * This needs to be called from the library each time new events are logged
     * Note posting may not happen right away when calling this
     */
    func httpPost(url: URL, body: NSDictionary)
    /**
     * For downloading data
     *
     * It is the implementation's responsibility to call `completion` handler with non-nil data only if the
     * HTTP response is 200 or 304. It is up to the implementation to print an informational error in case
     * of any problems downloading.
     */
    func httpDownload(url: URL, completion: @escaping (Data?) -> Void)
    
    /**
    * This method kicks off the posting of events queued from the httpPost method.
    * It is meant to be periodically called in the app lifecycle, i.e. through a PeriodicWorker.
    */
    func httpTryPost(_ completion: (() -> Void)?)
}
