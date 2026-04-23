import SwiftUI
import WMFData

@MainActor
public final class WMFSearchSettingsViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let showLanguagesTitle: String
        public let openOnSearchTabTitle: String
        public let footerText: String

        public init(title: String, showLanguagesTitle: String, openOnSearchTabTitle: String, footerText: String) {
            self.title = title
            self.showLanguagesTitle = showLanguagesTitle
            self.openOnSearchTabTitle = openOnSearchTabTitle
            self.footerText = footerText
        }
    }

    @Published public private(set) var sections: [SettingsSection] = []
    @Published public var showLanguageBar: Bool = false
    @Published public var openAppOnSearchTab: Bool = false
    @Published public var isLoading: Bool = true

    public let localizedStrings: LocalizedStrings

    private let userDefaultsStore: WMFKeyValueStore?
    public var onToggleShowLanguageBar: ((Bool) -> Void)?
    public var onToggleOpenAppOnSearchTab: ((Bool) -> Void)?

    public init(localizedStrings: LocalizedStrings, showLanguageBar: Bool, openAppOnSearchTab: Bool, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore, onToggleShowLanguageBar: ((Bool) -> Void)? = nil, onToggleOpenAppOnSearchTab: ((Bool) -> Void)? = nil) {
        self.localizedStrings = localizedStrings
        self.showLanguageBar = showLanguageBar
        self.openAppOnSearchTab = openAppOnSearchTab
        self.userDefaultsStore = userDefaultsStore
        self.onToggleShowLanguageBar = onToggleShowLanguageBar
        self.onToggleOpenAppOnSearchTab = onToggleOpenAppOnSearchTab

        Task { await loadAndBuild() }
    }

    public func loadAndBuild() async {
        isLoading = true
        defer { isLoading = false }

        // Values are passed from coordinator after migration, no need to read here
        buildSections()
    }

    private func buildSections() {
        sections = [
            SettingsSection(
                header: nil,
                footer: localizedStrings.footerText,
                items: [
                    showLanguagesToggleItem(),
                    openOnSearchTabToggleItem()
                ]
            )
        ]
    }

    private func showLanguagesToggleItem() -> SettingsItem {
        SettingsItem(
            image: nil,
            color: nil,
            title: localizedStrings.showLanguagesTitle,
            subtitle: nil,
            accessory: .toggle(showLanguagesBinding),
            action: nil
        )
    }

    private func openOnSearchTabToggleItem() -> SettingsItem {
        SettingsItem(
            image: nil,
            color: nil,
            title: localizedStrings.openOnSearchTabTitle,
            subtitle: nil,
            accessory: .toggle(openOnSearchTabBinding),
            action: nil
        )
    }

    private var showLanguagesBinding: Binding<Bool> {
        Binding(
            get: { self.showLanguageBar },
            set: { newValue in
                self.showLanguageBar = newValue
                self.onToggleShowLanguageBar?(newValue)
            }
        )
    }

    private var openOnSearchTabBinding: Binding<Bool> {
        Binding(
            get: { self.openAppOnSearchTab },
            set: { newValue in
                self.openAppOnSearchTab = newValue
                self.onToggleOpenAppOnSearchTab?(newValue)
            }
        )
    }
}
