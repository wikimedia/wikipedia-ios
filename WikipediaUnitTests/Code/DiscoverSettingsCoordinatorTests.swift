import XCTest
import os
@testable import Wikipedia
import WMFComponents
import WMFData

@MainActor
final class DiscoverSettingsCoordinatorTests: XCTestCase {

    private var store: InMemoryKeyValueStore!
    private var dataController: WMFDiscoverReadingListDataController!

    override func setUp() async throws {
        store = InMemoryKeyValueStore()
        dataController = WMFDiscoverReadingListDataController(
            userDefaultsStore: store,
            relatedPagesDataController: WMFRelatedPagesDataController(basicService: nil)
        )
    }

    private func saveSettings(source: WMFDiscoverSource, articleCount: Int) async throws -> WMFDiscoverSettings {
        let settings = WMFDiscoverSettings(isEnabled: true, articleCount: articleCount, cadence: .weekly, source: source)
        try await dataController.saveSettings(settings)
        return settings
    }

    private func waitUntil(_ condition: @MainActor () -> Bool) async {
        let deadline = Date().addingTimeInterval(5)
        while !condition() && Date() < deadline {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    func testUndoRefreshesTheSettingsScreenOnTop() async throws {
        let settings = try await saveSettings(source: .saved, articleCount: 5)
        let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController)
        let navigationController = UINavigationController(rootViewController: WMFDiscoverSettingsHostingController(viewModel: viewModel))
        _ = try await saveSettings(source: .history, articleCount: 5)

        DiscoverSettingsCoordinator.refreshScreen(onTopOf: navigationController)
        await waitUntil { viewModel.settings.source == .history }

        XCTAssertEqual(viewModel.settings.source, .history)
    }

    func testUndoReloadsTheDiscoverListOnTop() async throws {
        _ = try await saveSettings(source: .saved, articleCount: 5)
        let viewModel = WMFDiscoverReadingListViewModel(username: nil, dataController: dataController)
        let navigationController = UINavigationController(rootViewController: WMFDiscoverReadingListHostingController(viewModel: viewModel))
        viewModel.load()
        await waitUntil { viewModel.state != .loading }
        _ = try await saveSettings(source: .saved, articleCount: 7)

        DiscoverSettingsCoordinator.refreshScreen(onTopOf: navigationController)
        await waitUntil { viewModel.settings.articleCount == 7 }

        XCTAssertEqual(viewModel.settings.articleCount, 7)
    }

    func testAnotherScreenOnTopIsLeftAlone() throws {
        let navigationController = UINavigationController(rootViewController: UIViewController())

        DiscoverSettingsCoordinator.refreshScreen(onTopOf: navigationController)

        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }
}

/// A key-value store that lives only for one test. The lock keeps it `Sendable`, like the real stores.
private final class InMemoryKeyValueStore: WMFKeyValueStore {

    private let values = OSAllocatedUnfairLock<[String: Data]>(initialState: [:])

    func load<T: Codable>(key: String...) throws -> T? {
        guard let data = values.withLock({ $0[key.joined(separator: "/")] }) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func save<T: Codable>(key: String..., value: T) throws {
        let data = try JSONEncoder().encode(value)
        values.withLock { $0[key.joined(separator: "/")] = data }
    }

    func remove(key: String...) throws {
        values.withLock { _ = $0.removeValue(forKey: key.joined(separator: "/")) }
    }

    func keys(inDirectory directory: String) throws -> [String] {
        values.withLock { $0.keys }.filter { $0.hasPrefix(directory + "/") }.map { String($0.dropFirst(directory.count + 1)) }
    }
}
