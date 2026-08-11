import SwiftUI
import WMFData

@MainActor
public final class WMFStorageAndSyncingSettingsViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let syncSavedArticlesTitle: String
        public let syncSavedArticlesFooter: String
        public let showSavedReadingListTitle: String
        public let showSavedReadingListFooter: String
        public let syncWithServerTitle: String
        public let syncWithServerFooter: String

        public init(title: String, syncSavedArticlesTitle: String, syncSavedArticlesFooter: String, showSavedReadingListTitle: String, showSavedReadingListFooter: String, syncWithServerTitle: String, syncWithServerFooter: String) {
            self.title = title
            self.syncSavedArticlesTitle = syncSavedArticlesTitle
            self.syncSavedArticlesFooter = syncSavedArticlesFooter
            self.showSavedReadingListTitle = showSavedReadingListTitle
            self.showSavedReadingListFooter = showSavedReadingListFooter
            self.syncWithServerTitle = syncWithServerTitle
            self.syncWithServerFooter = syncWithServerFooter
        }
    }

    @Published public private(set) var sections: [SettingsSection] = []
    @Published public var isSyncEnabled: Bool = false
    @Published public var showSavedReadingList: Bool = false
    @Published public var isLoading: Bool = true

    public let localizedStrings: LocalizedStrings

    public var onToggleSync: ((Bool) -> Void)?
    public var onToggleShowSavedList: ((Bool) -> Void)?
    public var onSyncWithServer: (() -> Void)?

    public init(localizedStrings: LocalizedStrings, onToggleSync: ((Bool) -> Void)? = nil, onToggleShowSavedList: ((Bool) -> Void)? = nil, onSyncWithServer: (() -> Void)? = nil) {
        self.localizedStrings = localizedStrings
        self.onToggleSync = onToggleSync
        self.onToggleShowSavedList = onToggleShowSavedList
        self.onSyncWithServer = onSyncWithServer

        Task { await loadAndBuild() }
    }

    public func loadAndBuild() async {
        isLoading = true
        defer { isLoading = false }

        buildSections()
    }

    public func updateSyncStatus(_ enabled: Bool) {
        isSyncEnabled = enabled
        buildSections()
    }

    public func updateShowSavedList(_ show: Bool) {
        showSavedReadingList = show
        buildSections()
    }

    private func buildSections() {
        sections = [
            SettingsSection(
                header: nil,
                footer: localizedStrings.syncSavedArticlesFooter,
                items: [syncSavedArticlesToggleItem()]
            ),
            SettingsSection(
                header: nil,
                footer: localizedStrings.showSavedReadingListFooter,
                items: [showSavedReadingListToggleItem()]
            ),
            SettingsSection(
                header: nil,
                footer: localizedStrings.syncWithServerFooter,
                items: [syncWithServerButtonItem()]
            )
        ]
    }

    private func syncSavedArticlesToggleItem() -> SettingsItem {
        SettingsItem(
            image: nil,
            color: nil,
            title: localizedStrings.syncSavedArticlesTitle,
            subtitle: nil,
            accessory: .toggle(syncSavedArticlesBinding),
            action: nil
        )
    }

    private func showSavedReadingListToggleItem() -> SettingsItem {
        SettingsItem(
            image: nil,
            color: nil,
            title: localizedStrings.showSavedReadingListTitle,
            subtitle: nil,
            accessory: .toggle(showSavedReadingListBinding),
            action: nil
        )
    }

    private func syncWithServerButtonItem() -> SettingsItem {
        SettingsItem(
            image: nil,
            color: nil,
            title: localizedStrings.syncWithServerTitle,
            subtitle: nil,
            accessory: .chevron(label: nil),
            action: { [weak self] in
                self?.onSyncWithServer?()
            }
        )
    }

    private var syncSavedArticlesBinding: Binding<Bool> {
        Binding(
            get: { self.isSyncEnabled },
            set: { newValue in
                self.onToggleSync?(newValue)
            }
        )
    }

    private var showSavedReadingListBinding: Binding<Bool> {
        Binding(
            get: { self.showSavedReadingList },
            set: { newValue in
                self.onToggleShowSavedList?(newValue)
            }
        )
    }
}
