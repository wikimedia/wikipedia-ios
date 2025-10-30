import Foundation
import SwiftUI
import WMFData

struct ArticlesReadViewModel {
    var username: String
    var hoursRead: Int
    var minutesRead: Int
    var totalArticlesRead: Int
    var dateTimeLastRead: String
	var weeklyReads: [Int]
	var topCategories: [String]
}

@MainActor
public class WMFActivityTabViewModel: ObservableObject {
    let localizedStrings: LocalizedStrings
    private let dataController: WMFActivityTabDataController
    @Published var articlesReadViewModel: ArticlesReadViewModel?
    var hasSeenActivityTab: () -> Void
    @Published var isLoggedIn: Bool
    @Published public var usernamesReading: String
    
    public init(localizedStrings: LocalizedStrings,
                dataController: WMFActivityTabDataController,
                hasSeenActivityTab: @escaping () -> Void,
                isLoggedIn: Bool) {
        self.localizedStrings = localizedStrings
        self.dataController = dataController
        self.hasSeenActivityTab = hasSeenActivityTab
        self.isLoggedIn = isLoggedIn
        self.usernamesReading = localizedStrings.noUsernameReading
    }
    
    func fetchData() {
        Task {
            async let timeResult = dataController.getTimeReadPast7Days()
            async let articlesResult = dataController.getArticlesRead()
            async let dateResult = dataController.getMostRecentReadDateTime()
            async let weeklyResults = dataController.getWeeklyReadsThisMonth()
            async let categoriesResult = dataController.getTopCategories()
            
            let (hours, minutes) = (try? await timeResult) ?? (0, 0)
            let totalArticlesRead = (try? await articlesResult) ?? 0
            let dateTime = (try? await dateResult) ?? Date()
			let weeklyReads = (try? await weeklyResults) ?? []
			let categories = (try? await categoriesResult) ?? []
            
            let formattedDate = self.formatDateTime(dateTime)
            
            await MainActor.run {
                self.articlesReadViewModel = ArticlesReadViewModel(
                    username: "",
                    hoursRead: hours,
                    minutesRead: minutes,
                    totalArticlesRead: totalArticlesRead,
                    dateTimeLastRead: formattedDate,
					weeklyReads: weeklyReads,
					topCategories: categories
                )
            }
        }
    }
    
    // MARK: - View Strings
    
    public var hoursMinutesRead: String {
        guard let model = articlesReadViewModel else { return "" }
        return localizedStrings.totalHoursMinutesRead(model.hoursRead, model.minutesRead)
    }
    
    // MARK: - Update
    
    public func updateUsername(username: String) {
        updateUsernamesReading(username: username)
        guard var model = articlesReadViewModel else { return }
        model.username = username
        if !username.isEmpty {
            updateIsLoggedIn(isLoggedIn: true)
        }
        articlesReadViewModel = model
    }
    
    private func updateUsernamesReading(username: String) {
       usernamesReading = localizedStrings.userNamesReading(username)
    }
    
    public func updateIsLoggedIn(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
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
    
    private func updateDateTimeRead(dateTime: Date) {
        guard var model = articlesReadViewModel else { return }
        model.dateTimeLastRead = formatDateTime(dateTime)
        articlesReadViewModel = model
    }

 	private func updateWeeklyReads(weeklyReads: [Int]) {
        guard var model = articlesReadViewModel else { return }
        model.weeklyReads = weeklyReads
        articlesReadViewModel = model
    }
    
    public func updateTopCategories(topCategories: [String]) {
        guard var model = articlesReadViewModel else { return }
        model.topCategories = topCategories
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
        let week: String
        let articlesRead: String
        let topCategories: String
        let loggedOutTitle: String
        
        public init(userNamesReading: @escaping (String) -> String, noUsernameReading: String, totalHoursMinutesRead: @escaping (Int, Int) -> String, onWikipediaiOS: String, timeSpentReading: String, totalArticlesRead: String, week: String, articlesRead: String, topCategories: String, loggedOutTitle: String) {
            self.userNamesReading = userNamesReading
            self.noUsernameReading = noUsernameReading
            self.totalHoursMinutesRead = totalHoursMinutesRead
            self.onWikipediaiOS = onWikipediaiOS
            self.timeSpentReading = timeSpentReading
            self.totalArticlesRead = totalArticlesRead
            self.week = week
            self.articlesRead = articlesRead
            self.topCategories = topCategories
            self.loggedOutTitle = loggedOutTitle
        }
    }
}
