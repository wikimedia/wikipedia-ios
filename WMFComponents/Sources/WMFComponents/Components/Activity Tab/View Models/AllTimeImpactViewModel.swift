import WMFData
import SwiftUI

@MainActor
final class AllTimeImpactViewModel: ObservableObject {
    let totalEdits: Int?
    let bestStreak: Int?
    let thanksCount: Int?
    let lastEdited: Date?

    init(response: WMFUserImpactDataController.APIResponse) {
        self.totalEdits = response.totalEditsCount
        self.bestStreak = response.longestEditingStreak
        self.thanksCount = response.givenThanksCount
        self.lastEdited = response.lastEditTimestamp
    }
}
