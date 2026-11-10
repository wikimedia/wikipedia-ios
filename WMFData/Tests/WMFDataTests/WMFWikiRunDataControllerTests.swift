import Foundation
import Testing
@testable import WMFData
@testable import WMFDataMocks

@Suite
final class WMFWikiRunDataControllerTests {

    private let snapshot = WMFWikiRunDataController.WMFWikiRunSnapshot(
        version: 1,
        values: ["theme": "dark", "score": "10"]
    )

    @Test
    func loadReturnsNilBeforeAnythingIsSaved() async throws {
        let dataController = WMFWikiRunDataController(sharedCacheStore: WMFMockKeyValueStore())

        let loaded = try await dataController.loadSnapshot()

        #expect(loaded == nil)
    }

    @Test
    func snapshotRoundTripsThroughTheStore() async throws {
        let dataController = WMFWikiRunDataController(sharedCacheStore: WMFMockKeyValueStore())

        try await dataController.saveSnapshot(snapshot)
        let loaded = try await dataController.loadSnapshot()

        #expect(loaded == snapshot)
    }

    @Test
    func savingReplacesThePreviousSnapshot() async throws {
        let dataController = WMFWikiRunDataController(sharedCacheStore: WMFMockKeyValueStore())
        let updated = WMFWikiRunDataController.WMFWikiRunSnapshot(version: 1, values: ["score": "20"])

        try await dataController.saveSnapshot(snapshot)
        try await dataController.saveSnapshot(updated)
        let loaded = try await dataController.loadSnapshot()

        #expect(loaded == updated)
    }

    @Test
    func clearRemovesTheSnapshot() async throws {
        let dataController = WMFWikiRunDataController(sharedCacheStore: WMFMockKeyValueStore())

        try await dataController.saveSnapshot(snapshot)
        try await dataController.clearSnapshot()
        let loaded = try await dataController.loadSnapshot()

        #expect(loaded == nil)
    }
}
