import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
@Suite(.serialized)
final class WMFDiscoverSettingsViewModelTests {

    private let fixture = WMFDataTestFixture()
    private let englishLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
    private var englishProject: WMFProject { .wikipedia(englishLanguage) }

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [englishLanguage])
        coreDataStore = try await fixture.makeTemporaryCoreDataStore()
    }

    // The data controllers read only this store, so a task that outlives a test never reads the store of another suite.
    private var coreDataStore: WMFCoreDataStore?

    private func makeDataController() -> WMFDiscoverReadingListDataController {
        WMFDiscoverReadingListDataController(coreDataStore: coreDataStore)
    }

    /// A controller that can generate a list: every related pages request gets the `related-pages-get` mock.
    private func makeDataControllerWithRelatedPages() -> WMFDiscoverReadingListDataController {
        let relatedPagesDataController = WMFRelatedPagesDataController(basicService: WMFMockBasicService(jsonResourceName: "related-pages-get"))
        return WMFDiscoverReadingListDataController(coreDataStore: coreDataStore, relatedPagesDataController: relatedPagesDataController)
    }

    private func makeInterestsDataController() -> WMFDiscoverInterestsDataController {
        WMFDiscoverInterestsDataController(coreDataStore: coreDataStore)
    }

    /// Adds to the Discover set, which the `interests` source reads. The For You set is separate.
    private func addInterest(_ title: String) async throws {
        try await makeInterestsDataController().addPage(title: title, project: englishProject)
    }

    private func makeEnabledSettings(dataController: WMFDiscoverReadingListDataController) async throws -> WMFDiscoverSettings {
        var settings = WMFDiscoverSettings.default
        settings.isEnabled = true
        try await dataController.saveSettings(settings)
        return settings
    }

    private func waitForSave(_ viewModel: WMFDiscoverSettingsViewModel) async {
        await viewModel.saveTask?.value
    }

    // MARK: - Loading

    @Test
    func loadReadsTheSettingsAndTheInterestCount() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            var settings = try await makeEnabledSettings(dataController: dataController)
            settings.cadence = .monthly
            settings.articleCount = 7
            try await dataController.saveSettings(settings)
            try await addInterest("Cat")
            try await addInterest("Dog")

            let viewModel = await WMFDiscoverSettingsViewModel.load(dataController: dataController, interestsDataController: makeInterestsDataController())

            #expect(viewModel.settings == settings)
            #expect(viewModel.interestCount == 2)
            #expect(viewModel.interestCountText == "2")
            #expect(viewModel.cadenceValue == WMFDiscoverSettingsViewModel.cadenceMonthlyTitle)
            #expect(viewModel.articleCountText == "7")
        }
    }

    // MARK: - Switch

    @Test
    func turningTheSwitchOffOnlyAsksForConfirmation() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let settings = try await makeEnabledSettings(dataController: dataController)
            let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController, interestsDataController: makeInterestsDataController())

            viewModel.isEnabledBinding.wrappedValue = false

            #expect(viewModel.isShowingTurnOffAlert)
            #expect(viewModel.settings.isEnabled)
            #expect(viewModel.isEnabledBinding.wrappedValue)
            await waitForSave(viewModel)
            #expect(await dataController.settings.isEnabled)
        }
    }

    @Test
    func confirmingTurnOffStoresTheChangeThrowsTheListAwayAndHidesTheRows() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataControllerWithRelatedPages()
            let settings = WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests)
            try await dataController.saveSettings(settings)
            try await addInterest("Cat")
            _ = try await dataController.generateRecommendations()
            let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController, interestsDataController: makeInterestsDataController())
            var turnOffCount = 0
            viewModel.didTurnOff = { turnOffCount += 1 }
            viewModel.isEnabledBinding.wrappedValue = false

            viewModel.confirmTurnOff()
            await waitForSave(viewModel)

            #expect(turnOffCount == 1)
            #expect(!viewModel.isShowingTurnOffAlert)
            #expect(!viewModel.settings.isEnabled)
            #expect(!viewModel.showsInterestsRow)
            #expect(viewModel.footerText == WMFDiscoverSettingsViewModel.footerOffText)
            #expect(await dataController.settings.isEnabled == false)
            #expect(try await dataController.fetchCurrentRecommendations().isEmpty)
        }
    }

    @Test
    func cancellingTurnOffKeepsDiscoverOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let settings = try await makeEnabledSettings(dataController: dataController)
            let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController, interestsDataController: makeInterestsDataController())
            var turnOffCount = 0
            viewModel.didTurnOff = { turnOffCount += 1 }
            viewModel.isEnabledBinding.wrappedValue = false

            viewModel.cancelTurnOff()

            #expect(turnOffCount == 0)
            #expect(!viewModel.isShowingTurnOffAlert)
            #expect(viewModel.settings.isEnabled)
            #expect(viewModel.footerText == WMFDiscoverSettingsViewModel.footerOnText)
        }
    }

    @Test
    func turningTheSwitchOnStoresTheChangeAtOnce() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = WMFDiscoverSettingsViewModel(settings: .default, dataController: dataController, interestsDataController: makeInterestsDataController())

            viewModel.isEnabledBinding.wrappedValue = true
            await waitForSave(viewModel)

            #expect(!viewModel.isShowingTurnOffAlert)
            #expect(viewModel.settings.isEnabled)
            #expect(viewModel.showsInterestsRow)
            #expect(await dataController.settings.isEnabled)
        }
    }

    // MARK: - List size and cadence

    @Test
    func fastStepperTapsReachTheStoreInOrder() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let settings = try await makeEnabledSettings(dataController: dataController)
            let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController, interestsDataController: makeInterestsDataController())

            viewModel.articleCountBinding.wrappedValue = 6
            viewModel.articleCountBinding.wrappedValue = 7
            viewModel.articleCountBinding.wrappedValue = 8
            await waitForSave(viewModel)

            #expect(viewModel.settings.articleCount == 8)
            #expect(await dataController.settings.articleCount == 8)
            #expect(try await dataController.isGenerationDue())
        }
    }

    @Test
    func choosingACadenceStoresItAndChangesTheTexts() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let settings = try await makeEnabledSettings(dataController: dataController)
            let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController, interestsDataController: makeInterestsDataController())

            viewModel.cadenceBinding.wrappedValue = .daily
            await waitForSave(viewModel)

            #expect(viewModel.settings.cadence == .daily)
            #expect(viewModel.cadenceValue == WMFDiscoverSettingsViewModel.cadenceDailyTitle)
            #expect(viewModel.turnOffAlertMessage == WMFDiscoverSettingsViewModel.turnOffAlertMessageDaily)
            #expect(await dataController.settings.cadence == .daily)
        }
    }

    @Test
    func settingTheSameValueDoesNotSave() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let settings = try await makeEnabledSettings(dataController: dataController)
            let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController, interestsDataController: makeInterestsDataController())

            viewModel.articleCountBinding.wrappedValue = settings.articleCount
            viewModel.cadenceBinding.wrappedValue = settings.cadence

            #expect(viewModel.saveTask == nil)
        }
    }

    // MARK: - Source

    @Test
    func theInterestsRowShowsOnlyForTheInterestsSource() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            var settings = try await makeEnabledSettings(dataController: dataController)
            settings.source = .saved
            let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController, interestsDataController: makeInterestsDataController())

            #expect(!viewModel.showsInterestsRow)
            #expect(viewModel.sourceSubtitle == WMFDiscoverSettingsViewModel.sourceSavedSubtitle)
        }
    }

    @Test
    func refreshPicksUpASourceChangedBehindTheScreen() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            var settings = try await makeEnabledSettings(dataController: dataController)
            let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController, interestsDataController: makeInterestsDataController())
            settings.source = .history
            try await dataController.saveSettings(settings)
            try await addInterest("Cat")

            viewModel.refresh()
            await viewModel.refreshTask?.value

            #expect(viewModel.settings.source == .history)
            #expect(viewModel.sourceSubtitle == WMFDiscoverSettingsViewModel.sourceHistorySubtitle)
            #expect(viewModel.interestCount == 1)
        }
    }

    @Test
    func theRowsCallTheirClosures() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = WMFDiscoverSettingsViewModel(settings: .default, dataController: makeDataController(), interestsDataController: makeInterestsDataController())
            var didTapSource = false
            var didTapInterests = false
            viewModel.didTapSource = { didTapSource = true }
            viewModel.didTapInterests = { didTapInterests = true }

            viewModel.tapSource()
            viewModel.tapInterests()

            #expect(didTapSource)
            #expect(didTapInterests)
        }
    }
}
