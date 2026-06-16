import Foundation
@_spi(Testing) import WMFData

public final class WMFDataTestFixture {

    private var restoreEnvironment: (() -> Void)?
    private var temporaryDirectories: [URL] = []
    private var isGlobalFixtureLockHeld = false

    public init() {}

    deinit {
        resetSynchronousWMFDataTestState()
        restoreEnvironmentForTesting()
        resetSynchronousWMFDataTestState()
        unlockGlobalFixtureState()
    }

    public func setUp() async {
        lockGlobalFixtureState()
        restoreEnvironmentForTesting()
        snapshotEnvironment()
        await resetWMFDataTestState()
    }

    public func tearDown() async {
        await resetWMFDataTestState()
        restoreEnvironmentForTesting()
        await resetWMFDataTestState()
        unlockGlobalFixtureState()
    }

    public func resetWMFDataTestState() async {
        resetSynchronousWMFDataTestState()
        await WMFOnThisDayDataController.shared.reset()
    }

    private func resetSynchronousWMFDataTestState() {
        WMFDonateDataController.shared.reset()
        WMFFundraisingCampaignDataController.shared.reset()
        WMFArticleTabsDataController.shared.reset()
        WMFDeveloperSettingsDataController.shared.reset()
        WMFImageDataController.shared.reset()
        WMFTempAccountDataController.shared.reset()
    }

    public func makeTemporaryCoreDataStore() async throws -> WMFCoreDataStore {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        temporaryDirectories.append(temporaryDirectory)
        return try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
    }

    private func snapshotEnvironment() {
        let snapshot = WMFDataEnvironment.current.snapshotForTesting()

        restoreEnvironment = {
            WMFDataEnvironment.current.restoreForTesting(snapshot)
        }
    }

    private func restoreEnvironmentForTesting() {
        restoreEnvironment?()
        restoreEnvironment = nil
        removeTemporaryDirectories()
    }

    private func removeTemporaryDirectories() {
        for temporaryDirectory in temporaryDirectories {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        temporaryDirectories = []
    }

    private func lockGlobalFixtureState() {
        guard isGlobalFixtureLockHeld == false else {
            return
        }

        WMFDataTestFixtureLock.shared.lock()
        isGlobalFixtureLockHeld = true
    }

    private func unlockGlobalFixtureState() {
        guard isGlobalFixtureLockHeld else {
            return
        }

        isGlobalFixtureLockHeld = false
        WMFDataTestFixtureLock.shared.unlock()
    }
}

// Swift Testing serializes tests within a suite, but different suites can still
// run in parallel. Fixture setup and teardown mutate process-wide WMFData
// singletons, so fixture users need one cross-suite lease for the whole test.
private final class WMFDataTestFixtureLock: @unchecked Sendable {
    static let shared = WMFDataTestFixtureLock()

    private let mutex = NSLock()

    func lock() {
        mutex.lock()
    }

    func unlock() {
        mutex.unlock()
    }
}
