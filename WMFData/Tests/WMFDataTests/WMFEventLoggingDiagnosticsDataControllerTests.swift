import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFEventLoggingDiagnosticsDataControllerTests {

    private let fixture = WMFDataTestFixture()

    @Test
    func recordFlushAccumulates() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFEventLoggingDiagnosticsDataController.shared
            controller.reset()

            controller.recordFlush(posts: 2, events: 40)
            controller.recordFlush(posts: 1, events: 9)

            let diagnostics = controller.snapshot()
            #expect(diagnostics.flushCount == 2)
            #expect(diagnostics.postCount == 3)
            #expect(diagnostics.eventsSentCount == 49)
            #expect(diagnostics.eventsInLastFlush == 9)
            #expect(diagnostics.lastFlushDate != nil)
        }
    }

    @Test
    func recordDropCountsByReason() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFEventLoggingDiagnosticsDataController.shared
            controller.reset()

            controller.recordDrop(reason: .notInSample)
            controller.recordDrop(reason: .notInSample)
            controller.recordDrop(reason: .errorThrottled, count: 3)

            let diagnostics = controller.snapshot()
            #expect(diagnostics.dropCounts[WMFEventDropReason.notInSample.rawValue] == 2)
            #expect(diagnostics.dropCounts[WMFEventDropReason.errorThrottled.rawValue] == 3)
            #expect(diagnostics.dropCounts[WMFEventDropReason.serverRejected.rawValue] == nil)
        }
    }

    @Test
    func resetClearsEverything() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFEventLoggingDiagnosticsDataController.shared
            controller.recordFlush(posts: 1, events: 5)
            controller.recordDrop(reason: .serverRejected)

            controller.reset()

            let diagnostics = controller.snapshot()
            #expect(diagnostics.flushCount == 0)
            #expect(diagnostics.postCount == 0)
            #expect(diagnostics.eventsSentCount == 0)
            #expect(diagnostics.dropCounts.isEmpty)
            #expect(diagnostics.lastFlushDate == nil)
        }
    }

    @Test
    func concurrentIncrementsAreNotLost() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFEventLoggingDiagnosticsDataController.shared
            controller.reset()

            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<50 {
                    group.addTask {
                        controller.recordDrop(reason: .notInSample)
                    }
                }
            }

            let diagnostics = controller.snapshot()
            #expect(diagnostics.dropCounts[WMFEventDropReason.notInSample.rawValue] == 50)
        }
    }

    @Test
    func aMissingStoreNeverThrows() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureMissingStoreEnvironment) {
            let controller = WMFEventLoggingDiagnosticsDataController.shared
            controller.recordFlush(posts: 1, events: 1)
            controller.recordDrop(reason: .serverRejected)
            controller.reset()

            let diagnostics = controller.snapshot()
            #expect(diagnostics.flushCount == 0)
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
    }

    private func configureMissingStoreEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = nil
    }
}
