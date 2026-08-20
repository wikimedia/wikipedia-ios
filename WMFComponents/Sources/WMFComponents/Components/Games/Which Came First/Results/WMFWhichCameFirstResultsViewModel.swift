import Combine
import Foundation
import SwiftUI
import WMFNativeLocalizations
import WMFData

@MainActor
public final class WMFWhichCameFirstResultsViewModel: ObservableObject {

    let shareScoreButton = WMFLocalizedString("which-came-first-share-score-button", value: "Share score", comment: "Button to share the user's score in the Which Came First game")
    let yourStatsTitle = WMFLocalizedString("which-came-first-your-stats-title", value: "Your stats", comment: "Section title for the user's stats in the Which Came First results screen")
    let gamesPlayedLabel = WMFLocalizedString("which-came-first-games-played-label", value: "games played", comment: "Label for the games played stat in the Which Came First results screen")
    let currentStreakLabel = WMFLocalizedString("which-came-first-current-streak-label", value: "current streak", comment: "Label for the current streak stat in the Which Came First results screen")
    let bestStreakLabel = WMFLocalizedString("which-came-first-best-streak-label", value: "best streak", comment: "Label for the best streak stat in the Which Came First results screen")
    let averageScoreLabel = WMFLocalizedString("which-came-first-average-score-label", value: "average score", comment: "Label for the average score stat in the Which Came First results screen")
    let logInToViewStatsTitle = WMFLocalizedString("which-came-first-log-in-stats-title", value: "Log in to view your game stats", comment: "Title prompting the user to log in to view stats in the Which Came First results screen")
    let logInToViewStatsBody = WMFLocalizedString("which-came-first-log-in-stats-body", value: "See your streaks, scores, and more", comment: "Body text prompting the user to log in to view stats in the Which Came First results screen")
    let logInButton = WMFLocalizedString("which-came-first-log-in-button", value: "Log in", comment: "Button to log in from the Which Came First results screen")
    let playTheArchiveButton = CommonStrings.playTheArchiveTitle

    func scoreLabel(_ score: Int, of total: Int) -> String {
        let format = WMFLocalizedString("which-came-first-score", value: "You scored %1$d/%2$d.", comment: "Score label, where $1 is score and $2 is the total number of questions")
        return String.localizedStringWithFormat(format, score, total)
    }

    func countdownLabel(from countdownString: String) -> String {
        let descriptionText = WMFLocalizedString("which-came-first-next-game-time", value: "Next game in %1$@", comment: "Indication of when new game is available. $1 is replaced by a countdown timer string, indicating the number of hours / minutes / seconds left until the next game is available.")
        return String.localizedStringWithFormat(descriptionText, countdownString)
    }

    @Published public var score: Int
    @Published public var totalQuestions: Int
    @Published public var isLoggedIn: Bool
    @Published public var gamesPlayed: Int?
    @Published public var currentStreak: Int?
    @Published public var bestStreak: Int?
    @Published public var averageScore: Double?
    @Published public var nextGameCountdownString: String

    public let articlesViewModel: WMFWhichCameFirstArticlesViewModel

    public var onLogIn: ( @MainActor @Sendable () -> Void)?
    public var shareScore: ( @MainActor @Sendable () -> Void)?
    public var onPlayArchive: (@MainActor @Sendable () -> Void)?

    // The timer is made and used only on the main actor, thus the property needs no escape from
    // isolation. `nonisolated(unsafe)` let the cancellable be released from an isolated deinit,
    // which crashed the test runner on every construction of this view model.
    private var timerCancellable: AnyCancellable?

    public init(
        score: Int,
        totalQuestions: Int,
        isLoggedIn: Bool,
        project: WMFProject,
        questions: [WMFWhichCameFirstQuestion] = [],
        gamesPlayed: Int? = nil,
        currentStreak: Int? = nil,
        bestStreak: Int? = nil,
        averageScore: Double? = nil,
        shareScore: (@MainActor @Sendable () -> Void)? = nil,
        onLogIn: (@MainActor @Sendable () -> Void)? = nil,
        onArticleTap: WMFWhichCameFirstArticlesViewModel.ArticleTapAction? = nil,
        onArticleOpenInNewTab: WMFWhichCameFirstArticlesViewModel.ArticleTapAction? = nil,
        onArticleOpenInBackgroundTab: WMFWhichCameFirstArticlesViewModel.ArticleTapAction? = nil,
        onArticleSaveForLater: WMFWhichCameFirstArticlesViewModel.ArticleTapAction? = nil,
        onArticleUnsave: WMFWhichCameFirstArticlesViewModel.ArticleTapAction? = nil,
        onCheckSavedState: ((URL) -> Bool)? = nil,
        onArticleShare: WMFWhichCameFirstArticlesViewModel.ArticleShareAction? = nil,
        onPlayArchive: (@MainActor @Sendable () -> Void)? = nil,
        onArticleTapToEvent: WMFWhichCameFirstArticlesViewModel.ArticleEventTapAction? = nil,
    ) {
        self.score = score
        self.totalQuestions = totalQuestions
        self.isLoggedIn = isLoggedIn
        self.gamesPlayed = gamesPlayed
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.averageScore = averageScore
        self.nextGameCountdownString = Self.computeCountdown()
        self.shareScore = shareScore
        self.onLogIn = onLogIn
        self.onPlayArchive = onPlayArchive

        var seen = Set<String>()
        var items: [WMFWhichCameFirstArticleItemViewModel] = []
        for question in questions {
            for event in [question.optionA, question.optionB] {
                let apiTitle = event.articleTitle ?? event.title
                guard seen.insert(apiTitle).inserted else { continue }
                let articleURL: URL? = {
                    guard let siteURL = project.siteURL else { return nil }
                    var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false)
                    components?.path = "/wiki/\(apiTitle)"
                    return components?.url
                }()
                // Use the human-readable article title (spaces, not underscores) for display
                let displayTitle = apiTitle.underscoresToSpaces
                items.append(WMFWhichCameFirstArticleItemViewModel(
                    title: displayTitle,
                    apiTitle: apiTitle,
                    project: project,
                    articleURL: articleURL,
                    thumbnailURL: event.thumbnailURL
                ))
            }
        }
        self.articlesViewModel = WMFWhichCameFirstArticlesViewModel(
            articleItems: items,
            onCheckSavedState: onCheckSavedState,
            didTapArticle: onArticleTap,
            didTapOpenInNewTab: onArticleOpenInNewTab,
            didTapOpenInBackgroundTab: onArticleOpenInBackgroundTab,
            didSaveForLater: onArticleSaveForLater,
            didUnsaveArticle: onArticleUnsave,
            didShareArticle: onArticleShare,
            didTapArticleToEvent: onArticleTapToEvent
        )

        startCountdownTimer()
        fetchStats(project: project)
    }

    private func fetchStats(project: WMFProject) {
        let dataController = WMFGamesDataController()
        Task { [weak self] in
            guard let self else { return }
            guard let stats = try? await dataController.fetchWhichCameFirstStats(project: project) else { return }
            self.gamesPlayed = stats.gamesPlayed
            self.currentStreak = stats.currentStreak > 0 ? stats.currentStreak : nil
            self.bestStreak = stats.bestStreak > 0 ? stats.bestStreak : nil
            self.averageScore = stats.averageScore
        }
    }

    // MARK: - Countdown

    private func startCountdownTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.nextGameCountdownString = Self.computeCountdown()
            }
    }

    private static func computeCountdown() -> String {
        let now = Date()
        guard let tomorrow = Calendar.current.date(
            byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: now)
        ) else { return "--:--:--" }
        let seconds = max(0, Int(tomorrow.timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}
