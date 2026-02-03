import WMFData
import SwiftUI

@MainActor
final class ArticleViewsViewModel: ObservableObject {
    
    struct LocalizedStrings {
        let viewsOnArticlesYouveEdited: String
        let lineGraphDay: String
        let lineGraphViews: String
    }
    
    struct View: Identifiable {
        public let date: Date
        public let count: Int

        public var id: Date { date }
    }
    
    let localizedStrings: LocalizedStrings
    let totalViewsCount: Int
    let views: [View]

    init?(data: WMFUserImpactData, activityViewModel: WMFActivityTabViewModel) {
        
        guard !data.dailyTotalViews.isEmpty else {
            return nil
        }
        
        self.localizedStrings = LocalizedStrings(viewsOnArticlesYouveEdited: activityViewModel.localizedStrings.viewsOnArticlesYouveEditedTitle, lineGraphDay: activityViewModel.localizedStrings.lineGraphDay, lineGraphViews: activityViewModel.localizedStrings.lineGraphViews)
        
        let calendar = Calendar.current

        // Normalize to start-of-day
        let endDate = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: endDate) else {
            return nil
        }

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
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else {
                continue
            }
            
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
