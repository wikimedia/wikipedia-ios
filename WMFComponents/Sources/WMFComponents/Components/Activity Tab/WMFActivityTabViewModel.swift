import WMFData
import SwiftUI
import Combine

@MainActor
public final class WMFActivityTabViewModel: ObservableObject {

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
            loggedOutSecondaryCTA: String
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
        }
    }

    public let localizedStrings: LocalizedStrings
    @Published public var isLoggedIn: Bool

    @Published public var articlesReadViewModel: ArticlesReadViewModel
    @Published public var articlesSavedViewModel: ArticlesSavedViewModel

    public var navigateToSaved: (() -> Void)?
    public var hasSeenActivityTab: () -> Void

    public init(
        localizedStrings: LocalizedStrings,
        dataController: WMFActivityTabDataController = .shared,
        hasSeenActivityTab: @escaping () -> Void,
        isLoggedIn: Bool
    ) {
        self.localizedStrings = localizedStrings
        self.isLoggedIn = isLoggedIn
        self.hasSeenActivityTab = hasSeenActivityTab

        let dateFormatter: (Date) -> String = { DateFormatter.wmfLastReadFormatter(for: $0) }

        self.articlesReadViewModel = ArticlesReadViewModel(
            dataController: dataController,
            dateFormatter: dateFormatter,
            makeUsernamesReading: localizedStrings.userNamesReading,
            noUsernameReading: localizedStrings.noUsernameReading
        )

        self.articlesSavedViewModel = ArticlesSavedViewModel(
            dateFormatter: dateFormatter
        )
    }

    public func fetchData() {
        Task {
            async let readVM: Void = articlesReadViewModel.fetch()
            async let savedVM: Void = articlesSavedViewModel.fetch()
            _ = await (readVM, savedVM)
            
            self.articlesReadViewModel = articlesReadViewModel
            self.articlesSavedViewModel = articlesSavedViewModel
        }
    }

    public func updateUsername(username: String) {
        articlesReadViewModel.updateUsername(username)
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
}
