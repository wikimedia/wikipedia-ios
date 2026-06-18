import Foundation
@_spi(Testing) import WMFData

public final class WMFDataTestFixture {

    private var restoreEnvironment: (() -> Void)?
    private var temporaryDirectories: [URL] = []

    public init() {}

    deinit {
        resetSynchronousWMFDataTestState()
        restoreEnvironmentForTesting()
        resetSynchronousWMFDataTestState()
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
