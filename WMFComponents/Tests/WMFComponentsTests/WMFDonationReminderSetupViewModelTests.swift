import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
final class WMFDonationReminderSetupViewModelTests {

    private let fixture = WMFDataTestFixture()

    private func makeViewModel(origin: WMFDonationReminderSetupViewModel.Origin = .banner, experimentEndDate: Date? = nil) -> WMFDonationReminderSetupViewModel {
        WMFDonationReminderSetupViewModel(
            configuration: WMFDonationReminderSetupViewModel.experimentConfiguration(currencyCode: "EUR"),
            origin: origin,
            experimentEndDate: experimentEndDate
        )
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
    }

    @Test
    func startsWithConfigurationDefaultsAndCanConfirm() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel()

            #expect(viewModel.selectedTriggerOption?.trigger == .articlesRead(count: 5))
            #expect(viewModel.selectedPresetAmount == 1)
            #expect(viewModel.isReminderEnabled)
            #expect(viewModel.canConfirm)
        }
    }

    @Test
    func customAmountDeselectsPresetAndBecomesFinalAmount() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel()

            viewModel.customAmount = Decimal(string: "7.50") ?? 0
            viewModel.customAmountDidChange()

            #expect(viewModel.selectedPresetAmount == nil)
            #expect(viewModel.finalAmount == Decimal(string: "7.50"))
            #expect(viewModel.canConfirm)
        }
    }

    @Test
    func selectingPresetClearsCustomAmount() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel()
            viewModel.customAmount = Decimal(string: "7.50") ?? 0
            viewModel.customAmountDidChange()

            viewModel.selectPresetAmount(5)

            #expect(viewModel.customAmount == 0)
            #expect(viewModel.selectedPresetAmount == 5)
            #expect(viewModel.finalAmount == 5)
        }
    }

    @Test
    func withoutAnySelectedAmountConfirmIsDisabledAndDoesNotSave() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel()

            viewModel.selectedPresetAmount = nil

            #expect(viewModel.canConfirm == false)

            viewModel.confirm()

            #expect(WMFDonationReminderDataController.shared.loadReminder() == nil)
        }
    }

    @Test
    func confirmSavesEnabledReminderAndNotifies() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel()
            var confirmedReminder: WMFDonationReminder?
            viewModel.didConfirmReminder = { reminder in
                confirmedReminder = reminder
            }
            viewModel.selectedTriggerOptionIdentifier = "articles-20"

            viewModel.confirm()

            let savedReminder = WMFDonationReminderDataController.shared.loadReminder()
            #expect(savedReminder?.trigger == .articlesRead(count: 20))
            #expect(savedReminder?.amount == 1)
            #expect(savedReminder?.currencyCode == "EUR")
            #expect(savedReminder?.isEnabled == true)
            #expect(confirmedReminder == savedReminder)
        }
    }

    @Test
    func selectedPresetIsConfirmableEvenBelowCurrencyMinimum() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let configuration = WMFDonationReminderSetupViewModel.experimentConfiguration(currencyCode: "BRL", minimumAmount: 5)
            let viewModel = WMFDonationReminderSetupViewModel(configuration: configuration, origin: .banner)

            #expect(viewModel.selectedPresetAmount == 1)
            #expect(viewModel.canConfirm)
        }
    }

    @Test
    func customAmountBelowMinimumShowsErrorAndBlocksConfirm() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel()

            viewModel.customAmount = Decimal(string: "0.50") ?? 0
            viewModel.customAmountDidChange()

            #expect(viewModel.customAmountErrorText != nil)
            #expect(viewModel.canConfirm == false)

            viewModel.confirm()

            #expect(WMFDonationReminderDataController.shared.loadReminder() == nil)
        }
    }

    @Test
    func customAmountAboveMaximumShowsErrorAndBlocksConfirm() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let configuration = WMFDonationReminderSetupViewModel.experimentConfiguration(currencyCode: "EUR", minimumAmount: 1, maximumAmount: 25_000)
            let viewModel = WMFDonationReminderSetupViewModel(configuration: configuration, origin: .banner)

            viewModel.customAmount = 30_000
            viewModel.customAmountDidChange()

            #expect(viewModel.customAmountErrorText != nil)
            #expect(viewModel.canConfirm == false)

            viewModel.confirm()

            #expect(WMFDonationReminderDataController.shared.loadReminder() == nil)
        }
    }

    @Test
    func customAmountAtMaximumHasNoErrorAndCanConfirm() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let configuration = WMFDonationReminderSetupViewModel.experimentConfiguration(currencyCode: "EUR", minimumAmount: 1, maximumAmount: 25_000)
            let viewModel = WMFDonationReminderSetupViewModel(configuration: configuration, origin: .banner)

            viewModel.customAmount = 25_000
            viewModel.customAmountDidChange()

            #expect(viewModel.customAmountErrorText == nil)
            #expect(viewModel.canConfirm)
        }
    }

    @Test
    func customAmountWithoutConfiguredMaximumHasNoUpperLimit() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel()

            viewModel.customAmount = 1_000_000
            viewModel.customAmountDidChange()

            #expect(viewModel.customAmountErrorText == nil)
            #expect(viewModel.canConfirm)
        }
    }

    @Test
    func customAmountAtMinimumHasNoErrorAndCanConfirm() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel()

            viewModel.customAmount = 1
            viewModel.customAmountDidChange()

            #expect(viewModel.customAmountErrorText == nil)
            #expect(viewModel.canConfirm)
        }
    }

    @Test
    func settingsTogglingOffDisablesSavedReminderImmediately() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let existingReminder = WMFDonationReminder(trigger: .articlesRead(count: 10), amount: 3, currencyCode: "EUR", createdDate: Date(), isEnabled: true)
            WMFDonationReminderDataController.shared.saveReminder(existingReminder)

            let viewModel = makeViewModel(origin: .settings)
            viewModel.isReminderEnabled = false

            let savedReminder = WMFDonationReminderDataController.shared.loadReminder()
            #expect(savedReminder?.isEnabled == false)
            #expect(savedReminder?.trigger == .articlesRead(count: 10))
            #expect(savedReminder?.amount == 3)
        }
    }

    @Test
    func settingsTogglingBackOnReenablesSavedReminder() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let existingReminder = WMFDonationReminder(trigger: .articlesRead(count: 10), amount: 3, currencyCode: "EUR", createdDate: Date(), isEnabled: true)
            WMFDonationReminderDataController.shared.saveReminder(existingReminder)

            let viewModel = makeViewModel(origin: .settings)
            viewModel.isReminderEnabled = false
            viewModel.isReminderEnabled = true

            #expect(WMFDonationReminderDataController.shared.loadReminder()?.isEnabled == true)
        }
    }

    @Test
    func settingsTogglingWithoutSavedReminderPersistsNothing() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(origin: .settings)

            viewModel.isReminderEnabled = true
            viewModel.isReminderEnabled = false

            #expect(WMFDonationReminderDataController.shared.loadReminder() == nil)
        }
    }

    @Test
    func settingsPrefillsFromSavedReminder() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let existingReminder = WMFDonationReminder(trigger: .articlesRead(count: 20), amount: 5, currencyCode: "EUR", createdDate: Date(), isEnabled: true)
            WMFDonationReminderDataController.shared.saveReminder(existingReminder)

            let viewModel = makeViewModel(origin: .settings)

            #expect(viewModel.selectedTriggerOption?.trigger == .articlesRead(count: 20))
            #expect(viewModel.selectedPresetAmount == 5)
            #expect(viewModel.isReminderEnabled)
        }
    }

    @Test
    func settingsPrefillsCustomAmountWhenSavedAmountIsNotAPreset() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let existingReminder = WMFDonationReminder(trigger: .articlesRead(count: 5), amount: Decimal(string: "7.50") ?? 0, currencyCode: "EUR", createdDate: Date(), isEnabled: true)
            WMFDonationReminderDataController.shared.saveReminder(existingReminder)

            let viewModel = makeViewModel(origin: .settings)

            #expect(viewModel.selectedPresetAmount == nil)
            #expect(viewModel.customAmount == Decimal(string: "7.50"))
        }
    }

    @Test
    func settingsStartsDisabledWithoutSavedReminder() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(origin: .settings)

            #expect(viewModel.isReminderEnabled == false)
        }
    }

    @Test
    func bannerStartsEnabled() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(origin: .banner)

            #expect(viewModel.isReminderEnabled)
        }
    }

    @Test
    func bannerConfirmStoresExperimentEndDate() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let endDate = Date(timeIntervalSince1970: 2_000_000_000)
            let viewModel = makeViewModel(origin: .banner, experimentEndDate: endDate)

            viewModel.confirm()

            #expect(WMFDonationReminderDataController.shared.loadReminder()?.experimentEndDate == endDate)
        }
    }

    @Test
    func settingsConfirmPreservesCreatedDateAndEndDate() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let createdDate = Date(timeIntervalSince1970: 1_700_000_000)
            let endDate = Date(timeIntervalSince1970: 2_000_000_000)
            let existingReminder = WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: createdDate, isEnabled: true, experimentEndDate: endDate)
            WMFDonationReminderDataController.shared.saveReminder(existingReminder)

            let testStartDate = Date()
            let viewModel = makeViewModel(origin: .settings)
            viewModel.selectedTriggerOptionIdentifier = "articles-10"
            viewModel.confirm()

            let savedReminder = WMFDonationReminderDataController.shared.loadReminder()
            #expect(savedReminder?.trigger == .articlesRead(count: 10))
            #expect(savedReminder?.createdDate == createdDate)
            #expect(savedReminder?.experimentEndDate == endDate)
            let cycleStartDate = savedReminder?.currentCycleStartDate ?? .distantPast
            #expect(cycleStartDate >= testStartDate)
            #expect(savedReminder?.timesReminderShown == 0)
        }
    }

    @Test
    func settingsUpdateButtonEnablesOnlyWithChanges() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let existingReminder = WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(), isEnabled: true)
            WMFDonationReminderDataController.shared.saveReminder(existingReminder)

            let viewModel = makeViewModel(origin: .settings)
            #expect(viewModel.isConfirmButtonEnabled == false)

            viewModel.selectedTriggerOptionIdentifier = "articles-10"
            #expect(viewModel.isConfirmButtonEnabled)

            viewModel.selectedTriggerOptionIdentifier = "articles-5"
            #expect(viewModel.isConfirmButtonEnabled == false)

            viewModel.selectPresetAmount(3)
            #expect(viewModel.isConfirmButtonEnabled)
        }
    }

    @Test
    func settingsReenablingDisabledReminderAllowsUpdate() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let existingReminder = WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(), isEnabled: false)
            WMFDonationReminderDataController.shared.saveReminder(existingReminder)

            let viewModel = makeViewModel(origin: .settings)
            #expect(viewModel.isReminderEnabled == false)

            viewModel.isReminderEnabled = true
            #expect(viewModel.isConfirmButtonEnabled)

            viewModel.confirm()
            #expect(WMFDonationReminderDataController.shared.loadReminder()?.isEnabled == true)
        }
    }

    @Test
    func settingsTogglingOffDiscardsUnconfirmedEdits() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let existingReminder = WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(), isEnabled: true)
            WMFDonationReminderDataController.shared.saveReminder(existingReminder)

            let viewModel = makeViewModel(origin: .settings)
            viewModel.selectPresetAmount(3)
            viewModel.selectedTriggerOptionIdentifier = "articles-20"

            viewModel.isReminderEnabled = false
            viewModel.isReminderEnabled = true

            #expect(viewModel.selectedPresetAmount == 1)
            #expect(viewModel.selectedTriggerOption?.trigger == .articlesRead(count: 5))
            #expect(viewModel.isConfirmButtonEnabled == false)
        }
    }

    @Test
    func settingsConfirmWithoutChangesDoesNotSave() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let existingReminder = WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(), isEnabled: true)
            WMFDonationReminderDataController.shared.saveReminder(existingReminder)

            let viewModel = makeViewModel(origin: .settings)
            viewModel.confirm()

            #expect(WMFDonationReminderDataController.shared.loadReminder() == existingReminder)
        }
    }

    @Test
    func primaryButtonTitleFollowsOrigin() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let bannerViewModel = makeViewModel(origin: .banner)
            let settingsViewModel = makeViewModel(origin: .settings)

            #expect(bannerViewModel.primaryButtonTitle == bannerViewModel.localizedStrings.confirmButtonTitle)
            #expect(settingsViewModel.primaryButtonTitle == settingsViewModel.localizedStrings.updateButtonTitle)
        }
    }

    @Test
    func declineSavesDisabledReminderWithEndDateAndNotifies() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let endDate = Date(timeIntervalSince1970: 2_000_000_000)
            let viewModel = makeViewModel(origin: .banner, experimentEndDate: endDate)
            var didNotify = false
            viewModel.didTapNoThanks = {
                didNotify = true
            }

            viewModel.declineReminder()

            let savedReminder = WMFDonationReminderDataController.shared.loadReminder()
            #expect(savedReminder?.isEnabled == false)
            #expect(savedReminder?.experimentEndDate == endDate)
            #expect(didNotify)
        }
    }
}
