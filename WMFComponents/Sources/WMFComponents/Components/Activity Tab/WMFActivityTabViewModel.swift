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
    var usernamesReading: String
    var articlesSavedAmount: Int
    var dateTimeLastSaved: String
    var articlesSavedImages: [URL]
}

@MainActor
public class WMFActivityTabViewModel: ObservableObject {
    let localizedStrings: LocalizedStrings
    private let dataController: WMFActivityTabDataController
    @Published var model: ArticlesReadViewModel = ArticlesReadViewModel(
        username: "",
        hoursRead: 0,
        minutesRead: 0,
        totalArticlesRead: 0,
        dateTimeLastRead: "",
        weeklyReads: [],
        topCategories: [],
        usernamesReading: "",
        articlesSavedAmount: 0,
        dateTimeLastSaved: "",
        articlesSavedImages: []
    )
    var hasSeenActivityTab: () -> Void
    @Published var isLoggedIn: Bool
    public var navigateToSaved: (() -> Void)?
    public var savedArticlesModuleDataDelegate: SavedArticleModuleDataDelegate?
    
    public init(localizedStrings: LocalizedStrings,
                dataController: WMFActivityTabDataController,
                hasSeenActivityTab: @escaping () -> Void,
                isLoggedIn: Bool) {
        self.localizedStrings = localizedStrings
        self.dataController = dataController
        self.hasSeenActivityTab = hasSeenActivityTab
        self.isLoggedIn = isLoggedIn
    }
    
    public func fetchData() {
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
            
            // BEGIN: TEMP SAVED ARTICLES STUFF
            let calendar = Calendar.current
            var savedArticleCount: Int = 0
            var savedArticleDate: Date? = nil
            var savedArticleImages: [String] = []
            let endDate = Date()
            if let startDate = calendar.date(byAdding: .day, value: -30, to: endDate),
               let tempSavedArticlesStuff = await savedArticlesModuleDataDelegate?.getSavedArticleModuleData(from: startDate, to: endDate) {
                savedArticleCount = tempSavedArticlesStuff.savedArticlesCount
                savedArticleDate = tempSavedArticlesStuff.dateLastSaved
                savedArticleImages = tempSavedArticlesStuff.articleUrlStrings
            }
            // END: TEMP SAVED ARTICLES STUFF
            
            await MainActor.run {
                var model = self.model
                model.hoursRead = hours
                model.minutesRead = minutes
                model.totalArticlesRead = totalArticlesRead
                model.dateTimeLastRead = formattedDate
                model.weeklyReads = weeklyReads
                model.topCategories = categories

                // BEGIN: TEMP SAVED ARTICLES STUFF
                model.articlesSavedAmount = savedArticleCount
                model.dateTimeLastSaved = savedArticleDate != nil ? self.formatDateTime(savedArticleDate!) : ""
                model.articlesSavedImages = savedArticleImages.compactMap { URL(string: $0) }
                // END: TEMP SAVED ARTICLES STUFF
                
                self.model = model
            }
        }
    }
    
    // MARK: - View Strings
    
    public var hoursMinutesRead: String {
        return localizedStrings.totalHoursMinutesRead(model.hoursRead, model.minutesRead)
    }
    
    // MARK: - Update
    
    public func updateUsername(username: String) {
        model.username = username
        model.usernamesReading = username.isEmpty
            ? localizedStrings.noUsernameReading
            : localizedStrings.userNamesReading(username)

        self.model = model
    }

    public func updateIsLoggedIn(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
    }
    
    private func updateHoursMinutesRead(hours: Int, minutes: Int) {
        model.hoursRead = hours
        model.minutesRead = minutes
    }
    
    private func updateTotalArticlesRead(totalArticlesRead: Int) {
        model.totalArticlesRead = totalArticlesRead
    }
    
    private func updateDateTimeRead(dateTime: Date) {
        model.dateTimeLastRead = formatDateTime(dateTime)
    }

 	private func updateWeeklyReads(weeklyReads: [Int]) {
        model.weeklyReads = weeklyReads
    }
    
    private func updateTopCategories(topCategories: [String]) {
        model.topCategories = topCategories
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
        let articlesSavedTitle: String
        let remaining: (Int) -> String
		let loggedOutTitle: String
        let loggedOutSubtitle: String
        let loggedOutPrimaryCTA: String
        let loggedOutSecondaryCTA: String
        
        public init(userNamesReading: @escaping (String) -> String, noUsernameReading: String, totalHoursMinutesRead: @escaping (Int, Int) -> String, onWikipediaiOS: String, timeSpentReading: String, totalArticlesRead: String, week: String, articlesRead: String, topCategories: String, articlesSavedTitle: String, remaining: @escaping (Int) -> String, loggedOutTitle: String, loggedOutSubtitle: String, loggedOutPrimaryCTA: String, loggedOutSecondaryCTA: String) {
            self.userNamesReading = userNamesReading
            self.noUsernameReading = noUsernameReading
            self.totalHoursMinutesRead = totalHoursMinutesRead
            self.onWikipediaiOS = onWikipediaiOS
            self.timeSpentReading = timeSpentReading
            self.totalArticlesRead = totalArticlesRead
            self.week = week
            self.articlesRead = articlesRead
            self.topCategories = topCategories
            self.articlesSavedTitle = articlesSavedTitle
            self.remaining = remaining
            self.loggedOutTitle = loggedOutTitle
            self.loggedOutSubtitle = loggedOutSubtitle
            self.loggedOutPrimaryCTA = loggedOutPrimaryCTA
            self.loggedOutSecondaryCTA = loggedOutSecondaryCTA
        }
    }
}
