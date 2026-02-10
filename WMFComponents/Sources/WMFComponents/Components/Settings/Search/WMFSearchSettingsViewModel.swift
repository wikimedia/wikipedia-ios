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

    private let userDefaults: UserDefaults

    public init(localizedStrings: LocalizedStrings, userDefaults: UserDefaults = .standard) {
        self.localizedStrings = localizedStrings
        self.userDefaults = userDefaults

        Task { await loadAndBuild() }
    }

    public func loadAndBuild() async {
        isLoading = true
        defer { isLoading = false }

        // Load current values from UserDefaults using the same keys as the old implementation
        // These are stored as plain Bool values, not JSON-encoded
        if let showLanguageBarValue = userDefaults.object(forKey: "ShowLanguageBar") as? NSNumber {
            showLanguageBar = showLanguageBarValue.boolValue
        } else {
            showLanguageBar = false
        }

        openAppOnSearchTab = userDefaults.bool(forKey: "WMFOpenAppOnSearchTab")

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
                Task { @MainActor in
                    await self.setShowLanguageBar(newValue)
                }
            }
        )
    }

    private var openOnSearchTabBinding: Binding<Bool> {
        Binding(
            get: { self.openAppOnSearchTab },
            set: { newValue in
                Task { @MainActor in
                    await self.setOpenAppOnSearchTab(newValue)
                }
            }
        )
    }

    public func setShowLanguageBar(_ newValue: Bool) async {
        showLanguageBar = newValue
        // Match the old implementation which stores as NSNumber
        userDefaults.set(NSNumber(value: newValue), forKey: "ShowLanguageBar")
    }

    public func setOpenAppOnSearchTab(_ newValue: Bool) async {
        openAppOnSearchTab = newValue
        userDefaults.set(newValue, forKey: "WMFOpenAppOnSearchTab")
    }
}
