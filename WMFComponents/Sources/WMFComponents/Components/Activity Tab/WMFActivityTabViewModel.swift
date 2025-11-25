import WMFData
import SwiftUI
import Combine

@MainActor
public final class WMFActivityTabViewModel: ObservableObject {

    // MARK: - Dependencies

    private let dataController: WMFActivityTabDataController
    let hasSeenActivityTab: () -> Void

    // MARK: - Navigation / Delegates


    public var savedArticlesModuleDataDelegate: SavedArticleModuleDataDelegate?

    // MARK: - Localization

    public struct LocalizedStrings {
        public let userNamesReading: (String) -> String
        public let noUsernameReading: String
        public let totalHoursMinutesRead:  (Int, Int) -> String
        public let onWikipediaiOS: String
        public let timeSpentReading: String
        public let totalArticlesRead: String
        public let week: String
        public let articlesRead: String
        public let topCategories: String
        public let articlesSavedTitle: String
        public let remaining: (Int) -> String
        public let loggedOutTitle: String
        public let loggedOutSubtitle: String
        public let loggedOutPrimaryCTA: String
        public let loggedOutSecondaryCTA: String
        public let todayTitle: String
        public let yesterdayTitle: String
        public let openArticle: String

        public init(
            userNamesReading: @escaping (String) -> String,
            noUsernameReading: String,
            totalHoursMinutesRead: @escaping (Int, Int) -> String,
            onWikipediaiOS: String,
            timeSpentReading: String,
            totalArticlesRead: String,
            week: String,
            articlesRead: String,
            topCategories: String,
            articlesSavedTitle: String,
            remaining: @escaping (Int) -> String,
            loggedOutTitle: String,
            loggedOutSubtitle: String,
            loggedOutPrimaryCTA: String,
            loggedOutSecondaryCTA: String,
            todayTitle: String,
            yesterdayTitle: String,
            openArticle: String
        ) {
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

    public let localizedStrings: LocalizedStrings

    // MARK: - Published State

    @Published public var isLoggedIn: Bool
    @Published public var articlesReadViewModel: ArticlesReadViewModel
    @Published public var articlesSavedViewModel: ArticlesSavedViewModel
    @Published public var timelineViewModel: TimelineViewModel

    // MARK: - Init

    public init(
        localizedStrings: LocalizedStrings,
        dataController: WMFActivityTabDataController = .shared,
        hasSeenActivityTab: @escaping () -> Void,
        isLoggedIn: Bool
    ) {
        self.localizedStrings = localizedStrings
        self.dataController = dataController
        self.hasSeenActivityTab = hasSeenActivityTab
        self.isLoggedIn = isLoggedIn

        let dateFormatter: (Date) -> String = { date in
            DateFormatter.wmfLastReadFormatter(for: date)
        }

        self.articlesReadViewModel = ArticlesReadViewModel(
            dataController: dataController,
            dateFormatter: dateFormatter,
            makeUsernamesReading: localizedStrings.userNamesReading,
            noUsernameReading: localizedStrings.noUsernameReading
        )

        self.articlesSavedViewModel = ArticlesSavedViewModel(
            dateFormatter: dateFormatter
        )

        self.timelineViewModel = TimelineViewModel(
            dataController: dataController
        )
    }

    // MARK: - Loading

    public func fetchData() {
        Task {
            async let readTask: Void = articlesReadViewModel.fetch()
            async let savedTask: Void = articlesSavedViewModel.fetch()
            async let timelineTask: Void = timelineViewModel.fetch()

            _ = await (readTask, savedTask, timelineTask)

            self.articlesReadViewModel = articlesReadViewModel
            self.articlesSavedViewModel = articlesSavedViewModel
            self.timelineViewModel = timelineViewModel

            hasSeenActivityTab()
        }
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

    public var hoursMinutesRead: String {
        localizedStrings.totalHoursMinutesRead(
            articlesReadViewModel.hoursRead,
            articlesReadViewModel.minutesRead
        )
    }

    // MARK: - Helpers

    func formatDateTime(_ dateTime: Date) -> String {
        DateFormatter.wmfLastReadFormatter(for: dateTime)
    }

    func formatDate(_ dateTime: Date) -> String {
        DateFormatter.wmfMonthDayYearDateFormatter.string(from: dateTime)
    }

}
