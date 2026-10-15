import XCTest
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

/// The settings view models keep their toggle bindings inside their sections. A binding that
/// captures the view model strongly keeps it alive forever.
@MainActor
final class WMFSettingsViewModelsReleaseTests: XCTestCase {

    private func assertReleased<ViewModel: AnyObject>(_ makeViewModel: () async -> ViewModel, file: StaticString = #filePath, line: UInt = #line) async {
        var viewModel: ViewModel? = await makeViewModel()
        weak var weakViewModel = viewModel

        viewModel = nil

        // The init of each view model queues a Task that holds it until the Task runs.
        let released = expectation(description: "The view model is released")
        Task {
            while weakViewModel != nil {
                await Task.yield()
            }
            released.fulfill()
        }
        await fulfillment(of: [released], timeout: 1)
        XCTAssertNil(weakViewModel, "The toggle bindings in the sections must not retain the view model", file: file, line: line)
    }

    func testAccountSettingsViewModelIsReleased() async {
        await assertReleased {
            let viewModel = WMFAccountSettingsViewModel(
                localizedStrings: .init(title: "Account", accountGroupTitle: "Account", vanishAccountTitle: "Vanish", autoSignDiscussionsTitle: "Auto sign", talkPagePreferencesTitle: "Talk", talkPagePreferencesFooter: "Footer"),
                username: "Reader",
                autoSignDiscussions: true,
                userDefaultsStore: WMFMockKeyValueStore()
            )
            await viewModel.loadAndBuild()
            XCTAssertFalse(viewModel.sections.isEmpty)
            return viewModel
        }
    }

    func testStorageAndSyncingSettingsViewModelIsReleased() async {
        await assertReleased {
            let viewModel = WMFStorageAndSyncingSettingsViewModel(
                localizedStrings: .init(title: "Storage", syncSavedArticlesTitle: "Sync", syncSavedArticlesFooter: "Footer", showSavedReadingListTitle: "Show", showSavedReadingListFooter: "Footer", syncWithServerTitle: "Sync now", syncWithServerFooter: "Footer")
            )
            await viewModel.loadAndBuild()
            XCTAssertFalse(viewModel.sections.isEmpty)
            return viewModel
        }
    }

    func testYearInReviewSettingsViewModelIsReleased() async {
        await assertReleased {
            let viewModel = WMFYearInReviewSettingsViewModel(
                dataController: WMFSettingsDataController.shared,
                localizedStrings: .init(title: "Year in Review", description: "Description", toggleTitle: "Toggle")
            )
            await viewModel.loadAndBuild()
            XCTAssertFalse(viewModel.sections.isEmpty)
            return viewModel
        }
    }
}
