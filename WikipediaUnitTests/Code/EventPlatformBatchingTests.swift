import XCTest
@testable import WMF

final class EventPlatformBatchingTests: XCTestCase {

    private typealias Stream = EventPlatformClient.Stream
    private typealias StreamConfiguration = EventPlatformClient.StreamConfiguration

    private func makeEvent(stream: Stream, json: String = "{\"test\":true}", index: Int = 0) -> PersistedEvent {
        return PersistedEvent(data: Data(json.utf8), stream: stream, managedObjectURI: URL(string: "x-coredata://test/WMFEPEventRecord/p\(index)")!)
    }

    private func makeConfigs(loggingStreams: [Stream]) -> [Stream: StreamConfiguration] {
        var configs: [Stream: StreamConfiguration] = [
            .search: StreamConfiguration(destination_event_service: "eventgate-analytics-external", sampling: nil),
            .sessions: StreamConfiguration(destination_event_service: "eventgate-analytics-external", sampling: nil)
        ]
        for stream in loggingStreams {
            configs[stream] = StreamConfiguration(destination_event_service: "eventgate-logging-external", sampling: nil)
        }
        return configs
    }

    // MARK: - makeBatches

    func testMakeBatchesWithNoEventsReturnsNoBatches() {
        let batches = EventPlatformClient.makeBatches(events: [], configs: makeConfigs(loggingStreams: []), chunkSize: 50)
        XCTAssertTrue(batches.isEmpty)
    }

    /// Regression test for the widget routing bug: with stream configs unavailable,
    /// every event must fall back to the analytics intake in a single batch.
    func testMakeBatchesWithNilConfigsRoutesEverythingToAnalytics() {
        let events = [makeEvent(stream: .search, index: 0), makeEvent(stream: .clientError, index: 1)]
        let batches = EventPlatformClient.makeBatches(events: events, configs: nil, chunkSize: 50)
        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches.first?.destination, .analytics)
        XCTAssertEqual(batches.first?.events.count, 2)
    }

    func testMakeBatchesGroupsByDestination() {
        let configs = makeConfigs(loggingStreams: [.clientError])
        let events = [
            makeEvent(stream: .search, index: 0),
            makeEvent(stream: .clientError, index: 1),
            makeEvent(stream: .sessions, index: 2),
            makeEvent(stream: .clientError, index: 3)
        ]
        let batches = EventPlatformClient.makeBatches(events: events, configs: configs, chunkSize: 50)
        XCTAssertEqual(batches.count, 2)

        let analytics = batches.first { $0.destination == .analytics }
        let logging = batches.first { $0.destination == .logging }
        XCTAssertEqual(analytics?.events.count, 2)
        XCTAssertEqual(logging?.events.count, 2)

        // Relative order within a destination is preserved
        XCTAssertEqual(analytics?.events.map(\.managedObjectURI.lastPathComponent), ["p0", "p2"])
        XCTAssertEqual(logging?.events.map(\.managedObjectURI.lastPathComponent), ["p1", "p3"])
    }

    func testMakeBatchesTreatsUnconfiguredStreamsAsAnalytics() {
        let configs = makeConfigs(loggingStreams: [])
        let batches = EventPlatformClient.makeBatches(events: [makeEvent(stream: .watchlist)], configs: configs, chunkSize: 50)
        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches.first?.destination, .analytics)
    }

    func testMakeBatchesChunkBoundaries() {
        let configs = makeConfigs(loggingStreams: [])
        for (eventCount, expectedChunks) in [(1, 1), (50, 1), (51, 2), (137, 3)] {
            let events = (0..<eventCount).map { makeEvent(stream: .search, index: $0) }
            let batches = EventPlatformClient.makeBatches(events: events, configs: configs, chunkSize: 50)
            XCTAssertEqual(batches.count, expectedChunks, "\(eventCount) events should produce \(expectedChunks) batches")
            XCTAssertEqual(batches.reduce(0) { $0 + $1.events.count }, eventCount, "no events may be lost to chunking")
            for batch in batches {
                XCTAssertLessThanOrEqual(batch.events.count, 50)
            }
        }
    }

    func testMakeBatchesClampsNonPositiveChunkSize() {
        let events = (0..<3).map { makeEvent(stream: .search, index: $0) }
        let batches = EventPlatformClient.makeBatches(events: events, configs: nil, chunkSize: 0)
        XCTAssertEqual(batches.count, 3)
    }

    // MARK: - encodeBatchBody

    func testEncodeBatchBodyProducesValidJSONArray() throws {
        let compact = Data("{\"a\":1}".utf8)
        let prettyPrinted = Data("{\n  \"b\" : 2\n}".utf8)
        let body = EventPlatformClient.encodeBatchBody([compact, prettyPrinted, compact])

        let parsed = try JSONSerialization.jsonObject(with: body)
        let array = try XCTUnwrap(parsed as? [[String: Int]])
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0]["a"], 1)
        XCTAssertEqual(array[1]["b"], 2)
        XCTAssertEqual(array[2]["a"], 1)
    }

    func testEncodeBatchBodySingleEvent() throws {
        let body = EventPlatformClient.encodeBatchBody([Data("{\"a\":1}".utf8)])
        let array = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [[String: Int]])
        XCTAssertEqual(array, [["a": 1]])
    }

    // MARK: - disposition(for:)

    private enum FakeError: Error {
        case network
    }

    func testDispositionTruthTable() {
        XCTAssertEqual(EventPlatformClient.disposition(for: .success(())), .purge)
        XCTAssertEqual(EventPlatformClient.disposition(for: .failure(.networkingLibraryError(FakeError.network))), .retain)
        XCTAssertEqual(EventPlatformClient.disposition(for: .failure(.unexpectedResponse(207))), .purge)
        XCTAssertEqual(EventPlatformClient.disposition(for: .failure(.unexpectedResponse(400))), .retryIndividually)
        XCTAssertEqual(EventPlatformClient.disposition(for: .failure(.missingResponse)), .retryIndividually)
        XCTAssertEqual(EventPlatformClient.disposition(for: .failure(.retryableServerError(statusCode: 429, retryAfter: 60))), .retainAndBackoff(60))
        XCTAssertEqual(EventPlatformClient.disposition(for: .failure(.retryableServerError(statusCode: 503, retryAfter: nil))), .retainAndBackoff(EventPlatformClient.defaultBackoffInterval))
    }

    func testDispositionClampsExcessiveRetryAfter() {
        let disposition = EventPlatformClient.disposition(for: .failure(.retryableServerError(statusCode: 429, retryAfter: 86400)))
        XCTAssertEqual(disposition, .retainAndBackoff(EventPlatformClient.maximumBackoffInterval))
    }

    // MARK: - Retry-After parsing

    func testRetryAfterParsesDeltaSeconds() {
        XCTAssertEqual(EventPlatformClient.retryAfterInterval(fromHeaderValue: "120"), 120)
        XCTAssertEqual(EventPlatformClient.retryAfterInterval(fromHeaderValue: " 5 "), 5)
        XCTAssertEqual(EventPlatformClient.retryAfterInterval(fromHeaderValue: "0"), 0)
    }

    func testRetryAfterParsesHTTPDate() throws {
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-08-27T12:00:00Z"))
        let interval = EventPlatformClient.retryAfterInterval(fromHeaderValue: "Wed, 27 Aug 2026 12:01:00 GMT", now: now)
        XCTAssertEqual(interval, 60)
    }

    func testRetryAfterHTTPDateInThePastClampsToZero() throws {
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-08-27T12:00:00Z"))
        let interval = EventPlatformClient.retryAfterInterval(fromHeaderValue: "Wed, 27 Aug 2026 11:00:00 GMT", now: now)
        XCTAssertEqual(interval, 0)
    }

    func testRetryAfterRejectsGarbage() {
        XCTAssertNil(EventPlatformClient.retryAfterInterval(fromHeaderValue: nil))
        XCTAssertNil(EventPlatformClient.retryAfterInterval(fromHeaderValue: ""))
        XCTAssertNil(EventPlatformClient.retryAfterInterval(fromHeaderValue: "soon"))
        XCTAssertNil(EventPlatformClient.retryAfterInterval(fromHeaderValue: "-30"))
    }
}
