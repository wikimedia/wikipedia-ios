import WMFData
import SwiftUI

@MainActor
final class ContributionsViewModel: ObservableObject {
    let thisMonthCount: Int
    let lastMonthCount: Int

    init(response: WMFUserImpactDataController.APIResponse) {
        let calendar = Calendar.current
        let now = Date()
        
        // Current month components
        let thisMonthComponents = calendar.dateComponents([.year, .month], from: now)
        
        // Last month date + components
        let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now)!
        let lastMonthComponents = calendar.dateComponents([.year, .month], from: lastMonthDate)
        
        var thisMonthCount: Int = 0
        var lastMonthCount: Int = 0
        
        for (date, count) in response.editCountByDay {
            let components = calendar.dateComponents([.year, .month], from: date)
            
            if components.year == thisMonthComponents.year &&
               components.month == thisMonthComponents.month {
                thisMonthCount += count
            } else if components.year == lastMonthComponents.year &&
                      components.month == lastMonthComponents.month {
                lastMonthCount += count
            }
        }
        
        self.thisMonthCount = thisMonthCount
        self.lastMonthCount = lastMonthCount
    }
}
