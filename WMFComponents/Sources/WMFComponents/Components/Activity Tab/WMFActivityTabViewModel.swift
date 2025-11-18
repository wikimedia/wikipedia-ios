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

public final class TimelineViewModel: ObservableObject {
    
    public final class Section: ObservableObject, Identifiable {
        public let id: String
        let date: Date
        @Published var items: [Item] = []
        
        init(id: String, date: Date, items: [TimelineViewModel.Item]) {
            self.id = id
            self.date = date
            self.items = items
        }
    }
    
    public enum ItemType {
        case standard // no icon, logged out users, etc.
        case edit
        case read
        case save
    }
    
    public final class Item: ObservableObject, Identifiable {
        public let id: String
        public let pageWithTimestamp: WMFPageWithTimestamp

        public init(id: String,
                    pageWithTimestamp: WMFPageWithTimestamp) {
            self.id = id
            self.pageWithTimestamp = pageWithTimestamp
        }

        public static func == (lhs: Item, rhs: Item) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    @Published var sections: [Section] = []
}

@MainActor
public class WMFActivityTabViewModel: ObservableObject {
    let localizedStrings: LocalizedStrings
    private let dataController: WMFActivityTabDataController
    public var onTapArticle: ((TimelineViewModel.Item) -> Void)?

    @Published var articlesReadViewModel: ArticlesReadViewModel = ArticlesReadViewModel(
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
    
    @Published var timelineViewModel = TimelineViewModel()

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
            async let timelineResult = dataController.fetchTimeline()

            let (hours, minutes) = (try? await timeResult) ?? (0, 0)
            let totalArticlesRead = (try? await articlesResult) ?? 0
            let dateTime = (try? await dateResult) ?? Date()
            let weeklyReads = (try? await weeklyResults) ?? []
            let categories = (try? await categoriesResult) ?? []
            let timeline = (try? await timelineResult) ?? [:]
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
            
            var timelineSections: [TimelineViewModel.Section] = []
            for (date, value) in timeline {
                var timelineItems: [TimelineViewModel.Item] = []
                for pageWithTimestamp in value {
                    let id = "\(pageWithTimestamp.page.projectID)-\(pageWithTimestamp.page.namespaceID)-\(pageWithTimestamp.page.title)-\(pageWithTimestamp.timestamp.timeIntervalSince1970)"
                    let item = TimelineViewModel.Item(id: id, pageWithTimestamp: pageWithTimestamp)
                    timelineItems.append(item)
                }
                timelineSections.append(TimelineViewModel.Section(id: "\(date.timeIntervalSince1970)", date: date, items: timelineItems))
            }
            
            await MainActor.run {
                
                var model = self.articlesReadViewModel
                model.hoursRead = hours
                model.minutesRead = minutes
                model.totalArticlesRead = totalArticlesRead
                model.dateTimeLastRead = formattedDate
                model.weeklyReads = weeklyReads
                model.topCategories = categories
                model.articlesSavedAmount = savedArticleCount
                model.dateTimeLastSaved = savedArticleDate.map { self.formatDateTime($0) } ?? ""
                model.articlesSavedImages = savedArticleImages
                self.articlesReadViewModel = model
                
                
                self.timelineViewModel.sections = timelineSections
            }
        }
    }

    // MARK: - View Strings

    public var hoursMinutesRead: String {
        localizedStrings.totalHoursMinutesRead(articlesReadViewModel.hoursRead, articlesReadViewModel.minutesRead)
    }

    // MARK: - Updates

    public func updateUsername(username: String) {
        articlesReadViewModel.username = username
        articlesReadViewModel.usernamesReading = username.isEmpty
            ? localizedStrings.noUsernameReading
            : localizedStrings.userNamesReading(username)
    }

    public func updateIsLoggedIn(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
    }

    // MARK: - Helpers
    
    func formatDateTime(_ dateTime: Date) -> String {
        DateFormatter.wmfLastReadFormatter(for: dateTime)
    }
    
    func formatDate(_ dateTime: Date) -> String {
        DateFormatter.wmfMonthDayYearDateFormatter.string(from: dateTime)
    }
    
    func onTap(_ item: TimelineViewModel.Item) {
        onTapArticle?(item)
    }
    
    @MainActor
    func deleteItem(item: TimelineViewModel.Item, in section: TimelineViewModel.Section) {
        Task {
            do {
                try await dataController.deletePageView(for: item.pageWithTimestamp)
                
                var itemIndex: Int?
                for (index, loopItem) in section.items.enumerated() {
                    if item.id == loopItem.id {
                        itemIndex = index
                    }
                }

                if let itemIndex {
                    section.items.remove(at: itemIndex)
                }

                
            } catch {
                print("Failed to delete page: \(error)")
            }
        }
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
        let todayTitle: String
        let yesterdayTitle: String
        let openArticle: String
        
        
        public init(userNamesReading: @escaping (String) -> String, noUsernameReading: String, totalHoursMinutesRead: @escaping (Int, Int) -> String, onWikipediaiOS: String, timeSpentReading: String, totalArticlesRead: String, week: String, articlesRead: String, topCategories: String, articlesSavedTitle: String, remaining: @escaping (Int) -> String, loggedOutTitle: String, loggedOutSubtitle: String, loggedOutPrimaryCTA: String, loggedOutSecondaryCTA: String, todayTitle: String, yesterdayTitle: String, openArticle: String) {
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
            self.todayTitle = todayTitle
            self.yesterdayTitle = yesterdayTitle
            self.openArticle = openArticle
        }
    }
}
