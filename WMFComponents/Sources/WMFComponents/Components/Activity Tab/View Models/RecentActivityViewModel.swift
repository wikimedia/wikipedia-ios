import WMFData
import SwiftUI

@MainActor
final class RecentActivityViewModel: ObservableObject {
    
    struct LocalizedStrings {
        let yourRecentActivity: String
        let edits: String
        let startEndDatesAccessibilityLabel: (String, String) -> String
    }
    
    struct Edit: Identifiable {
        public let date: Date
        public let count: Int

        public var id: Date { date }
    }
    
    let localizedStrings: LocalizedStrings
    let editCount: Int
    let startDate: Date
    let endDate: Date
    let edits: [Edit]

    init?(data: WMFUserImpactData, activityViewModel: WMFActivityTabViewModel) {
        
        self.localizedStrings = LocalizedStrings(yourRecentActivity: activityViewModel.localizedStrings.yourRecentActivityTitle, edits: activityViewModel.localizedStrings.editsLabel, startEndDatesAccessibilityLabel: activityViewModel.localizedStrings.startEndDatesAccessibilityLabel)
        
        let calendar = Calendar.current

        // Normalize to start-of-day so keys line up
        let endDate = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: endDate) else {
            return nil
        }

        // Normalize response dates to start-of-day
        let normalizedCounts: [Date: Int] = Dictionary(
            data.editCountByDay.map { key, value in
                (calendar.startOfDay(for: key), value)
            },
            uniquingKeysWith: +
        )

        // Generate last 30 days, filling missing days with 0
        var edits: [Edit] = []
        var totalCount = 0

        for offset in 0..<30 {
            let date = calendar.date(byAdding: .day, value: offset, to: startDate) ?? startDate
            let count = normalizedCounts[date] ?? 0

            edits.append(Edit(date: date, count: count))
            totalCount += count
        }
        
        self.startDate = startDate
        self.endDate = endDate
        self.edits = edits
        self.editCount = totalCount
        
        guard totalCount > 0 else {
            return nil
        }
    }
}
