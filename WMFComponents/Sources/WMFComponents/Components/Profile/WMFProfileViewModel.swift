import Foundation
import SwiftUI
import WMFData

public class WMFProfileViewModel: ObservableObject {
    weak var badgeDelegate: YearInReviewBadgeDelegate?
    
    public struct YearInReviewDependencies {
        let dataController: WMFYearInReviewDataController
        let countryCode: String
        let primaryAppLanguageProject: WMFProject
        
        public init(dataController: WMFYearInReviewDataController, countryCode: String, primaryAppLanguageProject: WMFProject) {
            self.dataController = dataController
            self.countryCode = countryCode
            self.primaryAppLanguageProject = primaryAppLanguageProject
        }
    }
    
    @Published var profileSections: [ProfileSection] = []
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    let isLoggedIn: Bool
    let isTemporaryAccount: Bool
    let localizedStrings: LocalizedStrings
    let inboxCount: Int
    private weak var coordinatorDelegate: ProfileCoordinatorDelegate?
    public var isLoadingDonateConfigs: Bool = false {
        didSet {
            loadProfileSections()
        }
    }

    private let yearInReviewDependencies: YearInReviewDependencies?

    public init(isLoggedIn: Bool, isTemporaryAccount: Bool, localizedStrings: LocalizedStrings, inboxCount: Int, coordinatorDelegate: ProfileCoordinatorDelegate?, yearInReviewDependencies: YearInReviewDependencies?, badgeDelegate: YearInReviewBadgeDelegate?) {
        self.isLoggedIn = isLoggedIn
        self.isTemporaryAccount = isTemporaryAccount
        self.localizedStrings = localizedStrings
        self.inboxCount = inboxCount
        self.coordinatorDelegate = coordinatorDelegate
        self.yearInReviewDependencies = yearInReviewDependencies
        self.badgeDelegate = badgeDelegate
        loadProfileSections()
    }
    
    public func isUserLoggedIn() -> Bool {
        isLoggedIn
    }

    private func loadProfileSections() {
        profileSections = ProfileState.sections(isLoggedIn: isLoggedIn, isTemporaryAccount: isTemporaryAccount, localizedStrings: localizedStrings, inboxCount: inboxCount, coordinatorDelegate: coordinatorDelegate, isLoadingDonateConfigs: isLoadingDonateConfigs, yearInReviewDependencies: yearInReviewDependencies, badgeDelegate: badgeDelegate, refreshAction: loadProfileSections)
    }

    public struct LocalizedStrings {
        let pageTitle: String
        let doneButtonTitle: String
        let notificationsTitle: String
        let userPageTitle: String
        let talkPageTitle: String
        let watchlistTitle: String
        let logOutTitle: String
        let donateTitle: String
        let settingsTitle: String
        let joinWikipediaTitle: String
        let joinWikipediaSubtext: String
        let donateSubtext: String
        let yearInReviewTitle: String
        let yearInReviewLoggedOutSubtext: String

        public init(pageTitle: String, doneButtonTitle: String, notificationsTitle: String, userPageTitle: String, talkPageTitle: String, watchlistTitle: String, logOutTitle: String, donateTitle: String, settingsTitle: String, joinWikipediaTitle: String, joinWikipediaSubtext: String, donateSubtext: String, yearInReviewTitle: String, yearInReviewLoggedOutSubtext: String) {
            self.pageTitle = pageTitle
            self.doneButtonTitle = doneButtonTitle
            self.notificationsTitle = notificationsTitle
            self.userPageTitle = userPageTitle
            self.talkPageTitle = talkPageTitle
            self.watchlistTitle = watchlistTitle
            self.logOutTitle = logOutTitle
            self.donateTitle = donateTitle
            self.settingsTitle = settingsTitle
            self.joinWikipediaTitle = joinWikipediaTitle
            self.joinWikipediaSubtext = joinWikipediaSubtext
            self.donateSubtext = donateSubtext
            self.yearInReviewTitle = yearInReviewTitle
            self.yearInReviewLoggedOutSubtext = yearInReviewLoggedOutSubtext
        }
    }
}

struct ProfileListItem: Identifiable {
    var id = UUID()
    let text: String
    let image: UIImage?
    let imageColor: UIColor?
    let hasNotifications: Bool?
    var needsNotificationCount: Bool = false
    let isDonate: Bool
    let isLoadingDonateConfigs: Bool
    let action: () -> ()?
}

struct ProfileSection: Identifiable {
    let id = UUID()
    let listItems: [ProfileListItem]
    let subtext: String?
}

enum ProfileState {
    static func sections(isLoggedIn: Bool, isTemporaryAccount: Bool, localizedStrings: WMFProfileViewModel.LocalizedStrings, inboxCount: Int = 0, coordinatorDelegate: ProfileCoordinatorDelegate?, isLoadingDonateConfigs: Bool, yearInReviewDependencies: WMFProfileViewModel.YearInReviewDependencies?, badgeDelegate: YearInReviewBadgeDelegate?, refreshAction: @escaping () -> Void) -> [ProfileSection] {

        var needsYiRNotification = false
        if let yearInReviewDependencies {
            needsYiRNotification = yearInReviewDependencies.dataController.shouldShowYiRNotification(isLoggedOut: !isLoggedIn, isTemporaryAccount: isTemporaryAccount)
        }

        if isLoggedIn {
            let notificationsItem = ProfileListItem(
                text: localizedStrings.notificationsTitle,
                image: WMFSFSymbolIcon.for(symbol: .bellFill),
                imageColor: UIColor(Color.blue),
                hasNotifications: inboxCount > 0,
                needsNotificationCount: true,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showNotifications)
                }
            )
            let userPageItem = ProfileListItem(
                text: localizedStrings.userPageTitle,
                image: WMFSFSymbolIcon.for(symbol: .personFilled),
                imageColor: UIColor(Color.purple),
                hasNotifications: nil,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showUserPage)
                }
            )
            let talkPageItem = ProfileListItem(
                text: localizedStrings.talkPageTitle,
                image: WMFSFSymbolIcon.for(symbol: .chatBubbleFilled),
                imageColor: UIColor(Color.green),
                hasNotifications: nil,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showUserTalkPage)
                }
            )
            let watchlistItem = ProfileListItem(
                text: localizedStrings.watchlistTitle,
                image: WMFSFSymbolIcon.for(symbol: .textBadgeStar),
                imageColor: UIColor(Color.orange),
                hasNotifications: nil,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showWatchlist)
                }
            )
            let logoutItem = ProfileListItem(
                text: localizedStrings.logOutTitle,
                image: WMFSFSymbolIcon.for(symbol: .leave),
                imageColor: UIColor(Color.gray),
                hasNotifications: nil,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.logout)
                }
            )
            let donateItem = ProfileListItem(
                text: localizedStrings.donateTitle,
                image: WMFSFSymbolIcon.for(symbol: .heartFilled),
                imageColor: UIColor(Color.red),
                hasNotifications: nil,
                isDonate: true,
                isLoadingDonateConfigs: isLoadingDonateConfigs,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showDonate)
                    coordinatorDelegate?.handleProfileAction(.logDonateTap)
                }
            )

            let yearInReviewItem = ProfileListItem(
                text: localizedStrings.yearInReviewTitle,
                image: WMFSFSymbolIcon.for(symbol: .calendar),
                imageColor: WMFColor.blue600,
                hasNotifications: needsYiRNotification,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    badgeDelegate?.updateYIRBadgeVisibility()
                    refreshAction()
                    coordinatorDelegate?.handleProfileAction(.showYearInReview)
                    coordinatorDelegate?.handleProfileAction(.logYearInReviewTap)
                }
            )
            
            var section3Items = [donateItem]
            if let yearInReviewDependencies,
               yearInReviewDependencies.dataController.shouldShowYearInReviewEntryPoint(countryCode: yearInReviewDependencies.countryCode) {
                section3Items = [donateItem, yearInReviewItem]
            }
            
            let settingsItem = ProfileListItem(
                text: localizedStrings.settingsTitle,
                image: WMFSFSymbolIcon.for(symbol: .gear),
                imageColor: UIColor(Color.gray),
                hasNotifications: nil,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showSettings)
                }
            )
            return [
                ProfileSection(
                    listItems: [
                        notificationsItem
                    ],
                    subtext: nil
                ),
                ProfileSection(
                    listItems: [
                        userPageItem,
                        talkPageItem,
                        watchlistItem,
                        logoutItem
                    ],
                    subtext: nil
                ),
                ProfileSection(
                    listItems: section3Items,
                    subtext: nil
                ),
                ProfileSection(
                    listItems: [
                        settingsItem
                    ],
                    subtext: nil
                )
            ]
        } else if isTemporaryAccount {
            let notificationsItem = ProfileListItem(
                text: localizedStrings.notificationsTitle,
                image: WMFSFSymbolIcon.for(symbol: .bellFill),
                imageColor: UIColor(Color.blue),
                hasNotifications: inboxCount > 0,
                needsNotificationCount: true,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showNotifications)
                }
            )
            let userPageItem = ProfileListItem(
                text: localizedStrings.userPageTitle,
                image: WMFIcon.temp,
                imageColor: UIColor(Color.orange),
                hasNotifications: nil,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showUserPageTempAccount)
                }
            )
            let talkPageItem = ProfileListItem(
                text: localizedStrings.talkPageTitle,
                image: WMFSFSymbolIcon.for(symbol: .chatBubbleFilled),
                imageColor: UIColor(Color.green),
                hasNotifications: nil,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showUserTalkPageTempAccount)
                }
            )
            let joinWikipediaItem = ProfileListItem(
                text: localizedStrings.joinWikipediaTitle,
                image: WMFSFSymbolIcon.for(symbol: .leave),
                imageColor: UIColor(Color.gray),
                hasNotifications: nil,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.login)
                    
                }
            )
            let donateItem = ProfileListItem(
                text: localizedStrings.donateTitle,
                image: WMFSFSymbolIcon.for(symbol: .heartFilled),
                imageColor: UIColor(Color.red),
                hasNotifications: nil,
                isDonate: true,
                isLoadingDonateConfigs: isLoadingDonateConfigs,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showDonate)
                    coordinatorDelegate?.handleProfileAction(.logDonateTap)
                }
            )
            let settingsItem = ProfileListItem(
                text: localizedStrings.settingsTitle,
                image: WMFSFSymbolIcon.for(symbol: .gear),
                imageColor: UIColor(Color.gray),
                hasNotifications: nil,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showSettings)
                }
            )
            
            let joinSection = ProfileSection(
                listItems: [
                    userPageItem,
                    talkPageItem,
                    joinWikipediaItem
                ],
                subtext: localizedStrings.joinWikipediaSubtext
            )
            let donateSection = ProfileSection(
                listItems: [
                    donateItem
                ],
                subtext: localizedStrings.donateSubtext
            )
            let notificationsSection = ProfileSection(listItems: [notificationsItem], subtext: nil)
            let settingsSection = ProfileSection(listItems: [settingsItem], subtext: nil)
            
            let sections = [notificationsSection, joinSection, donateSection, settingsSection]
            return sections
        } else {
            let joinWikipediaItem = ProfileListItem(
                text: localizedStrings.joinWikipediaTitle,
                image: WMFSFSymbolIcon.for(symbol: .leave),
                imageColor: UIColor(Color.gray),
                hasNotifications: nil,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.login)
                    
                }
            )
            let donateItem = ProfileListItem(
                text: localizedStrings.donateTitle,
                image: WMFSFSymbolIcon.for(symbol: .heartFilled),
                imageColor: UIColor(Color.red),
                hasNotifications: nil,
                isDonate: true,
                isLoadingDonateConfigs: isLoadingDonateConfigs,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showDonate)
                    coordinatorDelegate?.handleProfileAction(.logDonateTap)
                }
            )

            let yearInReviewItem = ProfileListItem(
                text: localizedStrings.yearInReviewTitle,
                image: WMFSFSymbolIcon.for(symbol: .calendar),
                imageColor: WMFColor.blue600,
                hasNotifications: needsYiRNotification,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    if let dataController = try? WMFYearInReviewDataController() {
                        dataController.hasTappedProfileItem = true
                        badgeDelegate?.updateYIRBadgeVisibility()
                        needsYiRNotification = false
                    }
                    refreshAction()
                    coordinatorDelegate?.handleProfileAction(.showYearInReview)
                    coordinatorDelegate?.handleProfileAction(.logYearInReviewTap)
                }
            )
            
            let settingsItem = ProfileListItem(
                text: localizedStrings.settingsTitle,
                image: WMFSFSymbolIcon.for(symbol: .gear),
                imageColor: UIColor(Color.gray),
                hasNotifications: nil,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showSettings)
                }
            )
            
            let joinSection = ProfileSection(
                listItems: [
                    joinWikipediaItem
                ],
                subtext: localizedStrings.joinWikipediaSubtext
            )
            let donateSection = ProfileSection(
                listItems: [
                    donateItem
                ],
                subtext: localizedStrings.donateSubtext
            )
            let yearInReviewSection = ProfileSection(
                listItems: [
                    yearInReviewItem
                ],
                subtext: localizedStrings.yearInReviewLoggedOutSubtext
                )
            let settingsSection = ProfileSection(
                listItems: [
                    settingsItem
                ],
                subtext: nil
            )

            var sections = [joinSection, donateSection, settingsSection]
            if let yearInReviewDependencies,
               yearInReviewDependencies.dataController.shouldShowYearInReviewEntryPoint(countryCode: yearInReviewDependencies.countryCode) {
                sections = [joinSection, donateSection, yearInReviewSection, settingsSection]
            }
            
            return sections
        }
    }
}
