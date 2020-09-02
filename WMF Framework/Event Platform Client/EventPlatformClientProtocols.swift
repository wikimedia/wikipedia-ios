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
 * Network manager provides EPC with the ability to interact with the network,
 * asynchronously.
 *
 * It can perform fire-and-forget HTTP requests via `HTTP POST`. Additionally,
 * the network manager can also be used to download data. Refer to
 * [mw:Wikimedia Product/Analytics Infrastructure/Event Platform Client](https://www.mediawiki.org/wiki/Wikimedia_Product/Analytics_Infrastructure/Event_Platform_Client)
 * for additional information.
 */
public protocol EPCNetworkManaging {
    /**
     * For scheduling events to be sent fire-and-forget via `HTTP POST`
     *
     * This needs to be called from the library each time new events are logged.
     * **Note**: posting may not happen right away when calling this.
     */
    func schedulePost(url: URL, body: NSDictionary)
    /**
     * For downloading data
     *
     * It is the implementation's responsibility to call `completion` handler with
     * non-nil data only if the HTTP response is 200 or 304. It is up to the
     * implementation to print an informational error in case of any problems
     * downloading.
     */
    func httpDownload(url: URL, completion: @escaping (Data?) -> Void)
    
    /**
     * This method kicks off the posting of events queued from the httpPost method
     *
     * It is meant to be periodically called in the app lifecycle, i.e. through a
     * PeriodicWorker.
     */
    func httpTryPost()
}
