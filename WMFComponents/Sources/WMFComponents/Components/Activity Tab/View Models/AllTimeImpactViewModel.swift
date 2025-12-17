import WMFData
import SwiftUI

@MainActor
final class AllTimeImpactViewModel: ObservableObject {
    let totalEdits: Int?
    let bestStreak: Int?
    let thanksCount: Int?
    let lastEdited: Date?

    init(data: WMFUserImpactData) {
        self.totalEdits = data.totalEditsCount
        self.bestStreak = data.longestEditingStreak
        self.thanksCount = data.receivedThanksCount
        self.lastEdited = data.lastEditTimestamp
    }
}
