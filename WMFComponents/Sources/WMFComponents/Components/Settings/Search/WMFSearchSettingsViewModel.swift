import SwiftUI
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFSearchSettingsViewModel: ObservableObject {

    public let title = CommonStrings.searchTitle
    let showLanguagesTitle = WMFLocalizedString("settings-language-bar", value: "Show languages on search", comment: "Title in Settings for toggling the display the language bar in the search view")
    let openOnSearchTabTitle = WMFLocalizedString("settings-search-open-app-on-search", value: "Open app on Search tab", comment: "Title for setting that allows users to open app on Search tab")
    let semanticSearchTitle = WMFLocalizedString("settings-search-semantic-search-title", value: "Search within articles", comment: "Title of the Search settings row that shows or hides the semantic search entry point on the search screen.")
    let semanticSearchSubtitle = WMFLocalizedString("settings-search-semantic-search-subtitle", value: "Jump straight into the relevant passage", comment: "Subtitle of the Search settings row that shows or hides the semantic search entry point on the search screen.")

    var footerText: String {
        WMFDeveloperSettingsDataController.shared.isCommunityFeedMode
            ? WMFLocalizedString("settings-search-footer-text-home", value: "Set the app to open to the Search tab instead of the Home tab", comment: "Footer text for section that allows users to customize certain Search settings, shown while the Home tab experiment is enabled")
            : WMFLocalizedString("settings-search-footer-text", value: "Set the app to open to the Search tab instead of the Explore tab", comment: "Footer text for section that allows users to customize certain Search settings")
    }

    @Published public private(set) var sections: [SettingsSection] = []
    @Published public var showLanguageBar: Bool = false
    @Published public var openAppOnSearchTab: Bool = false
    @Published public var showSemanticSearchEntryPoint: Bool = false
    @Published public var isLoading: Bool = true

    /// The semantic search row only exists for readers who can see the entry point.
    public let showsSemanticSearchItem: Bool

    private let userDefaultsStore: WMFKeyValueStore?
    public var onToggleShowLanguageBar: ((Bool) -> Void)?
    public var onToggleOpenAppOnSearchTab: ((Bool) -> Void)?
    public var onToggleShowSemanticSearchEntryPoint: ((Bool) -> Void)?

    public init(
        showLanguageBar: Bool,
        openAppOnSearchTab: Bool,
        showsSemanticSearchItem: Bool = false,
        showSemanticSearchEntryPoint: Bool = false,
        userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore,
        onToggleShowLanguageBar: ((Bool) -> Void)? = nil,
        onToggleOpenAppOnSearchTab: ((Bool) -> Void)? = nil,
        onToggleShowSemanticSearchEntryPoint: ((Bool) -> Void)? = nil
    ) {
        self.showLanguageBar = showLanguageBar
        self.openAppOnSearchTab = openAppOnSearchTab
        self.showsSemanticSearchItem = showsSemanticSearchItem
        self.showSemanticSearchEntryPoint = showSemanticSearchEntryPoint
        self.userDefaultsStore = userDefaultsStore
        self.onToggleShowLanguageBar = onToggleShowLanguageBar
        self.onToggleOpenAppOnSearchTab = onToggleOpenAppOnSearchTab
        self.onToggleShowSemanticSearchEntryPoint = onToggleShowSemanticSearchEntryPoint

        Task { await loadAndBuild() }
    }

    public func loadAndBuild() async {
        isLoading = true
        defer { isLoading = false }

        // Values are passed from coordinator after migration, no need to read here
        buildSections()
    }

    private func buildSections() {
        var items = [showLanguagesToggleItem()]
        if showsSemanticSearchItem {
            items.append(semanticSearchToggleItem())
        }
        items.append(openOnSearchTabToggleItem())

        sections = [
            SettingsSection(
                header: nil,
                footer: footerText,
                items: items
            )
        ]
    }

    private func showLanguagesToggleItem() -> SettingsItem {
        SettingsItem(
            image: nil,
            color: nil,
            title: showLanguagesTitle,
            subtitle: nil,
            accessory: .toggle(showLanguagesBinding),
            action: nil
        )
    }

    private func semanticSearchToggleItem() -> SettingsItem {
        SettingsItem(
            image: nil,
            color: nil,
            title: semanticSearchTitle,
            subtitle: semanticSearchSubtitle,
            showsBetaBadge: true,
            accessory: .toggle(semanticSearchBinding),
            action: nil
        )
    }

    private func openOnSearchTabToggleItem() -> SettingsItem {
        SettingsItem(
            image: nil,
            color: nil,
            title: openOnSearchTabTitle,
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

    private var semanticSearchBinding: Binding<Bool> {
        Binding(
            get: { self.showSemanticSearchEntryPoint },
            set: { newValue in
                self.showSemanticSearchEntryPoint = newValue
                self.onToggleShowSemanticSearchEntryPoint?(newValue)
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
