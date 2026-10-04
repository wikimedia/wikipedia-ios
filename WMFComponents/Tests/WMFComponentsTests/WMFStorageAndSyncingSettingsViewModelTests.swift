import XCTest
@testable import WMFComponents

@MainActor
final class WMFStorageAndSyncingSettingsViewModelTests: XCTestCase {

    func testShowSavedReadingListToggleUpdatesStateAndNotifies() {
        var receivedValue: Bool?
        let viewModel = makeViewModel(onToggleShowSavedList: {
            receivedValue = $0
        })
        viewModel.updateShowSavedList(true)
        let item = viewModel.sections[1].items[0]

        guard case let .toggle(binding) = item.accessory else {
            return XCTFail("Show Saved reading list row should be a toggle")
        }

        XCTAssertTrue(viewModel.showSavedReadingList)

        binding.wrappedValue = false

        XCTAssertFalse(viewModel.showSavedReadingList)
        XCTAssertEqual(receivedValue, false)
    }

    func testUpdateSyncedReadingListsHasNoAccessoryAndTriggersSync() async {
        var didSync = false
        let viewModel = makeViewModel(onSyncWithServer: {
            didSync = true
        })
        await viewModel.loadAndBuild()
        let item = viewModel.sections[2].items[0]

        guard case .none = item.accessory else {
            return XCTFail("Update synced reading lists should not display an accessory")
        }

        item.action?()

        XCTAssertTrue(didSync)
    }

    // MARK: - Helpers

    private let localizedStrings = WMFStorageAndSyncingSettingsViewModel.LocalizedStrings(
        title: "Storage and syncing",
        syncSavedArticlesTitle: "Sync saved articles and lists",
        syncSavedArticlesFooter: "Sync footer",
        showSavedReadingListTitle: "Show Saved reading list",
        showSavedReadingListFooter: "Saved reading list footer",
        syncWithServerTitle: "Update synced reading lists",
        syncWithServerFooter: "Update footer"
    )

    private func makeViewModel(onToggleShowSavedList: ((Bool) -> Void)? = nil, onSyncWithServer: (() -> Void)? = nil) -> WMFStorageAndSyncingSettingsViewModel {
        WMFStorageAndSyncingSettingsViewModel(
            localizedStrings: localizedStrings,
            onToggleShowSavedList: onToggleShowSavedList,
            onSyncWithServer: onSyncWithServer
        )
    }
}
