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
    public var presentCustomizeLogInToastAction: (() -> Void)? {
        didSet {
            self.customizeViewModel.presentLoggedInToastAction = self.presentCustomizeLogInToastAction
        }
    }
    public var onTapArticle: ((URL) -> Void)?

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
        public let totalEditsAcrossProjects: String
        public let read: String
        public let edited: String
        public let saved: String
        public let emptyViewTitleLoggedIn: String
        public let emptyViewSubtitleLoggedIn: String
        public let emptyViewTitleLoggedOut: String
        public let emptyViewSubtitleLoggedOut: String
        public let customizeTimeSpentReading: String
        public let customizeReadingInsights: String
        public let customizeEditingInsights: String
        public let customizeAllTimeImpact: String
        public let customizeLastInAppDonation: String
        public let customizeTimelineOfBehavior: String
        public let customizeFooter: String
        public let customizeEmptyState: String
        public let viewChanges: String
        public let contributionsThisMonth: String
        public let thisMonth: String
        public let lastMonth: String
        public let lookingForSomethingNew: String
        public let exploreWikipedia: String
        public let zeroEditsToArticles: String
        public let looksLikeYouHaventMadeAnEdit: String
        public let makeAnEdit: String
        public let viewsString: (Int) -> String
        public let mostViewed: String
        public let allTimeImpactTitle: String
        public let totalEditsLabel: String
        public let bestStreakValue: (Int) -> String
        public let bestStreakLabel: String
        public let thanksLabel: String
        public let lastEditedLabel: String
        public let yourRecentActivityTitle: String
        public let editsLabel: String
        public let startEndDatesAccessibilityLabel: (String, String) -> String
        public let viewsOnArticlesYouveEditedTitle: String
        public let lineGraphDay: String
        public let lineGraphViews: String
        
        public init(userNamesReading: @escaping (String) -> String, noUsernameReading: String, totalHoursMinutesRead: @escaping (Int, Int) -> String, onWikipediaiOS: String, timeSpentReading: String, totalArticlesRead: String, week: String, articlesRead: String, topCategories: String, articlesSavedTitle: String, remaining: @escaping (Int) -> String, loggedOutTitle: String, loggedOutSubtitle: String, loggedOutPrimaryCTA: String, yourImpact: String, todayTitle: String, yesterdayTitle: String, openArticle: String, deleteAccessibilityLabel: String, totalEditsAcrossProjects: String, read: String, edited: String, saved: String, emptyViewTitleLoggedIn: String, emptyViewSubtitleLoggedIn: String, emptyViewTitleLoggedOut: String, emptyViewSubtitleLoggedOut: String, customizeTimeSpentReading: String, customizeReadingInsights: String, customizeEditingInsights: String, customizeAllTimeImpact: String, customizeLastInAppDonation: String, customizeTimelineOfBehavior: String, customizeFooter: String, customizeEmptyState: String, viewChanges: String, contributionsThisMonth: String, thisMonth: String, lastMonth: String, lookingForSomethingNew: String, exploreWikipedia: String, zeroEditsToArticles: String, looksLikeYouHaventMadeAnEdit: String, makeAnEdit: String, viewsString: @escaping (Int) -> String, mostViewed: String, allTimeImpactTitle: String, totalEditsLabel: String, bestStreakValue: @escaping (Int) -> String, bestStreakLabel: String, thanksLabel: String, lastEditedLabel: String, yourRecentActivityTitle: String, editsLabel: String, startEndDatesAccessibilityLabel: @escaping (String, String) -> String, viewsOnArticlesYouveEditedTitle: String, lineGraphDay: String, lineGraphViews: String) {
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
            self.totalEditsAcrossProjects = totalEditsAcrossProjects
            self.read = read
            self.edited = edited
            self.saved = saved
            self.emptyViewTitleLoggedIn = emptyViewTitleLoggedIn
            self.emptyViewSubtitleLoggedIn = emptyViewSubtitleLoggedIn
            self.emptyViewTitleLoggedOut = emptyViewTitleLoggedOut
            self.emptyViewSubtitleLoggedOut = emptyViewSubtitleLoggedOut
            self.customizeTimeSpentReading = customizeTimeSpentReading
            self.customizeReadingInsights = customizeReadingInsights
            self.customizeEditingInsights = customizeEditingInsights
            self.customizeAllTimeImpact = customizeAllTimeImpact
            self.customizeLastInAppDonation = customizeLastInAppDonation
            self.customizeTimelineOfBehavior = customizeTimelineOfBehavior
            self.customizeFooter = customizeFooter
            self.customizeEmptyState = customizeEmptyState
            self.viewChanges = viewChanges
            self.contributionsThisMonth = contributionsThisMonth
            self.thisMonth = thisMonth
            self.lastMonth = lastMonth
            self.lookingForSomethingNew = lookingForSomethingNew
            self.exploreWikipedia = exploreWikipedia
            self.zeroEditsToArticles = zeroEditsToArticles
            self.looksLikeYouHaventMadeAnEdit = looksLikeYouHaventMadeAnEdit
            self.makeAnEdit = makeAnEdit
            self.viewsString = viewsString
            self.mostViewed = mostViewed
            self.allTimeImpactTitle = allTimeImpactTitle
            self.totalEditsLabel = totalEditsLabel
            self.bestStreakValue = bestStreakValue
            self.bestStreakLabel = bestStreakLabel
            self.thanksLabel = thanksLabel
            self.lastEditedLabel = lastEditedLabel
            self.yourRecentActivityTitle = yourRecentActivityTitle
            self.editsLabel = editsLabel
            self.startEndDatesAccessibilityLabel = startEndDatesAccessibilityLabel
            self.viewsOnArticlesYouveEditedTitle = viewsOnArticlesYouveEditedTitle
            self.lineGraphDay = lineGraphDay
            self.lineGraphViews = lineGraphViews
        }
    }

    public let localizedStrings: LocalizedStrings
    var userID: Int?

    // MARK: - Published State

    @Published public var authenticationState: LoginState
    @Published public var articlesReadViewModel: ArticlesReadViewModel
    @Published public var articlesSavedViewModel: ArticlesSavedViewModel
    
    var yourImpactOnWikipediaSubtitle: String?
    @Published var mostViewedArticlesViewModel: MostViewedArticlesViewModel?
    @Published var contributionsViewModel: ContributionsViewModel?
    @Published var allTimeImpactViewModel: AllTimeImpactViewModel?
    @Published var recentActivityViewModel: RecentActivityViewModel?
    @Published var articleViewsViewModel: ArticleViewsViewModel?
    @Published public var timelineViewModel: TimelineViewModel
    @Published public var emptyViewModel: WMFEmptyViewModel
    @Published public var customizeViewModel: WMFActivityTabCustomizeViewModel
    @Published var sections: [TimelineViewModel.TimelineSection] = [] {
        didSet {
            recomputeShouldShowEmptyState()
        }
    }

    @Published private(set) var shouldShowEmptyState: Bool = false
    @Published public var shouldShowExploreCTA: Bool = false

    @Published var globalEditCount: Int?
    @Published public var isLoading: Bool = false
    public var isEmpty: Bool = false
    public var onTapGlobalEdits: (() -> Void)?
    public var fetchDataCompleteAction: ((Bool) -> Void)?
    public var openCustomize: () -> Void = { }
    public var getURL: ((WMFUserImpactData.TopViewedArticle, WMFProject) -> URL?)?
    public var exploreWikipedia: () -> Void = { }
    public var makeAnEdit: () -> Void = { }
    public var isExploreFeedOn: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    private var isFirstTimeLoading: Bool = true
    
    var shouldShowYourImpactHeader: Bool {
        return mostViewedArticlesViewModel != nil ||
            contributionsViewModel != nil ||
            allTimeImpactViewModel != nil ||
            recentActivityViewModel != nil ||
            articleViewsViewModel != nil ||
            (globalEditCount != nil && (globalEditCount ?? 0) > 0)
    }

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
        
        let customizeViewModel = WMFActivityTabCustomizeViewModel(localizedStrings: WMFActivityTabCustomizeViewModel.LocalizedStrings(timeSpentReading: localizedStrings.customizeTimeSpentReading, readingInsights: localizedStrings.customizeReadingInsights, editingInsights: localizedStrings.customizeEditingInsights, allTimeImpact: localizedStrings.customizeAllTimeImpact, lastInAppDonation: localizedStrings.customizeLastInAppDonation, timeline: localizedStrings.customizeTimelineOfBehavior, footer: localizedStrings.customizeFooter), isLoggedIn: authenticationState == .loggedIn)
        self.customizeViewModel = customizeViewModel
        
        // Unfortunately this part is needed for SwiftUI view to see changes in binding. Alternative is to have the toggle booleans live here within WMFActivityTabViewModel
        customizeViewModel.objectWillChange
                    .sink { [weak self] _ in
                        self?.objectWillChange.send()
                    }
                    .store(in: &cancellables)
        
        self.timelineViewModel.activityTabViewModel = self
    }

    // MARK: - Loading

    public func fetchData(fromAppearance: Bool = false) {
        Task { @MainActor in
            if isFirstTimeLoading {
                isLoading = true
            }
            let start = ContinuousClock.now

            async let readTask: Void = articlesReadViewModel.fetch()
            async let savedTask: Void = articlesSavedViewModel.fetch()
            async let timelineTask: Void = timelineViewModel.fetch()
            async let editCountTask: Void = getGlobalEditCount()
            async let userImpactTask: Void = fetchUserImpact()

            _ = await (readTask, savedTask, timelineTask, editCountTask, userImpactTask)

            self.articlesReadViewModel = articlesReadViewModel
            self.articlesSavedViewModel = articlesSavedViewModel
            self.timelineViewModel = timelineViewModel
            self.globalEditCount = globalEditCount
            
            shouldShowExploreCTA = articlesReadViewModel.totalArticlesRead == 0 &&
                                   articlesSavedViewModel.articlesSavedAmount == 0 &&
                                   isExploreFeedOn
            
            isEmpty =
                articlesReadViewModel.hoursRead == 0 &&
                articlesReadViewModel.minutesRead == 0 &&
                articlesSavedViewModel.articlesSavedAmount == 0 &&
                (globalEditCount == 0 || globalEditCount == nil) &&
                shouldShowEmptyState

            // Minimum 500ms, parity with Android
            let elapsed = start.duration(to: .now)
            let minimum = Duration.milliseconds(500)

            if elapsed < minimum {
                try? await Task.sleep(for: minimum - elapsed)
            }

            isLoading = false
            isFirstTimeLoading = false
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
            globalEditCount = nil
        }
    }

    private func fetchUserImpact() async {
        guard case .loggedIn = authenticationState else { return }
        guard let userID else { return }
        do {
            let data = try await dataController.getUserImpactData(userID: userID)
            if let getURL = getURL {
                // Only recreate if data has actually changed
                if let existing = self.mostViewedArticlesViewModel,
                   existing.hasSameArticles(as: data) {
                    // Keep existing view model
                } else {
                    self.mostViewedArticlesViewModel = MostViewedArticlesViewModel(data: data, getURL: getURL)
                }
            }
            self.contributionsViewModel = ContributionsViewModel(data: data, activityViewModel: self)
            self.allTimeImpactViewModel = AllTimeImpactViewModel(data: data, activityViewModel: self)
            self.recentActivityViewModel = RecentActivityViewModel(data: data, activityViewModel: self)
            self.articleViewsViewModel = ArticleViewsViewModel(data: data, activityViewModel: self)
        } catch {
            debugPrint("Error getting user impact: \(error)")
            self.mostViewedArticlesViewModel = nil
            self.contributionsViewModel = nil
            self.allTimeImpactViewModel = nil
            self.recentActivityViewModel = nil
            self.articleViewsViewModel = nil
        }
    }

    public func updateUsername(username: String?) {
        let resolvedUsername = username ?? ""
        articlesReadViewModel.username = resolvedUsername
        articlesReadViewModel.usernamesReading = resolvedUsername.isEmpty
            ? localizedStrings.noUsernameReading
            : localizedStrings.userNamesReading(resolvedUsername)
    }

    public func updateID(userID: Int?) {
        self.userID = userID
    }
    
    public func updateYourImpactOnWikipediaSubtitle(_ subtitle: String?) {
        self.yourImpactOnWikipediaSubtitle = subtitle
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
    
    public func updateAuthenticationState(authState: LoginState, needsRefetch: Bool) {
        isLoading = true
        
        self.authenticationState = authState
        self.emptyViewModel = Self.generateEmptyViewModel(localizedStrings: localizedStrings, isLoggedIn: authState == .loggedIn)
        self.customizeViewModel.isLoggedIn = authState == .loggedIn
        
        if self.authenticationState != .loggedIn {
            updateUsername(username: nil)
            timelineViewModel.setUser(username: nil)
            globalEditCount = nil
            mostViewedArticlesViewModel = nil
            contributionsViewModel = nil
            allTimeImpactViewModel = nil
            recentActivityViewModel = nil
            articleViewsViewModel = nil
            Task {
                await timelineViewModel.fetch()
                recomputeShouldShowEmptyState()
                isLoading = false
            }
        } else if needsRefetch {
            // re-fetch anything that might change based on login state
            Task {
                
                // first reset things
                globalEditCount = nil
                mostViewedArticlesViewModel = nil
                contributionsViewModel = nil
                allTimeImpactViewModel = nil
                recentActivityViewModel = nil
                articleViewsViewModel = nil
                
                await timelineViewModel.fetch()
                await getGlobalEditCount()
                await fetchUserImpact()
                recomputeShouldShowEmptyState()
                isLoading = false
            }
        } else {
            isLoading = false
        }
    }

    public var hoursMinutesRead: String {
        localizedStrings.totalHoursMinutesRead(
            articlesReadViewModel.hoursRead,
            articlesReadViewModel.minutesRead
        )
    }

    // MARK: - Helpers
    public var pushToContributions: (() -> Void)?
    
    public func navigateToContributions() {
        pushToContributions?()
    }
    
    private func recomputeShouldShowEmptyState() {
        switch authenticationState {
        case .loggedIn:
            if sections.count == 1, let section = sections.first {
                shouldShowEmptyState = section.items.isEmpty
            } else {
                shouldShowEmptyState = false
            }
        case .loggedOut, .temp:
            if sections.count == 0 {
                shouldShowEmptyState = true
            } else {
                let hasReadItem = sections.contains { section in
                    section.items.contains { $0.itemType == .read }
                }
                shouldShowEmptyState = !hasReadItem
            }
        }
    }

    func formatDateTime(_ dateTime: Date) -> String {
        DateFormatter.wmfLastReadFormatter(for: dateTime)
    }

    func formatDate(_ dateTime: Date) -> String {
        DateFormatter.wmfMonthDayYearDateFormatter.string(from: dateTime)
    }
}
