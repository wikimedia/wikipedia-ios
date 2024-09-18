import Foundation
import SwiftUI

// I updated the view model so it could hold the coordinator reference, this is just for prototyping reasons
// We can have a ViewController hold the ref to the coordinator, and call the delegate there
public class ProfileViewModel: ObservableObject {
    @Published var profileSections: [ProfileSection] = []
    private let isLoggedIn: Bool
    private weak var coordinatorDelegate: ProfileCoordinatorDelegate?

    public var onDismiss: (() -> Void)?

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
                                self?.coordinatorDelegate?.handleProfileAction(.showNotifications)
                            }
                        )
                    ],
                    subtext: nil
                ),

                ProfileSection(
                    listItems: [
                        ProfileListItem(
                            text: "Settings",
                            image: .gear,
                            imageColor: UIColor(Color.gray),
                            notificationNumber: 0,
                            action: { [weak self] in
                                self?.coordinatorDelegate?.handleProfileAction(.showSettings)
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

