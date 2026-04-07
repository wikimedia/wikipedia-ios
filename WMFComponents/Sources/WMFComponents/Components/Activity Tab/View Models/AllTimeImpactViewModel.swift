import WMFData
import SwiftUI

@MainActor
final class AllTimeImpactViewModel: ObservableObject {
    
    struct LocalizedStrings {
        let allTimeImpact: String
        let totalEdits: String
        let bestStreakValue: (Int) -> String
        let bestStreakLabel: String
        let thanks: String
        let lastEdited: String
    }
    
    let localizedStrings: LocalizedStrings
    let totalEdits: Int?
    let bestStreak: Int?
    let thanksCount: Int?
    let lastEdited: Date?

    init(data: WMFUserImpactData, activityViewModel: WMFActivityTabViewModel) {
        self.localizedStrings = LocalizedStrings(allTimeImpact: activityViewModel.localizedStrings.allTimeImpactTitle, totalEdits: activityViewModel.localizedStrings.totalEditsLabel, bestStreakValue: activityViewModel.localizedStrings.bestStreakValue, bestStreakLabel: activityViewModel.localizedStrings.bestStreakLabel, thanks: activityViewModel.localizedStrings.thanksLabel, lastEdited: activityViewModel.localizedStrings.lastEditedLabel)
        self.totalEdits = data.totalEditsCount
        self.bestStreak = data.longestEditingStreak
        self.thanksCount = data.receivedThanksCount
        self.lastEdited = data.lastEditTimestamp
    }
}
