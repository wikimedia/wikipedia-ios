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
        coreDataStore = try await fixture.makeTemporaryCoreDataStore()
    }

    // The data controller reads only this store, so a task that outlives a test never reads the store of another suite.
    private var coreDataStore: WMFCoreDataStore?

    private func makeDataController() -> WMFDiscoverReadingListDataController {
        WMFDiscoverReadingListDataController(coreDataStore: coreDataStore)
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
            let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: coreDataStore)
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
    func continueWithInterestsOpensTheInterestsScreenAndSavesNothing() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            var storedSettings = WMFDiscoverSettings.default
            storedSettings.source = .saved
            try await dataController.saveSettings(storedSettings)
            let viewModel = makeViewModel(dataController: dataController)
            var interestsCalls = 0
            var turnOnCalls = 0
            viewModel.didChooseInterests = { interestsCalls += 1 }
            viewModel.didTurnOnDiscover = { turnOnCalls += 1 }

            await continueAndWait(viewModel)

            let settings = await dataController.settings
            #expect(settings.source == .saved, "the interests screen saves the source once the reader selected an interest")
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

    // MARK: - From Settings

    private func makeSettingsViewModel(currentSource: WMFDiscoverSource = .saved, dataController: WMFDiscoverReadingListDataController) async throws -> WMFDiscoverSetupViewModel {
        var settings = WMFDiscoverSettings.default
        settings.isEnabled = true
        settings.source = currentSource
        try await dataController.saveSettings(settings)
        return WMFDiscoverSetupViewModel(availableSources: [.interests, .saved, .history], currentSource: currentSource, presentation: .settings, readingListDataController: dataController)
    }

    @Test
    func fromSettingsANewSourceAsksForConfirmationFirst() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = try await makeSettingsViewModel(dataController: dataController)

            viewModel.select(.history)

            #expect(viewModel.isShowingAdjustAlert)
            #expect(viewModel.pendingSource == .history)
            #expect(viewModel.selectedSource == .saved)
        }
    }

    @Test
    func fromSettingsTheSavedSourceIsSelectedWithoutAnAlert() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = try await makeSettingsViewModel(dataController: dataController)
            viewModel.select(.history)
            viewModel.confirmAdjust()

            viewModel.select(.saved)

            #expect(!viewModel.isShowingAdjustAlert)
            #expect(viewModel.selectedSource == .saved)
        }
    }

    @Test
    func adjustSelectsTheNewSourceAndNeverMindKeepsTheOldOne() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = try await makeSettingsViewModel(dataController: dataController)

            viewModel.select(.history)
            viewModel.cancelAdjust()
            #expect(viewModel.selectedSource == .saved)
            #expect(viewModel.pendingSource == nil)
            #expect(!viewModel.isShowingAdjustAlert)
            #expect(viewModel.commitTask == nil)
            #expect(await dataController.settings.source == .saved)

            viewModel.select(.history)
            viewModel.confirmAdjust()
            await viewModel.commitTask?.value
            #expect(viewModel.selectedSource == .history)
            #expect(!viewModel.isShowingAdjustAlert)
            #expect(await dataController.settings.source == .history)
        }
    }

    @Test
    func adjustToInterestsOpensTheInterestsScreenWithoutSavingTheSource() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = try await makeSettingsViewModel(dataController: dataController)
            var interestsCalls = 0
            var changes = 0
            viewModel.didChooseInterests = { interestsCalls += 1 }
            viewModel.didChangeSource = { _, _ in changes += 1 }

            viewModel.select(.interests)
            viewModel.confirmAdjust()

            #expect(interestsCalls == 1)
            #expect(changes == 0)
            #expect(viewModel.selectedSource == .interests)
            #expect(viewModel.commitTask == nil)
            #expect(await dataController.settings.source == .saved, "the interests screen saves the source, after the reader selected an interest")
        }
    }

    @Test
    func adjustToSavedArticlesSavesTheSourceAndReportsTheChange() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = try await makeSettingsViewModel(currentSource: .history, dataController: dataController)
            var changes: [(WMFDiscoverSource, WMFDiscoverSource)] = []
            viewModel.didChangeSource = { changes.append(($0, $1)) }

            viewModel.select(.saved)
            viewModel.confirmAdjust()
            await viewModel.commitTask?.value

            #expect(await dataController.settings.source == .saved)
            #expect(changes.count == 1)
            #expect(changes.first?.0 == .history)
            #expect(changes.first?.1 == .saved)
        }
    }

    @Test
    func adjustToHistorySavesTheWholeSettingsWithTheNewSource() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = try await makeSettingsViewModel(dataController: dataController)
            var settings = await dataController.settings
            settings.cadence = .daily
            try await dataController.saveSettings(settings)
            var changes: [(WMFDiscoverSource, WMFDiscoverSource)] = []
            viewModel.didChangeSource = { changes.append(($0, $1)) }

            viewModel.select(.history)
            viewModel.confirmAdjust()
            await viewModel.commitTask?.value

            let saved = await dataController.settings
            #expect(saved.source == .history)
            #expect(saved.isEnabled == true)
            #expect(saved.cadence == .daily, "only the source changes")
            #expect(changes.count == 1)
            #expect(changes.first?.0 == .saved)
            #expect(changes.first?.1 == .history)
        }
    }

    @Test
    func selectingTheCurrentSourceSavesAndReportsNothing() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = try await makeSettingsViewModel(dataController: dataController)
            var changes = 0
            viewModel.didChangeSource = { _, _ in changes += 1 }

            viewModel.select(.saved)

            #expect(!viewModel.isShowingAdjustAlert)
            #expect(viewModel.commitTask == nil)
            #expect(changes == 0)
            #expect(await dataController.settings.source == .saved)
        }
    }

    @Test
    func continueDoesNothingFromSettings() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = try await makeSettingsViewModel(dataController: dataController)

            viewModel.tapContinue()

            #expect(viewModel.continueTask == nil)
        }
    }

    @Test
    func fromSettingsTheCurrentSourceIsOfferedEvenWithoutArticles() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            var settings = WMFDiscoverSettings.default
            settings.isEnabled = true
            settings.source = .saved
            try await dataController.saveSettings(settings)
            let viewModel = WMFDiscoverSetupViewModel(availableSources: [.interests, .history], currentSource: .saved, presentation: .settings, readingListDataController: dataController)

            #expect(viewModel.availableSources == [.interests, .saved, .history])
            #expect(viewModel.selectedSource == .saved)
        }
    }

    @Test
    func goingBackToTheOpeningSourceAfterAdjustToInterestsChangesNothing() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = try await makeSettingsViewModel(dataController: dataController)
            var changes = 0
            viewModel.didChangeSource = { _, _ in changes += 1 }
            viewModel.select(.interests)
            viewModel.confirmAdjust()

            viewModel.select(.saved)

            #expect(!viewModel.isShowingAdjustAlert)
            #expect(viewModel.selectedSource == .saved)
            #expect(viewModel.commitTask == nil)
            #expect(changes == 0)
            #expect(await dataController.settings.source == .saved)
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
