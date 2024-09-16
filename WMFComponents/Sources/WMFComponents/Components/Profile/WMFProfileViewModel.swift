import Foundation
import SwiftUI

public class ProfileViewModel: ObservableObject {
    @Published var profileSections: [ProfileSection] = []
    private let isLoggedIn: Bool
    private weak var coordinatorDelegate: ProfileCoordinatorDelegate?

    public init(isLoggedIn: Bool, coordinatorDelegate: ProfileCoordinatorDelegate?) {
        self.isLoggedIn = isLoggedIn
        self.coordinatorDelegate = coordinatorDelegate
        setupSections()
    }

    private func setupSections() {
        switch isLoggedIn {
        case true:
            profileSections = [
                ProfileSection(
                    listItems: [
                        ProfileListItem(
                            text: "Notifications",
                            image: .bellFill,
                            imageColor: UIColor(Color.blue),
                            notificationNumber: 12,
                            action: { [weak self] in
                                self?.coordinatorDelegate?.showNotifications()
                            }
                        )
                    ],
                    subtext: nil
                )
                // add others

            ]
        case false:
            profileSections = [

            ]
        }
    }
}

