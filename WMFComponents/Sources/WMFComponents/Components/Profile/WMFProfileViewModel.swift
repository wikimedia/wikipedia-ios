import Foundation
import SwiftUI

public class WMFProfileViewModel: ObservableObject {
    @Published var profileSections: [ProfileSection] = []
    let isLoggedIn: Bool
    let localizedStrings: LocalizedStrings
    let inboxCount: Int
    private weak var coordinatorDelegate: ProfileCoordinatorDelegate?
    public var isLoadingDonateConfigs: Bool = false {
        didSet {
            loadProfileSections()
        }
    }

    public init(isLoggedIn: Bool, localizedStrings: LocalizedStrings, inboxCount: Int, coordinatorDelegate: ProfileCoordinatorDelegate?) {
        self.isLoggedIn = isLoggedIn
        self.localizedStrings = localizedStrings
        self.inboxCount = inboxCount
        self.coordinatorDelegate = coordinatorDelegate
        loadProfileSections()
    }

    private func loadProfileSections() {
        profileSections = ProfileState.sections(isLoggedIn: isLoggedIn, localizedStrings: localizedStrings, inboxCount: inboxCount, coordinatorDelegate: coordinatorDelegate, isLoadingDonateConfigs: isLoadingDonateConfigs)
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

        public init(pageTitle: String, doneButtonTitle: String, notificationsTitle: String, userPageTitle: String, talkPageTitle: String, watchlistTitle: String, logOutTitle: String, donateTitle: String, settingsTitle: String, joinWikipediaTitle: String, joinWikipediaSubtext: String, donateSubtext: String) {
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
        }
    }
}

struct ProfileListItem: Identifiable {
    var id = UUID()
    let text: String
    let image: WMFSFSymbolIcon?
    let imageColor: UIColor?
    let hasNotifications: Bool?
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
    static func sections(isLoggedIn: Bool, localizedStrings: WMFProfileViewModel.LocalizedStrings, inboxCount: Int = 0, coordinatorDelegate: ProfileCoordinatorDelegate?, isLoadingDonateConfigs: Bool) -> [ProfileSection] {
        if isLoggedIn {
            return [
                ProfileSection(
                    listItems: [
                        ProfileListItem(
                            text: localizedStrings.notificationsTitle,
                            image: .bellFill,
                            imageColor: UIColor(Color.blue),
                            hasNotifications: inboxCount > 0,
                            isDonate: false,
                            isLoadingDonateConfigs: false,
                            action: {
                                coordinatorDelegate?.handleProfileAction(.showNotifications)
                            }
                        )
                    ],
                    subtext: nil
                ),
                ProfileSection(
                    listItems: [
                        ProfileListItem(
                            text: localizedStrings.userPageTitle,
                            image: .personFilled,
                            imageColor: UIColor(Color.purple),
                            hasNotifications: nil,
                            isDonate: false,
                            isLoadingDonateConfigs: false,
                            action: {
                                coordinatorDelegate?.handleProfileAction(.showUserPage)
                            }
                        ),
                        ProfileListItem(
                            text: localizedStrings.talkPageTitle,
                            image: .chatBubbleFilled,
                            imageColor: UIColor(Color.green),
                            hasNotifications: nil,
                            isDonate: false,
                            isLoadingDonateConfigs: false,
                            action: {
                                coordinatorDelegate?.handleProfileAction(.showUserTalkPage)
                            }
                        ),
                        ProfileListItem(
                            text: localizedStrings.watchlistTitle,
                            image: .textBadgeStar,
                            imageColor: UIColor(Color.orange),
                            hasNotifications: nil,
                            isDonate: false,
                            isLoadingDonateConfigs: false,
                            action: {
                                coordinatorDelegate?.handleProfileAction(.showWatchlist)
                            }
                        ),
                        ProfileListItem(
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
                    ],
                    subtext: nil
                ),
                ProfileSection(
                    listItems: [
                        ProfileListItem(
                            text: localizedStrings.donateTitle,
                            image: .heartFilled,
                            imageColor: UIColor(Color.red),
                            hasNotifications: nil,
                            isDonate: true,
                            isLoadingDonateConfigs: isLoadingDonateConfigs,
                            action: {
                                coordinatorDelegate?.handleProfileAction(.showDonate)
                                coordinatorDelegate?.handleProfileAction(.donateTap)
                            }
                        )
                    ],
                    subtext: nil
                ),
                ProfileSection(
                    listItems: [
                        ProfileListItem(
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
                    ],
                    subtext: nil
                )
            ]
        } else {
            return [
                ProfileSection(
                    listItems: [
                        ProfileListItem(
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
                    ],
                    subtext: localizedStrings.joinWikipediaSubtext
                ),
                ProfileSection(
                    listItems: [
                        ProfileListItem(
                            text: localizedStrings.donateTitle,
                            image: .heartFilled,
                            imageColor: UIColor(Color.red),
                            hasNotifications: nil,
                            isDonate: true,
                            isLoadingDonateConfigs: isLoadingDonateConfigs,
                            action: {
                                coordinatorDelegate?.handleProfileAction(.showDonate)
                                coordinatorDelegate?.handleProfileAction(.donateTap)
                            }
                        )
                    ],
                    subtext: localizedStrings.donateSubtext
                ),
                ProfileSection(
                    listItems: [
                        ProfileListItem(
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
                    ],
                    subtext: nil
                )
            ]
        }
    }
}
