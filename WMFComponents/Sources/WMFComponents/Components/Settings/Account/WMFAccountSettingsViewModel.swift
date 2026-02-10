import SwiftUI
import WMFData

@MainActor
public final class WMFAccountSettingsViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let accountGroupTitle: String
        public let vanishAccountTitle: String
        public let autoSignDiscussionsTitle: String
        public let talkPagePreferencesTitle: String
        public let talkPagePreferencesFooter: String

        public init(title: String, accountGroupTitle: String, vanishAccountTitle: String, autoSignDiscussionsTitle: String, talkPagePreferencesTitle: String, talkPagePreferencesFooter: String) {
            self.title = title
            self.accountGroupTitle = accountGroupTitle
            self.vanishAccountTitle = vanishAccountTitle
            self.autoSignDiscussionsTitle = autoSignDiscussionsTitle
            self.talkPagePreferencesTitle = talkPagePreferencesTitle
            self.talkPagePreferencesFooter = talkPagePreferencesFooter
        }
    }

    @Published public private(set) var sections: [SettingsSection] = []
    @Published public var autoSignDiscussions: Bool = false
    @Published public var isLoading: Bool = true
    @Published public var username: String = ""

    public let localizedStrings: LocalizedStrings

    private let userDefaultsStore: WMFKeyValueStore?
    public var onVanishAccount: (() -> Void)?
    public var onToggleAutoSign: ((Bool) -> Void)?

    public init(localizedStrings: LocalizedStrings, username: String, autoSignDiscussions: Bool, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore, onVanishAccount: (() -> Void)? = nil, onToggleAutoSign: ((Bool) -> Void)? = nil) {
        self.localizedStrings = localizedStrings
        self.username = username
        self.autoSignDiscussions = autoSignDiscussions
        self.userDefaultsStore = userDefaultsStore
        self.onVanishAccount = onVanishAccount
        self.onToggleAutoSign = onToggleAutoSign

        Task { await loadAndBuild() }
    }

    public func loadAndBuild() async {
        isLoading = true
        defer { isLoading = false }

        buildSections()
    }

    private func buildSections() {
        sections = [
            SettingsSection(
                header: localizedStrings.accountGroupTitle,
                footer: nil,
                items: [
                    usernameItem(),
                    vanishAccountItem()
                ]
            ),
            SettingsSection(
                header: localizedStrings.talkPagePreferencesTitle,
                footer: localizedStrings.talkPagePreferencesFooter,
                items: [autoSignDiscussionsToggleItem()]
            )
        ]
    }

    private func usernameItem() -> SettingsItem {
        SettingsItem(
            image: WMFSFSymbolIcon.for(symbol: .personFill),
            color: WMFColor.orange600,
            title: username,
            subtitle: nil,
            accessory: .none,
            action: nil
        )
    }

    private func vanishAccountItem() -> SettingsItem {
        SettingsItem(
            image: WMFSFSymbolIcon.for(symbol: .personCropCircleBadgeMinus),
            color: WMFColor.red600,
            title: localizedStrings.vanishAccountTitle,
            subtitle: nil,
            accessory: .chevron(label: nil),
            action: { [weak self] in
                self?.onVanishAccount?()
            }
        )
    }

    private func autoSignDiscussionsToggleItem() -> SettingsItem {
        SettingsItem(
            image: nil,
            color: nil,
            title: localizedStrings.autoSignDiscussionsTitle,
            subtitle: nil,
            accessory: .toggle(autoSignDiscussionsBinding),
            action: nil
        )
    }

    private var autoSignDiscussionsBinding: Binding<Bool> {
        Binding(
            get: { self.autoSignDiscussions },
            set: { newValue in
                self.autoSignDiscussions = newValue
                self.onToggleAutoSign?(newValue)
            }
        )
    }
}
