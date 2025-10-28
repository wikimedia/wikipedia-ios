import Foundation
import SwiftUI
import WMFData

struct ArticlesReadViewModel {
    var username: String
    var hoursRead: Int
    var minutesRead: Int
    var totalArticlesRead: Int
    var dateTimeLastRead: String
}

@MainActor
public class WMFActivityTabViewModel: ObservableObject {
    let localizedStrings: LocalizedStrings
    private let dataController: WMFActivityTabDataController
    @Published var articlesReadViewModel: ArticlesReadViewModel?
    var hasSeenActivityTab: () -> Void
    
    public init(localizedStrings: LocalizedStrings,
                dataController: WMFActivityTabDataController,
                hasSeenActivityTab: @escaping () -> Void) {
        self.localizedStrings = localizedStrings
        self.dataController = dataController
        self.hasSeenActivityTab = hasSeenActivityTab
    }
    
    func fetchData() {
        Task {
            async let timeResult = dataController.getTimeReadPast7Days()
            async let articlesResult = dataController.getArticlesRead()
            async let dateResult = dataController.getMostRecentReadDateTime()
            
            let (hours, minutes) = (try? await timeResult) ?? (0, 0)
            let totalArticlesRead = (try? await articlesResult) ?? 0
            let dateTime = (try? await dateResult) ?? Date()
            
            let formattedDate = self.formatDateTime(dateTime)
            
            await MainActor.run {
                self.articlesReadViewModel = ArticlesReadViewModel(
                    username: "",
                    hoursRead: hours,
                    minutesRead: minutes,
                    totalArticlesRead: totalArticlesRead,
                    dateTimeLastRead: formattedDate
                )
            }
        }
    }
    
    // MARK: - View Strings
    
    public var usernamesReading: String {
        guard let model = articlesReadViewModel else { return "" }
        if model.username.isEmpty {
            return localizedStrings.noUsernameReading
        }
        return localizedStrings.userNamesReading(model.username)
    }
    
    public var hoursMinutesRead: String {
        guard let model = articlesReadViewModel else { return "" }
        return localizedStrings.totalHoursMinutesRead(model.hoursRead, model.minutesRead)
    }
    
    // MARK: - Update
    
    public func updateUsername(username: String) {
        guard var model = articlesReadViewModel else { return }
        model.username = username
        articlesReadViewModel = model
    }
    
    private func updateHoursMinutesRead(hours: Int, minutes: Int) {
        guard var model = articlesReadViewModel else { return }
        model.hoursRead = hours
        model.minutesRead = minutes
        articlesReadViewModel = model
    }
    
    private func updateTotalArticlesRead(totalArticlesRead: Int) {
        guard var model = articlesReadViewModel else { return }
        model.totalArticlesRead = totalArticlesRead
        articlesReadViewModel = model
    }
    
    public func updateDateTimeRead(dateTime: Date) {
        guard var model = articlesReadViewModel else { return }
        model.dateTimeLastRead = formatDateTime(dateTime)
        articlesReadViewModel = model
    }
    
    // MARK: - Helpers
    
    private func formatDateTime(_ dateTime: Date) -> String {
        DateFormatter.wmfLastReadFormatter(for: dateTime)
    }
    
    // MARK: - Localized Strings
    
    public struct LocalizedStrings {
        let userNamesReading: (String) -> String
        let noUsernameReading: String
        let totalHoursMinutesRead: (Int, Int) -> String
        let onWikipediaiOS: String
        let timeSpentReading: String
        let totalArticlesRead: String
        
        public init(
            userNamesReading: @escaping (String) -> String,
            noUsernameReading: String,
            totalHoursMinutesRead: @escaping (Int, Int) -> String,
            onWikipediaiOS: String,
            timeSpentReading: String,
            totalArticlesRead: String
        ) {
            self.userNamesReading = userNamesReading
            self.noUsernameReading = noUsernameReading
            self.totalHoursMinutesRead = totalHoursMinutesRead
            self.onWikipediaiOS = onWikipediaiOS
            self.timeSpentReading = timeSpentReading
            self.totalArticlesRead = totalArticlesRead
        }
    }
}
