import WMFData
import SwiftUI

@MainActor
final class ContributionsViewModel: ObservableObject {
    let thisMonthCount: Int
    let lastMonthCount: Int
    let lastEdited: Date?
    weak var activityViewModel: WMFActivityTabViewModel?
    @Published public var shouldShowEditCTA: Bool = false

    init(data: WMFUserImpactData, activityViewModel: WMFActivityTabViewModel) {
        self.activityViewModel = activityViewModel
        let calendar = Calendar.current
        let now = Date()
        
        // Current month components
        let thisMonthComponents = calendar.dateComponents([.year, .month], from: now)
        
        // Last month date + components
        let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now)!
        let lastMonthComponents = calendar.dateComponents([.year, .month], from: lastMonthDate)
        
        var thisMonthCount: Int = 0
        var lastMonthCount: Int = 0
        
        for (date, count) in data.editCountByDay {
            let components = calendar.dateComponents([.year, .month], from: date)
            
            if components.year == thisMonthComponents.year &&
               components.month == thisMonthComponents.month {
                thisMonthCount += count
            } else if components.year == lastMonthComponents.year &&
                      components.month == lastMonthComponents.month {
                lastMonthCount += count
            }
        }
        
        if thisMonthCount == 0 {
            shouldShowEditCTA = true
        } else {
            shouldShowEditCTA = false
        }
        
        self.thisMonthCount = thisMonthCount
        self.lastMonthCount = lastMonthCount
        self.lastEdited = data.lastEditTimestamp
    }
    
    
    var dateText: String {
        guard let lastEdited = lastEdited else { return ""}
        let calendar = Calendar.current

        let title: String
        if let activityViewModel {
            if calendar.isDateInToday(lastEdited) {
                title = activityViewModel.localizedStrings.todayTitle
            } else if calendar.isDateInYesterday(lastEdited) {
                title = activityViewModel.localizedStrings.yesterdayTitle
            } else {
                title = activityViewModel.formatDateTime(lastEdited)
            }
        } else {
            return ""
        }
        
        return title
    }
}
