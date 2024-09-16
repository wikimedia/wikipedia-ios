import Foundation
import SwiftUI

public class WMFProfileViewModel: ObservableObject {
    @Published var profileSections: [ProfileSection] = []
    let isLoggedIn: Bool
    let localizedStrings: LocalizedStrings

    init(isLoggedIn: Bool, localizedStrings: LocalizedStrings) {
        self.isLoggedIn = isLoggedIn
        self.localizedStrings = localizedStrings
        loadProfileSections()
    }

    private func loadProfileSections() {
        profileSections = ProfileState.sections(isLoggedIn: isLoggedIn, localizedStrings: localizedStrings)
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
    }
}

struct ProfileListItem: Identifiable {
    var id = UUID()
    let text: String
    let image: WMFSFSymbolIcon?
    let imageColor: UIColor?
    let notificationNumber: Int?
    let action: () -> ()?
}

struct ProfileSection: Identifiable {
    let id = UUID()
    let listItems: [ProfileListItem]
    let subtext: String?
}

enum ProfileState {
    static func sections(isLoggedIn: Bool, localizedStrings: WMFProfileViewModel.LocalizedStrings) -> [ProfileSection] {
        if isLoggedIn {
            return [
                ProfileSection(
                    listItems: [
                        ProfileListItem(
                            text: localizedStrings.notificationsTitle,
                            image: .bellFill,
                            imageColor: UIColor(Color.blue),
                            notificationNumber: 12,
                            action: {}
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
                            notificationNumber: nil,
                            action: {}
                        ),
                        ProfileListItem(
                            text: localizedStrings.talkPageTitle,
                            image: .chatBubbleFilled,
                            imageColor: UIColor(Color.green),
                            notificationNumber: nil,
                            action: {}
                        ),
                        ProfileListItem(
                            text: localizedStrings.watchlistTitle,
                            image: .textBadgeStar,
                            imageColor: UIColor(Color.orange),
                            notificationNumber: nil,
                            action: {}
                        ),
                        ProfileListItem(
                            text: localizedStrings.logOutTitle,
                            image: .leave,
                            imageColor: UIColor(Color.gray),
                            notificationNumber: nil,
                            action: {}
                        )
                    ],
                    subtext: nil
                ),
                ProfileSection(
                    listItems: [
                        ProfileListItem(
                            text: localizedStrings.donateTitle,
                            image: .heart,
                            imageColor: UIColor(Color.red),
                            notificationNumber: nil,
                            action: {}
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
                            notificationNumber: nil,
                            action: {}
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
                            notificationNumber: nil,
                            action: {}
                        )
                    ],
                    subtext: localizedStrings.joinWikipediaSubtext
                ),
                ProfileSection(
                    listItems: [
                        ProfileListItem(
                            text: localizedStrings.donateTitle,
                            image: .heart,
                            imageColor: UIColor(Color.red),
                            notificationNumber: nil,
                            action: {}
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
                            notificationNumber: nil,
                            action: {}
                        )
                    ],
                    subtext: nil
                )
            ]
        }
    }
}
