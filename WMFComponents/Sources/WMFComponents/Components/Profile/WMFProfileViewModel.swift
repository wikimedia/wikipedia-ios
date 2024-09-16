import Foundation
import SwiftUI

public class WMFProfileViewModel: ObservableObject {
    @Published var profileSections: [ProfileSection] = []
    let isLoggedIn: Bool

    init(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
        loadProfileSections()
    }

    private func loadProfileSections() {
        if isLoggedIn {
            profileSections = ProfileState.loggedIn.sections
        } else {
            profileSections = ProfileState.loggedOut.sections
        }
    }
}

