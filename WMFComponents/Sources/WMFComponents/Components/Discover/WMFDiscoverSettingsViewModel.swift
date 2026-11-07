import SwiftUI
import WMFData
import WMFNativeLocalizations

/// The Discover settings screen: the switch, the list size, the cadence and the source.
@MainActor
public final class WMFDiscoverSettingsViewModel: ObservableObject {

    @Published public private(set) var settings: WMFDiscoverSettings
    /// The number of interests the reader picked. Nil until it is read.
    @Published public private(set) var interestCount: Int?
    @Published public var isShowingTurnOffAlert = false

    public var didTapSource: (() -> Void)?
    public var didTapInterests: (() -> Void)?
    public var didTurnOff: (() -> Void)?
    /// Called when the switch goes on with interests as the source and no interest picked. A list
    /// from no interests is empty, so the coordinator opens the interests screen at once.
    public var didTurnOnWithoutInterests: (() -> Void)?
    /// Called when the screen has gone away: Back, or Settings closing over it. The saves made
    /// here are stored by then, so the coordinator reads the settings the reader left.
    public var didLeave: (() -> Void)?

    private let dataController: WMFDiscoverReadingListDataController
    private let interestsDataController: WMFDiscoverInterestsDataController
    private(set) var saveTask: Task<Void, Never>?
    private(set) var refreshTask: Task<Void, Never>?

    public init(settings: WMFDiscoverSettings, interestCount: Int? = nil, dataController: WMFDiscoverReadingListDataController = .shared, interestsDataController: WMFDiscoverInterestsDataController = .shared) {
        self.settings = settings
        self.interestCount = interestCount
        self.dataController = dataController
        self.interestsDataController = interestsDataController
    }

    /// Reads the settings before the screen shows, so the screen never needs a loading state.
    public static func load(dataController: WMFDiscoverReadingListDataController = .shared, interestsDataController: WMFDiscoverInterestsDataController = .shared) async -> WMFDiscoverSettingsViewModel {
        let settings = await dataController.settings
        let interestCount = await Self.fetchInterestCount(interestsDataController: interestsDataController)
        return WMFDiscoverSettingsViewModel(settings: settings, interestCount: interestCount, dataController: dataController, interestsDataController: interestsDataController)
    }

    deinit {
        refreshTask?.cancel()
    }

    // MARK: - Refresh

    /// Reads the settings again. The source screen and the interests screen change them behind
    /// this screen. A save that starts during the read is awaited and the settings are read again,
    /// so the read never hides a change made on this screen.
    public func refresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            var awaitedSaveTask: Task<Void, Never>?
            var settings: WMFDiscoverSettings
            repeat {
                awaitedSaveTask = self.saveTask
                await awaitedSaveTask?.value
                settings = await self.dataController.settings
            } while awaitedSaveTask != self.saveTask
            let interestCount = await Self.fetchInterestCount(interestsDataController: self.interestsDataController)
            guard !Task.isCancelled else { return }
            self.settings = settings
            self.interestCount = interestCount
        }
    }

    private static func fetchInterestCount(interestsDataController: WMFDiscoverInterestsDataController) async -> Int {
        (try? await interestsDataController.fetchInterests().count) ?? 0
    }

    // MARK: - Switch

    public var isEnabledBinding: Binding<Bool> {
        Binding(
            get: { [weak self] in self?.settings.isEnabled ?? false },
            set: { [weak self] newValue in
                guard let self else { return }
                if newValue {
                    self.update { $0.isEnabled = true }
                    if self.settings.source == .interests, (self.interestCount ?? 0) == 0 {
                        self.didTurnOnWithoutInterests?()
                    }
                } else {
                    // The switch stays on until the reader confirms.
                    self.isShowingTurnOffAlert = true
                }
            }
        )
    }

    /// Turning off also throws the current list away, so the switch does not go through `update`.
    public func confirmTurnOff() {
        isShowingTurnOffAlert = false
        settings.isEnabled = false
        enqueue { dataController in
            try await dataController.turnOff()
        }
        didTurnOff?()
    }

    public func cancelTurnOff() {
        isShowingTurnOffAlert = false
    }

    /// Back on the interests screen that the switch opened. No interest was picked, so the switch
    /// goes back off, with no alert and no toast: no list was made in between.
    public func undoTurnOn() {
        update { $0.isEnabled = false }
    }

    // MARK: - List size

    public var articleCountText: String {
        NumberFormatter.localizedString(from: NSNumber(value: settings.articleCount), number: .decimal)
    }

    public var articleCountBinding: Binding<Int> {
        Binding(
            get: { [weak self] in self?.settings.articleCount ?? WMFDiscoverSettings.defaultArticleCount },
            set: { [weak self] newValue in self?.update { $0.articleCount = newValue } }
        )
    }

    // MARK: - Cadence

    public var cadenceBinding: Binding<WMFDiscoverCadence> {
        Binding(
            get: { [weak self] in self?.settings.cadence ?? WMFDiscoverSettings.default.cadence },
            set: { [weak self] newValue in self?.update { $0.cadence = newValue } }
        )
    }

    /// The value on the row is the same text as the menu option, so the two always agree.
    public var cadenceValue: String {
        Self.cadenceValue(for: settings.cadence)
    }

    static func cadenceValue(for cadence: WMFDiscoverCadence) -> String {
        switch cadence {
        case .daily:
            return cadenceDailyTitle
        case .weekly:
            return cadenceWeeklyTitle
        case .monthly:
            return cadenceMonthlyTitle
        }
    }

    // MARK: - Source

    public var sourceSubtitle: String {
        Self.sourceSubtitle(for: settings.source)
    }

    static func sourceSubtitle(for source: WMFDiscoverSource) -> String {
        switch source {
        case .interests:
            return sourceInterestsSubtitle
        case .saved:
            return sourceSavedSubtitle
        case .history:
            return sourceHistorySubtitle
        }
    }

    public var showsInterestsRow: Bool {
        settings.isEnabled && settings.source == .interests
    }

    public var interestCountText: String? {
        guard let interestCount, interestCount > 0 else { return nil }
        return NumberFormatter.localizedString(from: NSNumber(value: interestCount), number: .decimal)
    }

    func tapSource() {
        didTapSource?()
    }

    func tapInterests() {
        didTapInterests?()
    }

    // MARK: - Texts

    public var footerText: String {
        settings.isEnabled ? Self.footerOnText : Self.footerOffText
    }

    public var turnOffAlertMessage: String {
        switch settings.cadence {
        case .daily:
            return Self.turnOffAlertMessageDaily
        case .weekly:
            return Self.turnOffAlertMessageWeekly
        case .monthly:
            return Self.turnOffAlertMessageMonthly
        }
    }

    // MARK: - Leaving

    /// Waits for the saves in flight, then calls `didLeave`. The task holds this view model, so
    /// the call arrives after the screen is gone.
    public func leave() {
        Task {
            await saveTask?.value
            didLeave?()
        }
    }

    // MARK: - Saving

    private func update(_ change: (inout WMFDiscoverSettings) -> Void) {
        var newSettings = settings
        change(&newSettings)
        guard newSettings != settings else { return }
        settings = newSettings
        save(newSettings)
    }

    private func save(_ newSettings: WMFDiscoverSettings) {
        enqueue { dataController in
            try await dataController.saveSettings(newSettings)
        }
    }

    /// The saves run one after the other, so fast taps on the stepper reach the store in order.
    private func enqueue(_ operation: @escaping @Sendable (WMFDiscoverReadingListDataController) async throws -> Void) {
        let previousSaveTask = saveTask
        saveTask = Task { [dataController] in
            await previousSaveTask?.value
            try? await operation(dataController)
        }
    }

    // MARK: - Strings

    public static let discoverReadingListTitle = WMFLocalizedString("discover-settings-reading-list-title", value: "Discover reading list", comment: "Title of the Discover row on the Settings screen and of the switch on the Discover settings screen.")
    static let footerOnText = WMFLocalizedString("discover-settings-footer-on", value: "Discover is on. Wikipedia will recommend articles for you to read.", comment: "Text under the switch on the Discover settings screen when Discover is on.")
    static let footerOffText = WMFLocalizedString("discover-settings-footer-off", value: "Discover is off. Wikipedia won't recommend articles for you to read.", comment: "Text under the switch on the Discover settings screen when Discover is off.")
    static let yourListHeader = WMFLocalizedString("discover-settings-your-list-header", value: "Your list", comment: "Header of the section with the list options on the Discover settings screen.")
    static let articleCountTitle = WMFLocalizedString("discover-settings-article-count-title", value: "Articles per update", comment: "Title of the row with the number of articles in each Discover reading list, on the Discover settings screen.")
    static let cadenceTitle = WMFLocalizedString("discover-settings-cadence-title", value: "Updates", comment: "Title of the row that sets how often the Discover reading list updates, on the Discover settings screen.")
    static let cadenceDailyTitle = WMFLocalizedString("discover-settings-cadence-daily", value: "Every day", comment: "Option of the Updates menu on the Discover settings screen, and the value of the Updates row, when the Discover reading list updates every day.")
    static let cadenceWeeklyTitle = WMFLocalizedString("discover-settings-cadence-weekly", value: "Every week", comment: "Option of the Updates menu on the Discover settings screen, and the value of the Updates row, when the Discover reading list updates every week.")
    static let cadenceMonthlyTitle = WMFLocalizedString("discover-settings-cadence-monthly", value: "Every month", comment: "Option of the Updates menu on the Discover settings screen, and the value of the Updates row, when the Discover reading list updates every month.")
    public static let sourceTitle = WMFLocalizedString("discover-settings-source-title", value: "How Discover is built", comment: "Title of the row that opens the Discover source screen, on the Discover settings screen. Also the title of that screen.")
    static let sourceInterestsSubtitle = WMFLocalizedString("discover-settings-source-interests", value: "Based on your interests", comment: "Subtitle of the source row on the Discover settings screen when the Discover reading list is built from the reader's interests.")
    static let sourceSavedSubtitle = WMFLocalizedString("discover-settings-source-saved", value: "Based on your saved articles", comment: "Subtitle of the source row on the Discover settings screen when the Discover reading list is built from the reader's saved articles.")
    static let sourceHistorySubtitle = WMFLocalizedString("discover-settings-source-history", value: "Based on your reading history", comment: "Subtitle of the source row on the Discover settings screen when the Discover reading list is built from the reader's reading history.")
    static let interestsTitle = WMFLocalizedString("discover-settings-interests-title", value: "Interests", comment: "Title of the row that opens the interests screen, on the Discover settings screen.")
    static let turnOffAlertTitle = WMFLocalizedString("discover-settings-turn-off-alert-title", value: "Turn off Discover?", comment: "Title of the alert that asks the reader to confirm that they want to turn off Discover.")
    static let turnOffAlertMessageDaily = WMFLocalizedString("discover-settings-turn-off-alert-message-daily", value: "If you turn off Discover, you'll stop receiving daily reading recommendations from Wikipedia.", comment: "Message of the alert that asks the reader to confirm that they want to turn off Discover, when the Discover reading list updates every day.")
    static let turnOffAlertMessageWeekly = WMFLocalizedString("discover-settings-turn-off-alert-message-weekly", value: "If you turn off Discover, you'll stop receiving weekly reading recommendations from Wikipedia.", comment: "Message of the alert that asks the reader to confirm that they want to turn off Discover, when the Discover reading list updates every week.")
    static let turnOffAlertMessageMonthly = WMFLocalizedString("discover-settings-turn-off-alert-message-monthly", value: "If you turn off Discover, you'll stop receiving monthly reading recommendations from Wikipedia.", comment: "Message of the alert that asks the reader to confirm that they want to turn off Discover, when the Discover reading list updates every month.")
    static let turnOffAlertConfirmTitle = WMFLocalizedString("discover-settings-turn-off-alert-confirm", value: "Turn off", comment: "Button of the alert that turns off Discover.")
    public static let turnedOffToastTitle = WMFLocalizedString("discover-settings-turned-off-toast", value: "Discover has been turned off. You can turn it back on anytime in Settings.", comment: "Toast shown after the reader turns off Discover.")
}
