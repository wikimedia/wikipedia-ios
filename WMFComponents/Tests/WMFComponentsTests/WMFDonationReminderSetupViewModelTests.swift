import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
final class WMFDonationReminderSetupViewModelTests {

    private let fixture = WMFDataTestFixture()

    private func makeViewModel() -> WMFDonationReminderSetupViewModel {
        WMFDonationReminderSetupViewModel(configuration: WMFDonationReminderSetupViewModel.experimentConfiguration(currencyCode: "EUR"))
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
            let viewModel = WMFDonationReminderSetupViewModel(configuration: configuration)

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
    func togglingOffRecordsDisabledReminderImmediately() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel()

            viewModel.isReminderEnabled = false

            let savedReminder = WMFDonationReminderDataController.shared.loadReminder()
            #expect(savedReminder?.isEnabled == false)
        }
    }

    @Test
    func togglingBackOnClearsTheImmediateOptOut() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel()

            viewModel.isReminderEnabled = false
            viewModel.isReminderEnabled = true

            #expect(WMFDonationReminderDataController.shared.loadReminder() == nil)
        }
    }
}
