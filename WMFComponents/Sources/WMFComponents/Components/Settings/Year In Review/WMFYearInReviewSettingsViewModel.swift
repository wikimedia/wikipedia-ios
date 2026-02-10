import SwiftUI
import WMFData

@MainActor
public final class WMFYearInReviewSettingsViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let description: String
        public let toggleTitle: String

        public init(title: String, description: String, toggleTitle: String) {
            self.title = title
            self.description = description
            self.toggleTitle = toggleTitle
        }
    }

    @Published public private(set) var sections: [SettingsSection] = []
    @Published public var isEnabled: Bool = false
    @Published public var isLoading: Bool = true

    public let localizedStrings: LocalizedStrings

    private let dataController: WMFSettingsDataController
    public var onToggle: ((Bool) -> Void)?

    public init(dataController: WMFSettingsDataController, localizedStrings: LocalizedStrings, onToggle: ((Bool) -> Void)? = nil) {
        self.dataController = dataController
        self.localizedStrings = localizedStrings
        self.onToggle = onToggle

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
            get: { self.isEnabled },
            set: { newValue in
                self.onToggle?(newValue)

                Task { @MainActor in
                    await self.setEnabled(newValue)
                }
            }
        )
    }

    public func setEnabled(_ newValue: Bool) async {
        let old = isEnabled
        isEnabled = newValue
        let result = await dataController.setYirActive(newValue)

        if result != newValue {
            // Revert on failure
            isEnabled = old
        }
    }
}
