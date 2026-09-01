import Foundation
import SwiftUI
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFDonationReminderSetupViewModel: ObservableObject {

    // MARK: - Nested Types

    public enum Origin {
        case banner
        case settings
    }

    private struct Selection {
        let triggerOptionIdentifier: String
        let presetAmount: Decimal?
        let customAmount: Decimal
    }

    public struct TriggerOption: Identifiable, Equatable {
        public let id: String
        public let label: String
        public let trigger: WMFDonationReminder.Trigger

        public init(id: String, label: String, trigger: WMFDonationReminder.Trigger) {
            self.id = id
            self.label = label
            self.trigger = trigger
        }
    }

    /// The screen's numeric knobs (trigger options, preset amounts, currency, defaults) live
    /// here as data so experiment changes only touch the factory method below.
    public struct Configuration {
        let triggerOptions: [TriggerOption]
        let presetAmounts: [Decimal]
        let currencyCode: String
        let minimumAmount: Decimal
        let maximumAmount: Decimal?
        let defaultTriggerOptionIdentifier: String
        let defaultAmount: Decimal
    }

    struct LocalizedStrings {
        let title = WMFLocalizedString("donation-reminder-setup-title", value: "How should we remind you?", comment: "Navigation title of the donation reminder setup screen.")
        let subtitle = WMFLocalizedString("donation-reminder-setup-subtitle-articles", value: "Your generosity helps keep Wikipedia thriving. Set up a donation reminder based on the number of articles you read.", comment: "Subtitle of the article-based donation reminder setup screen.")
        let triggerGroupTitle = WMFLocalizedString("donation-reminder-setup-trigger-group-title-articles", value: "Whenever I read", comment: "Title of the article count selection group on the reminder setup screen.")
        let triggerGroupDetail = WMFLocalizedString("donation-reminder-setup-trigger-group-detail-articles", value: "Article count is stored locally on your device.", comment: "Explanation shown when tapping the info button next to the article count selection group.")
        let triggerUnitLabel = WMFLocalizedString("donation-reminder-setup-trigger-unit-articles", value: "Articles", comment: "Unit label displayed next to the article count buttons on the reminder setup screen.")
        let confirmationToastFormat = WMFLocalizedString("donation-reminder-setup-toast-articles", value: "We’ll remind you to donate %1$@ after you’ve read %2$@ articles while this experiment runs.", comment: "Toast shown after confirming an article-based donation reminder. %1$@ is the donation amount, %2$@ is the number of articles.")
        let infoText = WMFLocalizedString("donation-reminder-setup-info", value: "Donations go to the Wikimedia Foundation and affiliates, proud hosts of Wikipedia and its sister sites.", comment: "Informational text on the donation reminder setup screen explaining where donations go.")
        let reminderToggleTitle = WMFLocalizedString("donation-reminder-setup-toggle-title", value: "Donation reminders", comment: "Title of the toggle that enables donation reminders on the reminder setup screen.")
        let amountGroupTitle = WMFLocalizedString("donation-reminder-setup-amount-group-title", value: "Remind me to donate", comment: "Title of the donation amount selection group on the reminder setup screen.")
        let confirmButtonTitle = WMFLocalizedString("donation-reminder-setup-confirm-button-title", value: "Confirm reminder", comment: "Title of the button that saves the configured donation reminder.")
        let updateButtonTitle = WMFLocalizedString("donation-reminder-setup-update-button-title", value: "Update reminder", comment: "Title of the button that saves changes to an existing donation reminder, on the setup screen opened from settings.")
        let noThanksButtonTitle = CommonStrings.noThanksTitle
        let learnMoreButtonTitle = CommonStrings.learnMoreTitle()
        let problemWithFeatureButtonTitle = CommonStrings.problemWithFeatureTitle
        let moreButtonAccessibilityLabel = CommonStrings.moreButton
        let keyboardDoneButtonTitle = CommonStrings.doneTitle
        let amountButtonAccessibilityHint = WMFLocalizedString("donation-reminder-setup-amount-accessibility-hint", value: "Double tap to select donation amount", comment: "Accessibility hint on the donation amount buttons of the reminder setup screen.")
        let customAmountAccessibilityHint = WMFLocalizedString("donation-reminder-setup-custom-amount-accessibility-hint", value: "Enter custom donation amount", comment: "Accessibility hint on the custom donation amount text field of the reminder setup screen.")
        let triggerDetailAccessibilityLabel = WMFLocalizedString("donation-reminder-setup-trigger-detail-accessibility-label", value: "More information", comment: "Accessibility label of the info button next to the reminder trigger group title on the reminder setup screen.")
        // Same keys and values as the donate form's errors, so existing translations apply.
        let minimumAmountErrorFormat = WMFLocalizedString("donate-minimum-error-text", value: "Please select an amount (minimum %1$@ %2$@).", comment: "Error text displayed when user enters donation amount below the allowed minimum. Parameters: * %1$@ - the minimum amount allowed, %2$@ - the currency code. (For example, '$1 USD')")
        let maximumAmountErrorFormat = WMFLocalizedString("donate-maximum-error-text", value: "We cannot accept donations greater than %1$@ %2$@ through our website. Please contact our major gifts staff at benefactors@wikimedia.org.", comment: "Error text displayed when user enters donation amount above the maximum. Parameters: * %1$@ - the currency code, %2$@ - the maximum donation amount allowed. (For example, 'USD $25,000')")
    }

    // MARK: - Properties

    let localizedStrings = LocalizedStrings()
    let configuration: Configuration
    let origin: Origin
    private let initialReminder: WMFDonationReminder?

    @Published var isReminderEnabled: Bool = true {
        didSet {
            guard oldValue != isReminderEnabled else { return }

            if var savedReminder = WMFDonationReminderDataController.shared.loadReminder() {
                savedReminder.isEnabled = isReminderEnabled
                WMFDonationReminderDataController.shared.saveReminder(savedReminder)
            }

            if isReminderEnabled {
                resetSelectionsToInitialReminder()
            }
        }
    }
    @Published var selectedTriggerOptionIdentifier: String
    @Published var selectedPresetAmount: Decimal?
    @Published var customAmount: Decimal = 0
    @Published var customAmountHasFocus: Bool = false
    @Published var isShowingTriggerGroupDetail: Bool = false

    public var logSetupFormDidAppear: (@MainActor @Sendable () -> Void)?
    public var logDidTapLearnMore: (@MainActor @Sendable () -> Void)?
    public var logDidTapReportProblem: (@MainActor @Sendable () -> Void)?

    public var didConfirmReminder: (@MainActor @Sendable (WMFDonationReminder) -> Void)?
    public var didTapAboutExperiment: (@MainActor @Sendable () -> Void)?
    public var didTapNoThanks: (@MainActor @Sendable () -> Void)?
    public var didTapReportProblem: (@MainActor @Sendable () -> Void)?

    // MARK: - Lifecycle

    public init(configuration: Configuration, origin: Origin) {
        self.configuration = configuration
        self.origin = origin

        let savedReminder = WMFDonationReminderDataController.shared.loadReminder()
        self.initialReminder = savedReminder

        switch origin {
        case .banner:
            self.selectedTriggerOptionIdentifier = configuration.defaultTriggerOptionIdentifier
            self.selectedPresetAmount = configuration.defaultAmount
        case .settings:
            let selection = Self.selection(for: savedReminder, configuration: configuration)
            self.selectedTriggerOptionIdentifier = selection.triggerOptionIdentifier
            self.selectedPresetAmount = selection.presetAmount
            self.customAmount = selection.customAmount

            self.isReminderEnabled = savedReminder?.isEnabled ?? false
        }
    }

    private static func selection(
        for reminder: WMFDonationReminder?,
        configuration: Configuration
    ) -> Selection {
        let triggerOptionIdentifier = configuration.triggerOptions.first { $0.trigger == reminder?.trigger }?.id
        ?? configuration.defaultTriggerOptionIdentifier

        guard let savedAmount = reminder?.amount else {
            return Selection(triggerOptionIdentifier: triggerOptionIdentifier, presetAmount: configuration.defaultAmount, customAmount: 0)
        }

        if configuration.presetAmounts.contains(savedAmount) {
            return Selection(triggerOptionIdentifier: triggerOptionIdentifier, presetAmount: savedAmount, customAmount: 0)
        }
        return Selection(triggerOptionIdentifier: triggerOptionIdentifier, presetAmount: nil, customAmount: savedAmount)
    }

    private func resetSelectionsToInitialReminder() {
        let selection = Self.selection(for: initialReminder, configuration: configuration)
        selectedTriggerOptionIdentifier = selection.triggerOptionIdentifier
        selectedPresetAmount = selection.presetAmount
        customAmount = selection.customAmount
        customAmountHasFocus = false
    }

    var primaryButtonTitle: String {
        initialReminder == nil ? localizedStrings.confirmButtonTitle : localizedStrings.updateButtonTitle
    }

    var hasPendingChanges: Bool {
        guard origin == .settings, let initialReminder else { return true }

        return selectedTriggerOption?.trigger != initialReminder.trigger || finalAmount != initialReminder.amount || isReminderEnabled != initialReminder.isEnabled
    }

    var isConfirmButtonEnabled: Bool {
        canConfirm && hasPendingChanges
    }

    // MARK: - Selection

    var selectedTriggerOption: TriggerOption? {
        configuration.triggerOptions.first { $0.id == selectedTriggerOptionIdentifier }
    }

    var finalAmount: Decimal {
        if customAmount > 0 { return customAmount }

        return selectedPresetAmount ?? 0
    }

    var canConfirm: Bool {
        guard selectedTriggerOption != nil else {
            return false
        }
        // Preset amounts are sanctioned by the experiment and always confirmable; the
        // currency limits only police the freeform custom amount.
        if let selectedPresetAmount {
            return selectedPresetAmount > 0
        }
        guard customAmount >= configuration.minimumAmount else {
            return false
        }
        if let maximumAmount = configuration.maximumAmount {
            return customAmount <= maximumAmount
        }
        return true
    }

    var customAmountErrorText: String? {
        guard customAmount > 0 else {
            return nil
        }

        let formatter = NumberFormatter.wmfCurrencyFormatter
        formatter.currencyCode = configuration.currencyCode

        if customAmount < configuration.minimumAmount {
            let minimumString = formatter.string(from: configuration.minimumAmount as NSNumber) ?? "\(configuration.minimumAmount)"
            return String.localizedStringWithFormat(localizedStrings.minimumAmountErrorFormat, minimumString, configuration.currencyCode)
        }

        if let maximumAmount = configuration.maximumAmount, customAmount > maximumAmount {
            let maximumString = formatter.string(from: maximumAmount as NSNumber) ?? "\(maximumAmount)"
            return String.localizedStringWithFormat(localizedStrings.maximumAmountErrorFormat, maximumString, configuration.currencyCode)
        }

        return nil
    }

    func selectPresetAmount(_ amount: Decimal) {
        selectedPresetAmount = amount
        customAmount = 0
        customAmountHasFocus = false
    }

    func customAmountDidChange() {
        if customAmount > 0 {
            selectedPresetAmount = nil
        }
    }

    // MARK: - Actions

    func confirm() {
        guard let selectedTriggerOption, isConfirmButtonEnabled, isReminderEnabled else { return }

        let createdDate: Date
        let progress: WMFDonationReminder.Progress?
        switch origin {
        case .banner:
            createdDate = Date()
            progress = nil
        case .settings:
            createdDate = WMFDonationReminderDataController.shared.loadReminder()?.createdDate ?? Date()
            progress = WMFDonationReminder.Progress(currentCycleStartDate: Date(), timesReminderShown: 0)
        }

        let reminder = WMFDonationReminder(
            trigger: selectedTriggerOption.trigger,
            amount: finalAmount,
            currencyCode: configuration.currencyCode,
            createdDate: createdDate,
            isEnabled: true,
            progress: progress
        )
        WMFDonationReminderDataController.shared.saveReminder(reminder)

        let formatter = NumberFormatter.wmfCurrencyFormatter
        formatter.currencyCode = configuration.currencyCode
        let formattedAmount = formatter.string(from: finalAmount as NSNumber) ?? "\(finalAmount)"
        let toastTitle = String.localizedStringWithFormat(localizedStrings.confirmationToastFormat, formattedAmount, selectedTriggerOption.label)
        WMFToastPresenter.shared.show(WMFToastConfig(title: toastTitle))

        didConfirmReminder?(reminder)
    }

    func declineReminder() {
        guard let trigger = (selectedTriggerOption ?? configuration.triggerOptions.first)?.trigger else { return }

        let optOutReminder = WMFDonationReminder(
            trigger: trigger,
            amount: finalAmount,
            currencyCode: configuration.currencyCode,
            createdDate: Date(),
            isEnabled: false
        )
        WMFDonationReminderDataController.shared.saveReminder(optOutReminder)

        didTapNoThanks?()
    }

    // MARK: - Experiment Configuration

    public static func experimentConfiguration(currencyCode: String, minimumAmount: Decimal = 1, maximumAmount: Decimal? = nil) -> Configuration {

        let triggerOptions = [
            TriggerOption(id: "articles-5", label: "5", trigger: .articlesRead(count: 5)),
            TriggerOption(id: "articles-10", label: "10", trigger: .articlesRead(count: 10)),
            TriggerOption(id: "articles-20", label: "20", trigger: .articlesRead(count: 20))
        ]

        return Configuration(
            triggerOptions: triggerOptions,
            presetAmounts: [1, 3, 5],
            currencyCode: currencyCode,
            minimumAmount: minimumAmount,
            maximumAmount: maximumAmount,
            defaultTriggerOptionIdentifier: "articles-5",
            defaultAmount: 1
        )
    }

}
