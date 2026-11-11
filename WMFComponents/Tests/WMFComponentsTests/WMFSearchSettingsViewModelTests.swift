import XCTest
import SwiftUI
@testable import WMFComponents
import WMFDataMocks

@MainActor
final class WMFSearchSettingsViewModelTests: XCTestCase {

    private func makeViewModel(showsSemanticSearchItem: Bool, showSemanticSearchEntryPoint: Bool = true, onToggle: ((Bool) -> Void)? = nil) async -> WMFSearchSettingsViewModel {
        let viewModel = WMFSearchSettingsViewModel(
            showLanguageBar: true,
            openAppOnSearchTab: false,
            showsSemanticSearchItem: showsSemanticSearchItem,
            showSemanticSearchEntryPoint: showSemanticSearchEntryPoint,
            userDefaultsStore: WMFMockKeyValueStore(),
            onToggleShowSemanticSearchEntryPoint: onToggle
        )
        await viewModel.loadAndBuild()
        return viewModel
    }

    private func items(of viewModel: WMFSearchSettingsViewModel) -> [SettingsItem] {
        viewModel.sections.flatMap { $0.items }
    }

    func testSemanticSearchRowIsAbsentForReadersWithoutTheEntryPoint() async {
        let viewModel = await makeViewModel(showsSemanticSearchItem: false)

        XCTAssertEqual(items(of: viewModel).map(\.title), [viewModel.showLanguagesTitle, viewModel.openOnSearchTabTitle])
    }

    func testSemanticSearchRowSitsBetweenTheExistingToggles() async {
        let viewModel = await makeViewModel(showsSemanticSearchItem: true)

        let items = items(of: viewModel)
        XCTAssertEqual(items.map(\.title), [viewModel.showLanguagesTitle, viewModel.semanticSearchTitle, viewModel.openOnSearchTabTitle])
        XCTAssertEqual(items[1].subtitle, viewModel.semanticSearchSubtitle)
        XCTAssertTrue(items[1].showsBetaBadge)
        XCTAssertFalse(items[0].showsBetaBadge)
    }

    func testViewModelIsReleasedAfterBuildingItsSections() async {
        var viewModel: WMFSearchSettingsViewModel? = await makeViewModel(showsSemanticSearchItem: true)
        weak var weakViewModel = viewModel
        XCTAssertFalse(viewModel?.sections.isEmpty ?? true)

        viewModel = nil

        // The init of the view model queues a Task that holds it until the Task runs.
        let released = expectation(description: "The view model is released")
        Task {
            while weakViewModel != nil {
                await Task.yield()
            }
            released.fulfill()
        }
        await fulfillment(of: [released], timeout: 1)
        XCTAssertNil(weakViewModel, "The toggle bindings in the sections must not retain the view model")
    }

    func testTogglingTheRowUpdatesTheStateAndNotifies() async {
        var receivedValues: [Bool] = []
        let viewModel = await makeViewModel(showsSemanticSearchItem: true, showSemanticSearchEntryPoint: false) { receivedValues.append($0) }

        guard case let .toggle(binding) = items(of: viewModel)[1].accessory else {
            return XCTFail("The semantic search row is a toggle")
        }
        XCTAssertFalse(binding.wrappedValue)

        binding.wrappedValue = true

        XCTAssertTrue(viewModel.showSemanticSearchEntryPoint)
        XCTAssertEqual(receivedValues, [true])
    }
}
