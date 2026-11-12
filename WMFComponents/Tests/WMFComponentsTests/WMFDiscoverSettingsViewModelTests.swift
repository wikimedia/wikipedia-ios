import Foundation
import os
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

    /// A new reader has no interest yet. The default source is interests, so the switch alone would make an empty list.
    @Test
    func turningTheSwitchOnWithoutInterestsAsksForTheInterestsScreen() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = await WMFDiscoverSettingsViewModel.load(dataController: dataController, interestsDataController: makeInterestsDataController())
            var interestsScreenRequests = 0
            viewModel.didTurnOnWithoutInterests = { interestsScreenRequests += 1 }

            viewModel.isEnabledBinding.wrappedValue = true

            #expect(viewModel.settings.source == .interests)
            #expect(viewModel.interestCount == 0)
            #expect(interestsScreenRequests == 1)
            #expect(viewModel.settings.isEnabled, "Discover goes on before the screen opens")
        }
    }

    @Test
    func turningTheSwitchOnWithInterestsOrAnotherSourceDoesNotAskForTheInterestsScreen() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            var interestsScreenRequests = 0

            let withInterests = WMFDiscoverSettingsViewModel(settings: .default, interestCount: 1, dataController: dataController, interestsDataController: makeInterestsDataController())
            withInterests.didTurnOnWithoutInterests = { interestsScreenRequests += 1 }
            withInterests.isEnabledBinding.wrappedValue = true

            var savedSettings = WMFDiscoverSettings.default
            savedSettings.source = .saved
            let withSavedSource = WMFDiscoverSettingsViewModel(settings: savedSettings, interestCount: 0, dataController: dataController, interestsDataController: makeInterestsDataController())
            withSavedSource.didTurnOnWithoutInterests = { interestsScreenRequests += 1 }
            withSavedSource.isEnabledBinding.wrappedValue = true

            #expect(interestsScreenRequests == 0)
            #expect(withInterests.settings.isEnabled)
            #expect(withSavedSource.settings.isEnabled)
        }
    }

    /// Back on the interests screen that the switch opened, with no interest picked. Discover goes
    /// back off, as it was before the switch. No alert and no toast: the reader turned nothing off.
    @Test
    func undoTurnOnStoresDiscoverOffWithoutTheAlertOrTheToast() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            let viewModel = WMFDiscoverSettingsViewModel(settings: .default, interestCount: 0, dataController: dataController, interestsDataController: makeInterestsDataController())
            var turnOffReports = 0
            viewModel.didTurnOff = { turnOffReports += 1 }
            viewModel.isEnabledBinding.wrappedValue = true

            viewModel.undoTurnOn()
            await waitForSave(viewModel)

            #expect(!viewModel.settings.isEnabled)
            #expect(!viewModel.isShowingTurnOffAlert)
            #expect(turnOffReports == 0)
            #expect(await dataController.settings.isEnabled == false)
        }
    }

    /// The screen reads the settings again when the interests screen pops, and the undo arrives in
    /// the same moment. The read is held in the store while the undo lands, so the read sees the
    /// switch on. The read must not put the switch back on.
    @Test
    func refreshKeepsASaveThatStartsDuringTheRead() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = GatedKeyValueStore()
            let dataController = WMFDiscoverReadingListDataController(coreDataStore: coreDataStore, userDefaultsStore: store)
            let settings = try await makeEnabledSettings(dataController: dataController)
            let viewModel = WMFDiscoverSettingsViewModel(settings: settings, interestCount: 0, dataController: dataController, interestsDataController: makeInterestsDataController())

            store.holdNext(.load)
            viewModel.refresh()
            await store.waitForHeldOperationToStart()
            viewModel.undoTurnOn()
            store.open()
            await viewModel.refreshTask?.value

            #expect(!viewModel.settings.isEnabled)
            #expect(await dataController.settings.isEnabled == false)
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

    /// Back arrives while a save is still in flight. The coordinator must read the settings the reader left.
    @Test
    func leaveWaitsForTheSaveInFlight() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = GatedKeyValueStore()
            let dataController = WMFDiscoverReadingListDataController(coreDataStore: coreDataStore, userDefaultsStore: store)
            let settings = try await makeEnabledSettings(dataController: dataController)
            let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController, interestsDataController: makeInterestsDataController())
            var leaveCount = 0
            var didLeaveContinuation: CheckedContinuation<Void, Never>?
            viewModel.didLeave = {
                leaveCount += 1
                didLeaveContinuation?.resume()
                didLeaveContinuation = nil
            }

            store.holdNext(.save)
            viewModel.articleCountBinding.wrappedValue = 9
            await store.waitForHeldOperationToStart()
            viewModel.leave()
            await Task.yield()
            await Task.yield()
            #expect(leaveCount == 0, "the screen leaves after the save")

            if leaveCount == 0 {
                await withCheckedContinuation { continuation in
                    didLeaveContinuation = continuation
                    store.open()
                }
            } else {
                store.open()
            }

            #expect(leaveCount == 1)
            #expect(await dataController.settings.articleCount == 9)
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

/// A key value store that can hold one save or one load until the test lets it through.
private final class GatedKeyValueStore: WMFKeyValueStore, Sendable {

    enum Operation {
        case save
        case load
    }

    private struct State {
        var heldOperation: Operation?
        var heldOperationDidStart = false
        var startWaiter: CheckedContinuation<Void, Never>?
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let values = OSAllocatedUnfairLock<[String: Data]>(initialState: [:])
    private let gate = DispatchSemaphore(value: 0)

    /// The next operation of this kind waits for `open()`.
    func holdNext(_ operation: Operation) {
        state.withLock {
            $0.heldOperation = operation
            $0.heldOperationDidStart = false
        }
    }

    /// Returns when the held operation has begun.
    func waitForHeldOperationToStart() async {
        await withCheckedContinuation { continuation in
            let didStart = state.withLock { state -> Bool in
                if state.heldOperationDidStart { return true }
                state.startWaiter = continuation
                return false
            }
            if didStart {
                continuation.resume()
            }
        }
    }

    func open() {
        gate.signal()
    }

    func load<T: Codable>(key: String...) throws -> T? {
        waitIfHeld(.load)
        guard let data = values.withLock({ $0[key.joined(separator: "/")] }) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func save<T: Codable>(key: String..., value: T) throws {
        waitIfHeld(.save)
        let data = try JSONEncoder().encode(value)
        values.withLock { $0[key.joined(separator: "/")] = data }
    }

    private func waitIfHeld(_ operation: Operation) {
        let holds = state.withLock { state -> Bool in
            guard state.heldOperation == operation else { return false }
            state.heldOperation = nil
            state.heldOperationDidStart = true
            return true
        }
        guard holds else { return }
        let waiter = state.withLock { state -> CheckedContinuation<Void, Never>? in
            let waiter = state.startWaiter
            state.startWaiter = nil
            return waiter
        }
        waiter?.resume()
        // The timeout keeps a failed test from hanging the actor for good.
        _ = gate.wait(timeout: .now() + 5)
    }

    func remove(key: String...) throws {
        values.withLock { _ = $0.removeValue(forKey: key.joined(separator: "/")) }
    }

    func keys(inDirectory directory: String) throws -> [String] {
        values.withLock { $0.keys }.filter { $0.hasPrefix(directory + "/") }.map { String($0.dropFirst(directory.count + 1)) }
    }
}
