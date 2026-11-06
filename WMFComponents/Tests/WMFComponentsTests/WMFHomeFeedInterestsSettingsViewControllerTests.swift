import Foundation
import Testing
import UIKit
import WMFDataTestSupport
import WMFNativeLocalizations
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

/// Done on the interests screen: only the Discover screen has it, and it is off until an interest is selected.
@MainActor
@Suite(.serialized)
final class WMFHomeFeedInterestsSettingsViewControllerTests {

    private let fixture = WMFDataTestFixture()
    private let englishProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func makeDiscoverStore(titles: [String] = []) async throws -> WMFDiscoverInterestsStore {
        let dataController = WMFDiscoverInterestsDataController(coreDataStore: try await fixture.makeTemporaryCoreDataStore(), userDefaultsStore: WMFMockKeyValueStore())
        let pages = titles.map { WMFDiscoverInterests.Page(title: $0, project: englishProject) }
        return WMFDiscoverInterestsStore(interests: WMFDiscoverInterests(topics: [], pages: pages), dataController: dataController)
    }

    private func makeViewModel(discoverInterestsStore: WMFDiscoverInterestsStore?) -> WMFHomeFeedInterestsSettingsViewModel {
        let homeDataController = WMFHomeDataController(basicService: WMFMockBasicService(jsonResourceName: "random-articles-get"), userDefaultsStore: WMFMockKeyValueStore())
        let searchDataController = WMFArticleSearchDataController(basicService: WMFMockBasicService(jsonResourceName: "article-prefix-search-get"))
        return WMFHomeFeedInterestsSettingsViewModel(dataController: homeDataController, discoverInterestsStore: discoverInterestsStore, searchDataController: searchDataController, project: englishProject, logDidTapTopic: {}, logDidTapArticle: {}, logDidTapDeselectAll: {})
    }

    /// Loads the view and runs the appearance calls, which configure the navigation bar.
    private func show(_ viewController: UIViewController) {
        viewController.loadViewIfNeeded()
        viewController.beginAppearanceTransition(true, animated: false)
        viewController.endAppearanceTransition()
    }

    @Test
    func forYouHasNoDone() {
        let viewController = WMFHomeFeedInterestsSettingsViewController(viewModel: makeViewModel(discoverInterestsStore: nil))
        show(viewController)

        #expect(viewController.navigationItem.rightBarButtonItem == nil)
    }

    @Test
    func doneIsOffUntilATopicIsSelected() async throws {
        let viewModel = makeViewModel(discoverInterestsStore: try await makeDiscoverStore())
        let viewController = WMFHomeFeedInterestsSettingsViewController(viewModel: viewModel, doneButtonHandler: {})
        show(viewController)

        let doneButton = try #require(viewController.navigationItem.rightBarButtonItem)
        #expect(doneButton.title == CommonStrings.doneTitle)
        #expect(doneButton.accessibilityIdentifier == AccessibilityIdentifiers.Interests.doneButton)
        #expect(doneButton.isEnabled == false)

        viewModel.toggleTopic(.music)
        #expect(doneButton.isEnabled == true)

        viewModel.toggleTopic(.music)
        #expect(doneButton.isEnabled == false)
    }

    @Test
    func doneIsOnWhenTheScreenOpensWithSavedPages() async throws {
        let viewModel = makeViewModel(discoverInterestsStore: try await makeDiscoverStore(titles: ["Cat"]))
        let viewController = WMFHomeFeedInterestsSettingsViewController(viewModel: viewModel, doneButtonHandler: {})
        show(viewController)

        for await count in viewModel.$selectedArticleCount.values where count == 1 {
            break
        }

        #expect(viewController.navigationItem.rightBarButtonItem?.isEnabled == true)
    }

    @Test
    func doneCallsTheHandler() async throws {
        var taps = 0
        let viewModel = makeViewModel(discoverInterestsStore: try await makeDiscoverStore())
        let viewController = WMFHomeFeedInterestsSettingsViewController(viewModel: viewModel, doneButtonHandler: { taps += 1 })
        show(viewController)

        let doneButton = try #require(viewController.navigationItem.rightBarButtonItem)
        _ = try #require(doneButton.target).perform(try #require(doneButton.action))

        #expect(taps == 1)
    }
}
