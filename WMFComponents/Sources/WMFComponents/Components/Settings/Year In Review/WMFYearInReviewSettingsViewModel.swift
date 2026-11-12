import SwiftUI
import WMFData

@MainActor
public final class WMFYearInReviewSettingsViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let description: String
        public let toggleTitle: String
        public let turnOffAlertTitle: String
        public let turnOffAlertMessage: String
        public let turnOffAlertConfirmTitle: String
        public let turnOffAlertCancelTitle: String

        public init(title: String, description: String, toggleTitle: String, turnOffAlertTitle: String, turnOffAlertMessage: String, turnOffAlertConfirmTitle: String, turnOffAlertCancelTitle: String) {
            self.title = title
            self.description = description
            self.toggleTitle = toggleTitle
            self.turnOffAlertTitle = turnOffAlertTitle
            self.turnOffAlertMessage = turnOffAlertMessage
            self.turnOffAlertConfirmTitle = turnOffAlertConfirmTitle
            self.turnOffAlertCancelTitle = turnOffAlertCancelTitle
        }
    }

    public enum Action: Sendable {
        case switchOn
        case switchOff
        case switchOffConfirm
        case switchOffCancel
    }

    @Published public private(set) var sections: [SettingsSection] = []
    /// The rows are rebuilt on each change. SwiftUI does not read the switch binding again on its own,
    /// so without this the switch does not show the saved value.
    @Published public var isEnabled: Bool = false {
        didSet {
            guard isEnabled != oldValue, !sections.isEmpty else { return }
            buildSections()
        }
    }
    @Published public var isLoading: Bool = true
    @Published public var isShowingTurnOffAlert: Bool = false

    public let localizedStrings: LocalizedStrings

    private let dataController: WMFSettingsDataController
    public var onAction: (@MainActor @Sendable (Action) -> Void)?
    /// Called after the new value is saved.
    public var onEnabledChange: (@MainActor @Sendable (Bool) -> Void)?

    public init(dataController: WMFSettingsDataController, localizedStrings: LocalizedStrings, onAction: (@MainActor @Sendable (Action) -> Void)? = nil, onEnabledChange: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        self.dataController = dataController
        self.localizedStrings = localizedStrings
        self.onAction = onAction
        self.onEnabledChange = onEnabledChange

        Task { await loadAndBuild() }
    }

    public func loadAndBuild() async {
        isLoading = true
        defer { isLoading = false }

        isEnabled = await dataController.yirIsActive() == true

        buildSections()
    }

    private func buildSections() {
        sections = [
            SettingsSection(
                header: localizedStrings.description,
                footer: nil,
                items: [yearInReviewToggleItem()]
            )
        ]
    }

    private func yearInReviewToggleItem() -> SettingsItem {
        SettingsItem(
            image: WMFSFSymbolIcon.for(symbol: .calendar),
            color: WMFColor.blue700,
            title: localizedStrings.toggleTitle,
            subtitle: nil,
            accessory: .toggle(toggleBinding),
            action: nil
        )
    }

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { [weak self] in self?.isEnabled ?? false },
            set: { [weak self] newValue in
                guard let self else { return }
                if newValue {
                    onAction?(.switchOn)
                    Task { @MainActor [weak self] in
                        await self?.setEnabled(true)
                    }
                } else {
                    // The switch stays on until the reader confirms, because turning it off deletes the insights.
                    onAction?(.switchOff)
                    buildSections()
                    isShowingTurnOffAlert = true
                }
            }
        )
    }

    public func confirmTurnOff() {
        onAction?(.switchOffConfirm)
        Task { @MainActor [weak self] in
            await self?.setEnabled(false)
        }
    }

    public func cancelTurnOff() {
        onAction?(.switchOffCancel)
    }

    public func setEnabled(_ newValue: Bool) async {
        let old = isEnabled
        isEnabled = newValue
        let result = await dataController.setYirActive(newValue)

        if result != newValue {
            // Revert on failure
            isEnabled = old
        } else {
            onEnabledChange?(newValue)
        }
    }
}
