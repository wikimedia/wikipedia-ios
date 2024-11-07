import Foundation
import SwiftUI
import WMFData

public class WMFProfileViewModel: ObservableObject {
    
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
    let localizedStrings: LocalizedStrings
    let inboxCount: Int
    private weak var coordinatorDelegate: ProfileCoordinatorDelegate?
    public var isLoadingDonateConfigs: Bool = false {
        didSet {
            loadProfileSections()
        }
    }

    private let yearInReviewDependencies: YearInReviewDependencies?

    public init(isLoggedIn: Bool, localizedStrings: LocalizedStrings, inboxCount: Int, coordinatorDelegate: ProfileCoordinatorDelegate?, yearInReviewDependencies: YearInReviewDependencies?) {
        self.isLoggedIn = isLoggedIn
        self.localizedStrings = localizedStrings
        self.inboxCount = inboxCount
        self.coordinatorDelegate = coordinatorDelegate
        self.yearInReviewDependencies = yearInReviewDependencies
        loadProfileSections()
    }

    private func loadProfileSections() {
        profileSections = ProfileState.sections(isLoggedIn: isLoggedIn, localizedStrings: localizedStrings, inboxCount: inboxCount, coordinatorDelegate: coordinatorDelegate, isLoadingDonateConfigs: isLoadingDonateConfigs, yearInReviewDependencies: yearInReviewDependencies)
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
    let image: WMFSFSymbolIcon?
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
    static func sections(isLoggedIn: Bool, localizedStrings: WMFProfileViewModel.LocalizedStrings, inboxCount: Int = 0, coordinatorDelegate: ProfileCoordinatorDelegate?, isLoadingDonateConfigs: Bool, yearInReviewDependencies: WMFProfileViewModel.YearInReviewDependencies?) -> [ProfileSection] {

        var needsYiRNotification = false
        if let yearInReviewDependencies {
            needsYiRNotification = yearInReviewDependencies.dataController.shouldShowYiRNotification(primaryAppLanguageProject: yearInReviewDependencies.primaryAppLanguageProject)
        }

        if isLoggedIn {
            let notificationsItem = ProfileListItem(
                text: localizedStrings.notificationsTitle,
                image: .bellFill,
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
                image: .personFilled,
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
                image: .chatBubbleFilled,
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
                image: .textBadgeStar,
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
                image: .leave,
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
                image: .heartFilled,
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
                image: .calendar,
                imageColor: WMFColor.blue600,
                hasNotifications: needsYiRNotification,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showYearInReview)
                    coordinatorDelegate?.handleProfileAction(.logYearInReviewTap)
                }
            )
            
            var section3Items = [donateItem]
            if let yearInReviewDependencies,
               yearInReviewDependencies.dataController.shouldShowYearInReviewEntryPoint(countryCode: yearInReviewDependencies.countryCode, primaryAppLanguageProject: yearInReviewDependencies.primaryAppLanguageProject) {
                section3Items = [donateItem, yearInReviewItem]
            }
            
            let settingsItem = ProfileListItem(
                text: localizedStrings.settingsTitle,
                image: .gear,
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
        } else {
            let joinWikipediaItem = ProfileListItem(
                text: localizedStrings.joinWikipediaTitle,
                image: .leave,
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
                image: .heartFilled,
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
                image: .calendar,
                imageColor: WMFColor.blue600,
                hasNotifications: needsYiRNotification,
                isDonate: false,
                isLoadingDonateConfigs: false,
                action: {
                    coordinatorDelegate?.handleProfileAction(.showYearInReview)
                    coordinatorDelegate?.handleProfileAction(.logYearInReviewTap)
                }
            )
            
            let settingsItem = ProfileListItem(
                text: localizedStrings.settingsTitle,
                image: .gear,
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
               yearInReviewDependencies.dataController.shouldShowYearInReviewEntryPoint(countryCode: yearInReviewDependencies.countryCode, primaryAppLanguageProject: yearInReviewDependencies.primaryAppLanguageProject) {
                sections = [joinSection, donateSection, yearInReviewSection, settingsSection]
            }
            
            return sections
        }
    }
}
