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
    var timeline: [Date: [TimelineItem]]?
    var pageSummaries: [String: WMFArticleSummary] = [:] // always initialized
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
        articlesSavedImages: [],
        timeline: [:]
    )

    var hasSeenActivityTab: () -> Void
    @Published var isLoggedIn: Bool
    public var navigateToSaved: (() -> Void)?
    public var savedArticlesModuleDataDelegate: SavedArticleModuleDataDelegate?

    public init(
        localizedStrings: LocalizedStrings,
        dataController: WMFActivityTabDataController,
        hasSeenActivityTab: @escaping () -> Void,
        isLoggedIn: Bool
    ) {
        self.localizedStrings = localizedStrings
        self.dataController = dataController
        self.hasSeenActivityTab = hasSeenActivityTab
        self.isLoggedIn = isLoggedIn
    }

    // MARK: - Fetch Main Data

    func fetchData() {
        Task {
            async let timeResult = dataController.getTimeReadPast7Days()
            async let articlesResult = dataController.getArticlesRead()
            async let dateResult = dataController.getMostRecentReadDateTime()
            async let weeklyResults = dataController.getWeeklyReadsThisMonth()
            async let categoriesResult = dataController.getTopCategories()
            async let timelineResult = dataController.fetchTimeline() // returns [Date: [TimelineItem]]

            let (hours, minutes) = (try? await timeResult) ?? (0, 0)
            let totalArticlesRead = (try? await articlesResult) ?? 0
            let dateTime = (try? await dateResult) ?? Date()
            let weeklyReads = (try? await weeklyResults) ?? []
            let categories = (try? await categoriesResult) ?? []
            let timelineItems = (try? await timelineResult) ?? [:]
            let formattedDate = self.formatDateTime(dateTime)

            // TEMP: Saved Articles Module
            let calendar = Calendar.current
            var savedArticleCount: Int = 0
            var savedArticleDate: Date? = nil
            var savedArticleImages: [URL] = []
            let endDate = Date()
            if let startDate = calendar.date(byAdding: .day, value: -30, to: endDate),
               let tempData = await savedArticlesModuleDataDelegate?.getSavedArticleModuleData(from: startDate, to: endDate) {
                savedArticleCount = tempData.savedArticlesCount
                savedArticleDate = tempData.dateLastSaved
                savedArticleImages = tempData.articleUrlStrings.compactMap { URL(string: $0) }
            }

            // Update model on MainActor
            await MainActor.run {
                var model = self.model
                model.hoursRead = hours
                model.minutesRead = minutes
                model.totalArticlesRead = totalArticlesRead
                model.dateTimeLastRead = formattedDate
                model.weeklyReads = weeklyReads
                model.topCategories = categories
                model.timeline = timelineItems
                model.articlesSavedAmount = savedArticleCount
                model.dateTimeLastSaved = savedArticleDate.map { self.formatDateTime($0) } ?? ""
                model.articlesSavedImages = savedArticleImages
                self.model = model
            }
        }
    }

    // MARK: - Lazy Summary Fetching

    public func fetchSummary(for item: TimelineItem) async -> WMFArticleSummary? {
        let pageKey = "\(item.projectID)~\(item.pageTitle)~\(item.date.ISO8601Format())"
        if let existing = model.pageSummaries[pageKey] {
            return existing
        }
        if let summary = try? await dataController.fetchSummary(for: item.page) {
            await MainActor.run {
                self.model.pageSummaries[pageKey] = summary
            }
            return summary
        }
        return nil
    }

    // MARK: - View Strings

    public var hoursMinutesRead: String {
        localizedStrings.totalHoursMinutesRead(model.hoursRead, model.minutesRead)
    }

    // MARK: - Updates

    public func updateUsername(username: String) {
        model.username = username
        model.usernamesReading = username.isEmpty
            ? localizedStrings.noUsernameReading
            : localizedStrings.userNamesReading(username)
    }

    public func updateIsLoggedIn(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
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
