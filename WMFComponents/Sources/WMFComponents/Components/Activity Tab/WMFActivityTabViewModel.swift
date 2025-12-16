import WMFData
import SwiftUI
import Combine

@MainActor
public final class WMFActivityTabViewModel: ObservableObject {

    // MARK: - Dependencies

    private let dataController: WMFActivityTabDataController

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
        public let yourImpact: String
        public let todayTitle: String
        public let yesterdayTitle: String
        public let openArticle: String
        public let deleteAccessibilityLabel: String
        public let totalEdits: String
        public let read: String
        public let edited: String
        public let saved: String
        public let emptyViewTitleLoggedIn: String
        public let emptyViewSubtitleLoggedIn: String
        public let emptyViewTitleLoggedOut: String
        public let emptyViewSubtitleLoggedOut: String

        public init(userNamesReading: @escaping (String) -> String, noUsernameReading: String, totalHoursMinutesRead: @escaping (Int, Int) -> String, onWikipediaiOS: String, timeSpentReading: String, totalArticlesRead: String, week: String, articlesRead: String, topCategories: String, articlesSavedTitle: String, remaining: @escaping (Int) -> String, loggedOutTitle: String, loggedOutSubtitle: String, loggedOutPrimaryCTA: String, yourImpact: String, todayTitle: String, yesterdayTitle: String, openArticle: String, deleteAccessibilityLabel: String, totalEdits: String, read: String, edited: String, saved: String, emptyViewTitleLoggedIn: String, emptyViewSubtitleLoggedIn: String, emptyViewTitleLoggedOut: String, emptyViewSubtitleLoggedOut: String) {
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
            self.yourImpact = yourImpact
            self.todayTitle = todayTitle
            self.yesterdayTitle = yesterdayTitle
            self.openArticle = openArticle
            self.deleteAccessibilityLabel = deleteAccessibilityLabel
            self.totalEdits = totalEdits
            self.read = read
            self.edited = edited
            self.saved = saved
            self.emptyViewTitleLoggedIn = emptyViewTitleLoggedIn
            self.emptyViewSubtitleLoggedIn = emptyViewSubtitleLoggedIn
            self.emptyViewTitleLoggedOut = emptyViewTitleLoggedOut
            self.emptyViewSubtitleLoggedOut = emptyViewSubtitleLoggedOut
        }
    }

    public let localizedStrings: LocalizedStrings
    var userID: Int?

    // MARK: - Published State

    @Published public var authenticationState: LoginState
    @Published public var articlesReadViewModel: ArticlesReadViewModel
    @Published public var articlesSavedViewModel: ArticlesSavedViewModel
    @Published public var timelineViewModel: TimelineViewModel
    @Published public var emptyViewModel: WMFEmptyViewModel
    @Published public var shouldShowLogInPrompt: Bool = false
    @Published var sections: [TimelineViewModel.TimelineSection] = []

    @Published var globalEditCount: Int?
    public var isEmpty: Bool = false
    public var onTapGlobalEdits: (() -> Void)?
    public var fetchDataCompleteAction: ((Bool) -> Void)?

    // MARK: - Init

    public init(
        localizedStrings: LocalizedStrings,
        dataController: WMFActivityTabDataController = .shared,
        authenticationState: LoginState
    ) {
        self.localizedStrings = localizedStrings
        self.dataController = dataController
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
        
        self.emptyViewModel = Self.generateEmptyViewModel(localizedStrings: localizedStrings, isLoggedIn: authenticationState == .loggedIn)
        
        self.timelineViewModel.activityTabViewModel = self
        
        Task {
            await self.updateShouldShowLoginPrompt()
        }
    }

    // MARK: - Loading

    public func fetchData(fromAppearance: Bool = false) {
        Task {
            async let readTask: Void = articlesReadViewModel.fetch()
            async let savedTask: Void = articlesSavedViewModel.fetch()
            async let timelineTask: Void = timelineViewModel.fetch()
            async let editCountTask: Void = getGlobalEditCount()
            async let userImpactTask: Void = fetchUserImpact()
            
            _ = await (readTask, savedTask, timelineTask, editCountTask)
            
            self.articlesReadViewModel = articlesReadViewModel
            self.articlesSavedViewModel = articlesSavedViewModel
            self.timelineViewModel = timelineViewModel
            self.globalEditCount = globalEditCount
            
            isEmpty =
                articlesReadViewModel.hoursRead == 0 &&
                articlesReadViewModel.minutesRead == 0 &&
                articlesSavedViewModel.articlesSavedAmount == 0 &&
                (globalEditCount == 0 || globalEditCount == nil) &&
                shouldShowEmptyState
            
            fetchDataCompleteAction?(fromAppearance)
        }
    }

    // MARK: - Updates

    private func getGlobalEditCount() async {
        guard case .loggedIn = authenticationState else { return }
        do {
            let count = try await dataController.getGlobalEditCount()
            globalEditCount = count
        } catch {
            debugPrint("Error getting global edit count: \(error)")
        }
    }
    
    private func fetchUserImpact() async {
        guard case .loggedIn = authenticationState else { return }
        guard let userID else { return }
        do {
            let response = try await dataController.getUserImpactData(userID: userID)
            print(response)
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

    public func updateID(userID: Int?) {
        self.userID = userID
    }

    private static func generateEmptyViewModel(localizedStrings: LocalizedStrings, isLoggedIn: Bool) -> WMFEmptyViewModel {
        let emptyLocalizedStrings = WMFEmptyViewModel.LocalizedStrings(
            title: isLoggedIn ? localizedStrings.emptyViewTitleLoggedIn : localizedStrings.emptyViewTitleLoggedOut,
            subtitle: isLoggedIn ? localizedStrings.emptyViewSubtitleLoggedIn : localizedStrings.emptyViewSubtitleLoggedOut,
            titleFilter: nil,
            buttonTitle: nil,
            attributedFilterString: nil)
        
        return WMFEmptyViewModel(
            localizedStrings: emptyLocalizedStrings,
            image: UIImage(named: "empty-activity", in: .module, with: nil),
            imageColor: nil,
            numberOfFilters: 0)
    }
    
    public func updateAuthenticationState(authState: LoginState) {
        self.authenticationState = authState
        Task {
            await self.updateShouldShowLoginPrompt()
        }
        self.emptyViewModel = Self.generateEmptyViewModel(localizedStrings: localizedStrings, isLoggedIn: authState == .loggedIn)
        if self.authenticationState != .loggedIn {
            globalEditCount = nil
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
        
        switch authenticationState {
        case .loggedOut:
            await dataController.setLoggedOutUserHasDismissedActivityTabLogInPrompt(true)
        case .temp:
            await dataController.setTempAccountUserHasDismissedActivityTabLogInPrompt(true)
        case .loggedIn:
            break
        }
    }
    
    var shouldShowEmptyState: Bool {
        return self.sections.count == 1 && (self.sections.first?.items.isEmpty ?? true)
    }
}
