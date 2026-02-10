import SwiftUI
import WMFData

// MARK: - Types

public enum AccessoryType {
    case none
    case toggle(Binding<Bool>)
    case icon(UIImage?)
    case chevron(label: String?)
}

public struct SettingsItem: Identifiable {
    public let id = UUID()
    let image: UIImage?
    let color: UIColor?
    let title: String
    let subtitle: String?
    let accessory: AccessoryType
    let action: (() -> Void)?

    public init(image: UIImage?, color: UIColor?, title: String, subtitle: String?, accessory: AccessoryType, action: (() -> Void)?) {
        self.image = image
        self.color = color
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
        self.action = action
    }
}

public struct SettingsSection: Identifiable {
    public let id = UUID()
    let header: String?
    let footer: String?
    var items: [SettingsItem]

    public init(header: String?, footer: String?, items: [SettingsItem]) {
        self.header = header
        self.footer = footer
        self.items = items
    }
}

@MainActor
final public class WMFSettingsViewModel: ObservableObject {

    // MARK: - Nested Types

    public struct LocalizedStrings {
        let settingTitle: String
        let doneButtonTitle: String
        let cancelButtonTitle: String
        let accountTitle: String
        let logInTitle: String
        let myLanguagesTitle: String
        let searchTitle: String
        let exploreFeedTitle: String
        let onTitle: String
        let offTitle: String
        let yirTitle: String
        let pushNotificationsTitle: String
        let readingpreferences: String
        let articleSyncing: String
        let databasePopulation: String
        let clearCacheTitle: String
        let privacyHeader: String
        let privacyPolicyTitle: String
        let termsOfUseTitle: String
        let rateTheAppTitle: String
        let helpTitle: String
        let aboutTitle: String
        let clearDonationHistoryTitle: String

        public init(settingTitle: String, doneButtonTitle: String, cancelButtonTitle: String, accountTitle: String, logInTitle: String, myLanguagesTitle: String, searchTitle: String, exploreFeedTitle: String, onTitle: String, offTitle: String, yirTitle: String, pushNotificationsTitle: String, readingpreferences: String, articleSyncing: String, databasePopulation: String, clearCacheTitle: String, privacyHeader: String, privacyPolicyTitle: String, termsOfUseTitle: String, rateTheAppTitle: String, helpTitle: String, aboutTitle: String, clearDonationHistoryTitle: String) {
            self.settingTitle = settingTitle
            self.doneButtonTitle = doneButtonTitle
            self.cancelButtonTitle = cancelButtonTitle
            self.accountTitle = accountTitle
            self.logInTitle = logInTitle
            self.myLanguagesTitle = myLanguagesTitle
            self.searchTitle = searchTitle
            self.exploreFeedTitle = exploreFeedTitle
            self.onTitle = onTitle
            self.offTitle = offTitle
            self.yirTitle = yirTitle
            self.pushNotificationsTitle = pushNotificationsTitle
            self.readingpreferences = readingpreferences
            self.articleSyncing = articleSyncing
            self.databasePopulation = databasePopulation
            self.clearCacheTitle = clearCacheTitle
            self.privacyHeader = privacyHeader
            self.privacyPolicyTitle = privacyPolicyTitle
            self.termsOfUseTitle = termsOfUseTitle
            self.rateTheAppTitle = rateTheAppTitle
            self.helpTitle = helpTitle
            self.aboutTitle = aboutTitle
            self.clearDonationHistoryTitle = clearDonationHistoryTitle
        }
    }

    // MARK: - Properties

    @Published private(set) var sections: [SettingsSection] = []

    let URLTerms = "https://foundation.wikimedia.org/wiki/Terms_of_Use/en"
   
    let URLDonation = "https://donate.wikimedia.org/?utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=appmenu&app_version=<app-version>&uselang=<langcode>"

    let localizedStrings: LocalizedStrings
    private let username: String?
    private let tempUsername: String?
    private let isTempAccount: Bool
    private let mainLanguage: String
    private let exploreFeedStatus: Bool
    private let readingPreferenceTheme: String
    public weak var coordinatorDelegate: SettingsCoordinatorDelegate?
    private let dataController: WMFSettingsDataController

    // MARK: - Lifecycle

    public init(localizedStrings: LocalizedStrings, username: String?, tempUsername: String?, isTempAccount: Bool, primaryLanguage: String, exploreFeedStatus: Bool, readingPreferenceTheme: String, coordinatorDelegate: SettingsCoordinatorDelegate? = nil, dataController: WMFSettingsDataController) async {
        self.localizedStrings = localizedStrings
        self.username = username
        self.tempUsername = tempUsername
        self.isTempAccount = isTempAccount
        self.mainLanguage = primaryLanguage
        self.exploreFeedStatus = exploreFeedStatus
        self.readingPreferenceTheme = readingPreferenceTheme
        self.coordinatorDelegate = coordinatorDelegate
        self.dataController = dataController
        await buildSections()
    }

    // MARK: - Private methods

    private func buildSections() async {
        sections = await [getAccountSection(), getMainSection(), getTermsSection(), getHelpSection()]
    }
    
    public func refreshSections() async {
        await buildSections()
    }

    private func getMainSection() async -> SettingsSection {
        let myLanguages = SettingsItem(image: WMFIcon.settingsLanguage, color: WMFColor.blue300, title: localizedStrings.myLanguagesTitle, subtitle: nil, accessory: .chevron(label: mainLanguage), action: {
            self.coordinatorDelegate?.handleSettingsAction(.myLanguages)
        })

        let search = SettingsItem(image: WMFSFSymbolIcon.for(symbol: .magnifyingGlass), color: WMFColor.green600, title: localizedStrings.searchTitle, subtitle: nil, accessory: .chevron(label: nil), action: {
            self.coordinatorDelegate?.handleSettingsAction(.search)
        })

        let exploreFeed = SettingsItem(image: WMFIcon.settingsExplore, color: WMFColor.blue300, title: localizedStrings.exploreFeedTitle, subtitle: nil, accessory: .chevron(label: exploreFeedStatus ? localizedStrings.onTitle : localizedStrings.offTitle), action: {
            self.coordinatorDelegate?.handleSettingsAction(.exploreFeed)
        })
       
        let label = await dataController.yirIsActive() == true ? localizedStrings.onTitle : localizedStrings.offTitle

        let yearInReview = SettingsItem(image: WMFSFSymbolIcon.for(symbol: .calendar), color: WMFColor.blue700, title: localizedStrings.yirTitle, subtitle: nil, accessory: .chevron(label: label), action: {
            self.coordinatorDelegate?.handleSettingsAction(.yearInReview)
        })

        let pushNotifications = SettingsItem(image: WMFSFSymbolIcon.for(symbol: .appBadge), color: WMFColor.red600, title: localizedStrings.pushNotificationsTitle, subtitle: nil, accessory: .chevron(label: nil)) {
            self.coordinatorDelegate?.handleSettingsAction(.notifications)
        }

        let readingPrefs = SettingsItem(image: WMFIcon.settingsPreferences, color: WMFColor.black, title: localizedStrings.readingpreferences, subtitle: nil, accessory: .chevron(label: readingPreferenceTheme), action: {
            self.coordinatorDelegate?.handleSettingsAction(.readingPreferences)
        })

        let articleStorage = SettingsItem(image: WMFSFSymbolIcon.for(symbol: .bookmarkFill), color: WMFColor.blue600, title: localizedStrings.articleSyncing, subtitle: nil, accessory: .chevron(label: nil), action: {
            self.coordinatorDelegate?.handleSettingsAction(.articleSyncing)
        })

        let dangerZone = SettingsItem(image: WMFSFSymbolIcon.for(symbol: .handRaisedFill), color: WMFColor.blue700, title: localizedStrings.databasePopulation, subtitle: nil, accessory: .chevron(label: nil), action: {
            self.coordinatorDelegate?.handleSettingsAction(.databasePopulation)
        })

        let clearCache = SettingsItem(image: WMFIcon.settingsClearCache, color: WMFColor.yellow600, title: localizedStrings.clearCacheTitle, subtitle: nil, accessory: .none, action: {
            self.coordinatorDelegate?.handleSettingsAction(.clearCachedData)
        })

        var section = SettingsSection(header: nil, footer: nil, items: [myLanguages, search, exploreFeed, pushNotifications, readingPrefs, articleStorage, clearCache])

        if await dataController.shouldShowYiRSettingsItem() {
            section.items.insert(yearInReview, at: 3)
        }
#if DEBUG
        section.items.insert(dangerZone, at: 7)
#endif
        return section
    }

    private func getTermsSection() async -> SettingsSection {
        let privacy = SettingsItem(image: WMFIcon.settingsPrivacy, color: WMFColor.purple600, title: localizedStrings.privacyPolicyTitle, subtitle: nil, accessory: .icon( WMFIcon.externalLink), action: {
            self.coordinatorDelegate?.handleSettingsAction(.privacyPolicy)
        })
        let terms = SettingsItem(image: WMFSFSymbolIcon.for(symbol: .textJustify), color: WMFColor.gray300, title: localizedStrings.termsOfUseTitle, subtitle: nil, accessory: .icon(WMFIcon.externalLink), action: {
            self.coordinatorDelegate?.handleSettingsAction(.termsOfUse)
        })

        let deleteLocalDonations = SettingsItem(image: WMFSFSymbolIcon.for(symbol: .heartFilled), color: WMFColor.gray300, title: localizedStrings.clearDonationHistoryTitle, subtitle: nil, accessory: .none, action: {
            self.coordinatorDelegate?.handleSettingsAction(.deleteDonationHistory)
        })

        var section = SettingsSection(header: localizedStrings.privacyHeader, footer: nil, items:[privacy, terms])
        if await dataController.hasLocalDonations() {
            section.items.append(deleteLocalDonations)
        }
        return section
    }

    func getHelpSection() -> SettingsSection {
        let rateTheApp = SettingsItem(image: WMFSFSymbolIcon.for(symbol: .starFill), color: WMFColor.orange600, title: localizedStrings.rateTheAppTitle, subtitle: nil, accessory: .icon(WMFIcon.externalLink), action: {
            self.coordinatorDelegate?.handleSettingsAction(.rateTheApp)
        })

        let help = SettingsItem(image: WMFSFSymbolIcon.for(symbol: .lifePreserver), color: WMFColor.red600, title: localizedStrings.helpTitle, subtitle: nil, accessory: .chevron(label: nil), action: {
            self.coordinatorDelegate?.handleSettingsAction(.helpAndFeedback)
        })

        let about = SettingsItem(image: WMFIcon.wikipediaW, color: WMFColor.black, title: localizedStrings.aboutTitle, subtitle: nil, accessory: .chevron(label: nil), action: {
            self.coordinatorDelegate?.handleSettingsAction(.about)
        })

        return SettingsSection(header: nil, footer: nil, items: [rateTheApp, help, about])
    }

    private func getAccountSection() -> SettingsSection {
        let item: SettingsItem
        if let username {
            item = SettingsItem(
                image: WMFSFSymbolIcon.for(symbol: .personFilled),
                color: WMFColor.orange600,
                title: localizedStrings.accountTitle,
                subtitle: nil,
                accessory: .chevron(label: username),
                action: {
                    self.coordinatorDelegate?.handleSettingsAction(.account)
                }
            )

        } else if isTempAccount, let tempUsername {
            item = SettingsItem(
                image: WMFIcon.temp,
                color: WMFColor.orange600,
                title: localizedStrings.accountTitle,
                subtitle: nil,
                accessory: .chevron(label: tempUsername),
                action: {
                    self.coordinatorDelegate?.handleSettingsAction(.tempAccount)
                }
            )

        } else {
            item = SettingsItem(
                image: WMFSFSymbolIcon.for(symbol: .personFilled),
                color: WMFColor.gray100,
                title: localizedStrings.accountTitle,
                subtitle: nil,
                accessory: .chevron(label: nil),
                action: {
                    self.coordinatorDelegate?.handleSettingsAction(.logIn)
                }
            )

        }
        return SettingsSection(header: nil, footer: nil, items: [item])
    }

}
