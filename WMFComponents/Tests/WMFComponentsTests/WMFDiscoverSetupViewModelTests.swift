import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
@Suite(.serialized)
final class WMFDiscoverSetupViewModelTests {

    private let fixture = WMFDataTestFixture()
    private let englishLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
    private var englishProject: WMFProject { .wikipedia(englishLanguage) }

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [englishLanguage])
        WMFDataEnvironment.current.coreDataStore = try await fixture.makeTemporaryCoreDataStore()
    }

    private func makeDataController() -> WMFDiscoverReadingListDataController {
        WMFDiscoverReadingListDataController()
    }

    private func makeViewModel(availableSources: [WMFDiscoverSource] = [.interests, .saved, .history], currentSource: WMFDiscoverSource = .interests, dataController: WMFDiscoverReadingListDataController) -> WMFDiscoverSetupViewModel {
        let viewModel = WMFDiscoverSetupViewModel(availableSources: availableSources, currentSource: currentSource, readingListDataController: dataController)
        viewModel.loggingDelegate = loggingDelegate
        return viewModel
    }

    private func continueAndWait(_ viewModel: WMFDiscoverSetupViewModel) async {
        viewModel.tapContinue()
        await viewModel.continueTask?.value
    }

    private let loggingDelegate = MockLoggingDelegate()

    // MARK: - Pre-selection

    @Test
    func interestsIsPreSelectedOnTheFirstRun() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = await WMFDiscoverSetupViewModel.load(readingListDataController: makeDataController())

            #expect(viewModel.availableSources == [.interests])
            #expect(viewModel.selectedSource == .interests)
        }
    }

    @Test
    func theCurrentSourceIsPreSelectedWhenItIsOffered() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = makeViewModel(currentSource: .history, dataController: dataController)

            #expect(viewModel.selectedSource == .history)
        }
    }

    @Test
    func interestsIsPreSelectedWhenTheCurrentSourceIsNotOffered() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(availableSources: [.interests, .saved], currentSource: .history, dataController: makeDataController())

            #expect(viewModel.selectedSource == .interests)
        }
    }

    @Test
    func loadOffersTheSourcesTheDataControllerReports() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let pageViewsDataController = try WMFPageViewsDataController()
            _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: englishProject, previousPageViewObjectID: nil)

            let viewModel = await WMFDiscoverSetupViewModel.load(readingListDataController: makeDataController())

            #expect(viewModel.availableSources == [.interests, .history])
        }
    }

    // MARK: - Selection

    @Test
    func tappingAnOptionOnlySelectsIt() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = makeViewModel(dataController: dataController)

            viewModel.select(.saved)

            #expect(viewModel.selectedSource == .saved)
            #expect(await dataController.settings == .default, "nothing is saved before Continue")
        }
    }

    @Test
    func anOptionThatIsNotOfferedCannotBeSelected() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(availableSources: [.interests], dataController: makeDataController())

            viewModel.select(.history)

            #expect(viewModel.selectedSource == .interests)
        }
    }

    // MARK: - Continue

    @Test
    func continueWithInterestsStoresTheChoiceWithoutTurningDiscoverOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = makeViewModel(dataController: dataController)
            var interestsCalls = 0
            var turnOnCalls = 0
            viewModel.didChooseInterests = { interestsCalls += 1 }
            viewModel.didTurnOnDiscover = { turnOnCalls += 1 }

            await continueAndWait(viewModel)

            let settings = await dataController.settings
            #expect(settings.source == .interests)
            #expect(settings.isEnabled == false)
            #expect(interestsCalls == 1)
            #expect(turnOnCalls == 0)
            #expect(WMFDiscoverDataController.shared.hasDismissedAnnouncement == false, "the interests screen hides the card when the reader taps Done")
            #expect(loggingDelegate.continueSources == [.interests])
        }
    }

    @Test
    func continueWithSavedArticlesTurnsDiscoverOnAndHidesTheCard() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = makeViewModel(dataController: dataController)
            var interestsCalls = 0
            var turnOnCalls = 0
            viewModel.didChooseInterests = { interestsCalls += 1 }
            viewModel.didTurnOnDiscover = { turnOnCalls += 1 }

            viewModel.select(.saved)
            await continueAndWait(viewModel)

            let settings = await dataController.settings
            #expect(settings.source == .saved)
            #expect(settings.isEnabled == true)
            #expect(settings.cadence == WMFDiscoverSettings.default.cadence, "the other settings keep their values")
            #expect(interestsCalls == 0)
            #expect(turnOnCalls == 1)
            #expect(WMFDiscoverDataController.shared.hasDismissedAnnouncement)
            #expect(loggingDelegate.continueSources == [.saved])
        }
    }

    @Test
    func continueWithHistoryTurnsDiscoverOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = makeViewModel(dataController: dataController)
            var turnOnCalls = 0
            viewModel.didTurnOnDiscover = { turnOnCalls += 1 }

            viewModel.select(.history)
            await continueAndWait(viewModel)

            let settings = await dataController.settings
            #expect(settings.source == .history)
            #expect(settings.isEnabled == true)
            #expect(turnOnCalls == 1)
        }
    }

    @Test
    func aSecondTapOnContinueWhileTheFirstRunsIsIgnored() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(dataController: makeDataController())
            var turnOnCalls = 0
            viewModel.didTurnOnDiscover = { turnOnCalls += 1 }

            viewModel.select(.saved)
            viewModel.tapContinue()
            viewModel.tapContinue()
            await viewModel.continueTask?.value

            #expect(turnOnCalls == 1)
            #expect(loggingDelegate.continueSources == [.saved])
        }
    }

    // MARK: - Logging

    @Test
    func theImpressionIsLoggedOncePerInstance() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(dataController: makeDataController())

            viewModel.viewDidAppear()
            viewModel.viewDidAppear()

            #expect(loggingDelegate.impressions == 1)
        }
    }

    private final class MockLoggingDelegate: WMFDiscoverSetupLoggingDelegate {
        var impressions = 0
        var continueSources: [WMFDiscoverSource] = []

        func discoverSetupDidAppear() { impressions += 1 }
        func discoverSetupDidTapContinue(source: WMFDiscoverSource) { continueSources.append(source) }
    }
}
