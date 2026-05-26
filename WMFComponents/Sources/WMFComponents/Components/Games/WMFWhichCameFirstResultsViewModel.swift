import Combine
import Foundation
import SwiftUI
import WMFNativeLocalizations
import WMFData

@MainActor
public final class WMFWhichCameFirstResultsViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let shareScoreButton: String
        public let playArchiveButton: String
        public let yourStatsTitle: String
        public let gamesPlayedLabel: String
        public let currentStreakLabel: String
        public let bestStreakLabel: String
        public let averageScoreLabel: String
        public let logInToViewStatsTitle: String
        public let logInToViewStatsBody: String
        public let logInButton: String
        public let articlesReferencedTitle: String

        public init(
            shareScoreButton: String = WMFLocalizedString("which-came-first-share-score-button", value: "Share score", comment: "Button to share the user's score in the Which Came First game"),
            playArchiveButton: String = WMFLocalizedString("which-came-first-play-archive-button", value: "Play the archive", comment: "Button to play archived games in the Which Came First game"),
            yourStatsTitle: String = WMFLocalizedString("which-came-first-your-stats-title", value: "Your stats", comment: "Section title for the user's stats in the Which Came First results screen"),
            gamesPlayedLabel: String = WMFLocalizedString("which-came-first-games-played-label", value: "games played", comment: "Label for the games played stat in the Which Came First results screen"),
            currentStreakLabel: String = WMFLocalizedString("which-came-first-current-streak-label", value: "current streak", comment: "Label for the current streak stat in the Which Came First results screen"),
            bestStreakLabel: String = WMFLocalizedString("which-came-first-best-streak-label", value: "best streak", comment: "Label for the best streak stat in the Which Came First results screen"),
            averageScoreLabel: String = WMFLocalizedString("which-came-first-average-score-label", value: "average score", comment: "Label for the average score stat in the Which Came First results screen"),
            logInToViewStatsTitle: String = WMFLocalizedString("which-came-first-log-in-stats-title", value: "Log in to view your game stats", comment: "Title prompting the user to log in to view stats in the Which Came First results screen"),
            logInToViewStatsBody: String = WMFLocalizedString("which-came-first-log-in-stats-body", value: "See your streaks, scores, and more", comment: "Body text prompting the user to log in to view stats in the Which Came First results screen"),
            logInButton: String = WMFLocalizedString("which-came-first-log-in-button", value: "Log in", comment: "Button to log in from the Which Came First results screen"),
            articlesReferencedTitle: String = WMFLocalizedString("which-came-first-articles-referenced-title", value: "Articles referenced in today's game", comment: "Section title for articles referenced in the Which Came First game results screen")
        ) {
            self.shareScoreButton = shareScoreButton
            self.playArchiveButton = playArchiveButton
            self.yourStatsTitle = yourStatsTitle
            self.gamesPlayedLabel = gamesPlayedLabel
            self.currentStreakLabel = currentStreakLabel
            self.bestStreakLabel = bestStreakLabel
            self.averageScoreLabel = averageScoreLabel
            self.logInToViewStatsTitle = logInToViewStatsTitle
            self.logInToViewStatsBody = logInToViewStatsBody
            self.logInButton = logInButton
            self.articlesReferencedTitle = articlesReferencedTitle
        }

        func scoredLabel(_ score: Int, of total: Int) -> String {
            "You scored \(score)/\(total)."
        }

        public func scoreLabel(_ score: Int, of total: Int) -> String {
            let format = WMFLocalizedString("which-came-first-score", value: "You scored %1$d/%2$d.", comment: "Score label, where $1 is score and $2 is the total number of questions")
            return String.localizedStringWithFormat(format, score, total)
        }

        public func countdownLabel(from countdownString: String) -> String {
            let descriptionText = WMFLocalizedString("which-came-frst-next-game-time", value: "Next game in %1$@", comment: "Indication of when new game is available. %1$d is replaced by a countdown timer string, indicating the number of hours / minutes / seconds left until the next game is available.")
            return String.localizedStringWithFormat(descriptionText, countdownString)
        }
    }

    @Published public var score: Int
    @Published public var totalQuestions: Int
    @Published public var isLoggedIn: Bool
    @Published public var gamesPlayed: Int?
    @Published public var currentStreak: Int?
    @Published public var bestStreak: Int?
    @Published public var averageScore: Int?
    @Published public var referencedArticles: [WMFWhichCameFirstResultsArticle]
    @Published public var nextGameCountdownString: String

    public var localizedStrings: LocalizedStrings
    public var onShareScore: (() -> Void)?
    public var onPlayArchive: (() -> Void)?
    public var onLogIn: (() -> Void)?
    public var shareScore: (() -> Void)?
    public var onOpenArticle: ((WMFWhichCameFirstResultsArticle) -> Void)?

    private var timerCancellable: AnyCancellable?

    public init(
        score: Int,
        totalQuestions: Int,
        isLoggedIn: Bool,
        project: WMFProject,
        gamesPlayed: Int? = nil,
        currentStreak: Int? = nil,
        bestStreak: Int? = nil,
        averageScore: Int? = nil,
        shareScore: (() -> Void)? = nil,
        onLogIn: (() -> Void)? = nil,
        referencedArticles: [WMFWhichCameFirstResultsArticle] = [],
        localizedStrings: LocalizedStrings = LocalizedStrings()
    ) {
        self.score = score
        self.totalQuestions = totalQuestions
        self.isLoggedIn = isLoggedIn
        self.gamesPlayed = gamesPlayed
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.averageScore = averageScore
        self.referencedArticles = referencedArticles
        self.nextGameCountdownString = Self.computeCountdown()
        self.localizedStrings = localizedStrings
        self.shareScore = shareScore
        self.onLogIn = onLogIn
        startCountdownTimer()
        fetchStats(project: project)
    }

    private func fetchStats(project: WMFProject) {
        let dataController = WMFGamesDataController()
        Task { [weak self] in
            guard let self else { return }
            guard let stats = try? await dataController.fetchWhichCameFirstStats(project: project) else { return }
            self.gamesPlayed = stats.gamesPlayed
            self.currentStreak = stats.currentStreak > 1 ? stats.currentStreak : nil
            self.bestStreak = stats.bestStreak > 1 ? stats.bestStreak : nil
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

    // MARK: - Actions

    func playArchive() { onPlayArchive?() }
    func openArticle(_ article: WMFWhichCameFirstResultsArticle) { onOpenArticle?(article) }
}
