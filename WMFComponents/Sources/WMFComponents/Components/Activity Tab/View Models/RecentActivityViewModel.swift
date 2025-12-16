import WMFData
import SwiftUI

@MainActor
final class RecentActivityViewModel: ObservableObject {
    
    struct Edit: Identifiable {
        public let date: Date
        public let count: Int

        public var id: Date { date }
    }
    
    let editCount: Int
    let startDate: Date
    let endDate: Date
    let edits: [Edit]

    init(response: WMFUserImpactDataController.APIResponse) {
        let calendar = Calendar.current

        // Normalize to start-of-day so keys line up
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -29, to: endDate)!

        // Normalize response dates to start-of-day
        let normalizedCounts: [Date: Int] = Dictionary(
            response.editCountByDay.map { key, value in
                (calendar.startOfDay(for: key), value)
            },
            uniquingKeysWith: +
        )

        // Generate last 30 days, filling missing days with 0
        var edits: [Edit] = []
        var totalCount = 0

        for offset in 0..<30 {
            let date = calendar.date(byAdding: .day, value: offset, to: startDate)!
            let count = normalizedCounts[date] ?? 0

            edits.append(Edit(date: date, count: count))
            totalCount += count
        }

        self.startDate = startDate
        self.endDate = endDate
        self.edits = edits
        self.editCount = totalCount
    }
}
