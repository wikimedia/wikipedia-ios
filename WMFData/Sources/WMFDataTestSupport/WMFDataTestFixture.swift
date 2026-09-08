import Foundation
@_spi(Testing) import WMFData

public final class WMFDataTestFixture {

    private var restoreEnvironment: (() -> Void)?
    private var temporaryDirectories: [URL] = []

    public init() {}

    deinit {
        // The safety net for a test that died before its tearDown. It must only run for a
        // fixture that configured the environment: a reset here runs without the global lease,
        // and a fixture used only for temporary stores would reset the shared singletons in
        // the middle of another suite's leased test.
        if restoreEnvironment != nil {
            resetSynchronousWMFDataTestState()
            restoreEnvironmentForTesting()
            resetSynchronousWMFDataTestState()
        } else {
            removeTemporaryDirectories()
        }
    }

    public func setUp() async {
        restoreEnvironmentForTesting()
        snapshotEnvironment()
        await resetWMFDataTestState()
    }

    public func tearDown() async {
        await resetWMFDataTestState()
        restoreEnvironmentForTesting()
        await resetWMFDataTestState()
    }

    public func resetWMFDataTestState() async {
        resetSynchronousWMFDataTestState()
        await WMFOnThisDayDataController.shared.reset()
        // WMFImageDataController is an actor, so its reset is awaited here rather
        // than in resetSynchronousWMFDataTestState (same as WMFOnThisDayDataController).
        await WMFImageDataController.shared.reset()
    }

    public func withGlobalStateLease<T>(_ operation: () async throws -> T) async rethrows -> T {
        let lease = await WMFDataTestFixtureGlobalStateLease.shared.acquire()

        do {
            let result = try await operation()
            await lease.release()
            return result
        } catch {
            await lease.release()
            throw error
        }
    }

    public func withConfiguredEnvironment<T>(
        configure: () async throws -> Void,
        operation: () async throws -> T
    ) async rethrows -> T {
        try await withGlobalStateLease {
            await setUp()

            do {
                try await configure()
                await resetWMFDataTestState()
                let result = try await operation()
                await tearDown()
                return result
            } catch {
                await tearDown()
                throw error
            }
        }
    }

    /// One lock for every fixture in the process. The singletons' reset functions reassign
    /// plain stored properties, and two concurrent resets release the same old value twice -
    /// a crash in swift_release. XCTest suites call the fixture outside the global lease, so
    /// the lease alone does not serialize the resets.
    private static let resetLock = NSLock()

    private func resetSynchronousWMFDataTestState() {
        Self.resetLock.withLock {
            WMFDonateDataController.shared.reset()
            WMFFundraisingCampaignDataController.shared.reset()
            WMFArticleTabsDataController.shared.reset()
            WMFDeveloperSettingsDataController.shared.reset()
            WMFTempAccountDataController.shared.reset()
        }
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
}

private actor WMFDataTestFixtureGlobalStateLease {
    static let shared = WMFDataTestFixtureGlobalStateLease()

    private var isHeld = false
    private var waiters: [CheckedContinuation<Lease, Never>] = []

    func acquire() async -> Lease {
        if isHeld {
            return await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }

        isHeld = true
        return Lease(owner: self)
    }

    private func release() {
        guard waiters.isEmpty else {
            waiters.removeFirst().resume(returning: Lease(owner: self))
            return
        }

        isHeld = false
    }

    struct Lease: Sendable {
        private let owner: WMFDataTestFixtureGlobalStateLease

        fileprivate init(owner: WMFDataTestFixtureGlobalStateLease) {
            self.owner = owner
        }

        func release() async {
            await owner.release()
        }
    }
}
