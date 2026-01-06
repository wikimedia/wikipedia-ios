import WMFData
import SwiftUI

@MainActor
final class ArticleViewsViewModel: ObservableObject {
    
    struct View: Identifiable {
        public let date: Date
        public let count: Int

        public var id: Date { date }
    }
    
    let totalViewsCount: Int
    let views: [View]

    init?(data: WMFUserImpactData) {
        let calendar = Calendar.current

        // Normalize to start-of-day
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -29, to: endDate)!

        // Normalize response dates
        let normalizedCounts: [Date: Int] = Dictionary(
            data.dailyTotalViews.map { date, count in
                (calendar.startOfDay(for: date), count)
            },
            uniquingKeysWith: +
        )

        var views: [View] = []
        var total = 0

        // Generate last 30 days, filling missing days with 0
        for offset in 0..<30 {
            let date = calendar.date(byAdding: .day, value: offset, to: startDate)!
            let count = normalizedCounts[date] ?? 0

            views.append(View(date: date, count: count))
            total += count
        }
        
        guard total > 0 else {
            return nil
        }

        self.views = views
        self.totalViewsCount = total
    }
}
