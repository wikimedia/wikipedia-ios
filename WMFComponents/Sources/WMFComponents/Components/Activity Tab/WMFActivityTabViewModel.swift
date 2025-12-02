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
    public var didTapPrimaryLoggedOutCTA: (() -> Void)?

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
        public let todayTitle: String
        public let yesterdayTitle: String
        public let openArticle: String
        public let totalEdits: String
        public let read: String
        public let edited: String
        public let saved: String

        public init(userNamesReading: @escaping (String) -> String, noUsernameReading: String, totalHoursMinutesRead: @escaping (Int, Int) -> String, onWikipediaiOS: String, timeSpentReading: String, totalArticlesRead: String, week: String, articlesRead: String, topCategories: String, articlesSavedTitle: String, remaining: @escaping (Int) -> String, loggedOutTitle: String, loggedOutSubtitle: String, loggedOutPrimaryCTA: String, todayTitle: String, yesterdayTitle: String, openArticle: String, totalEdits: String, read: String, edited: String, saved: String) {
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
            self.todayTitle = todayTitle
            self.yesterdayTitle = yesterdayTitle
            self.openArticle = openArticle
            self.totalEdits = totalEdits
            self.read = read
            self.edited = edited
            self.saved = saved
        }
    }

    public let localizedStrings: LocalizedStrings

    // MARK: - Published State

    @Published public var authenticationState: LoginState
    @Published public var articlesReadViewModel: ArticlesReadViewModel
    @Published public var articlesSavedViewModel: ArticlesSavedViewModel
    @Published public var timelineViewModel: TimelineViewModel
    @Published public var shouldShowLogInPrompt: Bool = false

    @Published var globalEditCount: Int?
    public var navigateToGlobalEdits: (() -> Void)?

    // MARK: - Init

    public init(
        localizedStrings: LocalizedStrings,
        dataController: WMFActivityTabDataController = .shared,
        hasSeenActivityTab: @escaping () -> Void,
        authenticationState: LoginState
    ) {
        self.localizedStrings = localizedStrings
        self.dataController = dataController
        self.hasSeenActivityTab = hasSeenActivityTab
        self.authenticationState = authenticationState

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
        
        Task {
            await self.updateShouldShowLoginPrompt()
        }
    }

    // MARK: - Loading

    public func fetchData() {
        Task {
            async let readTask: Void = articlesReadViewModel.fetch()
            async let savedTask: Void = articlesSavedViewModel.fetch()
            async let timelineTask: Void = timelineViewModel.fetch()
            async let editCountTask: Void = getGlobalEditCount()

            _ = await (readTask, savedTask, timelineTask, editCountTask)

            self.articlesReadViewModel = articlesReadViewModel
            self.articlesSavedViewModel = articlesSavedViewModel
            self.timelineViewModel = timelineViewModel
            self.globalEditCount = globalEditCount

            hasSeenActivityTab()
        }
    }

    // MARK: - Updates

    private func getGlobalEditCount() async {
        do {
            let count = try await dataController.getGlobalEditCount()
            globalEditCount = count
        } catch {
            debugPrint("Error getting global edit count: \(error)")
        }

    }

    public func updateUsername(username: String) {
        articlesReadViewModel.username = username
        articlesReadViewModel.usernamesReading = username.isEmpty
            ? localizedStrings.noUsernameReading
            : localizedStrings.userNamesReading(username)
    }

    public func updateAuthenticationState(authState: LoginState) {
        self.authenticationState = authState
        Task {
            await self.updateShouldShowLoginPrompt()
        }
    }

    public var hoursMinutesRead: String {
        localizedStrings.totalHoursMinutesRead(
            articlesReadViewModel.hoursRead,
            articlesReadViewModel.minutesRead
        )
    }
    
    public func closeLoginPrompt() {
        Task {
            await dismissLoginPrompt()
        }
    }

    // MARK: - Helpers

    func formatDateTime(_ dateTime: Date) -> String {
        DateFormatter.wmfLastReadFormatter(for: dateTime)
    }

    func formatDate(_ dateTime: Date) -> String {
        DateFormatter.wmfMonthDayYearDateFormatter.string(from: dateTime)
    }
    
    func updateShouldShowLoginPrompt() async {
        let shouldShow = await dataController.shouldShowLoginPrompt(for: authenticationState)
        shouldShowLogInPrompt = shouldShow
    }

    func dismissLoginPrompt() async {
        shouldShowLogInPrompt = false
    }
}

@MainActor
extension WMFActivityTabViewModel {
    public struct TimelineSection: Identifiable {
        public let id: Date
        public let title: String
        public let subtitle: String
        public let pages: [TimelineItem]
    }

    public var timelineSections: [TimelineSection] {
        let calendar = Calendar.current
        return timelineViewModel.timeline.keys.sorted(by: >).map { date in
            let pages = timelineViewModel.timeline[date] ?? []
            let sortedPages = pages.sorted(by: { $0.date > $1.date })

            let title: String
            let subtitle: String
            if calendar.isDateInToday(date) {
                title = localizedStrings.todayTitle
                subtitle = formatDate(date)
            } else if calendar.isDateInYesterday(date) {
                title = localizedStrings.yesterdayTitle
                subtitle = formatDate(date)
            } else {
                title = formatDate(date)
                subtitle = ""
            }

            let filteredPages: [TimelineItem]
            if authenticationState != .loggedIn {
                filteredPages = sortedPages.filter { $0.itemType != .edit && $0.itemType != .saved }
            } else {
                filteredPages = sortedPages
            }

            return TimelineSection(id: date, title: title, subtitle: subtitle, pages: filteredPages)
        }
    }
}
