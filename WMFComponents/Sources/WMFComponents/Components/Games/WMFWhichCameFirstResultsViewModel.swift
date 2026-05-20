import Combine
import Foundation
import SwiftUI

@MainActor
public final class WMFWhichCameFirstResultsViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let shareScoreButton: String
        public let nextGameCountdown: String
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
            shareScoreButton: String = "Share score",
            nextGameCountdown: String = "Next game in 08:24:15",
            playArchiveButton: String = "Play the archive",
            yourStatsTitle: String = "Your stats",
            gamesPlayedLabel: String = "games played",
            currentStreakLabel: String = "current streak",
            bestStreakLabel: String = "best streak",
            averageScoreLabel: String = "average score",
            logInToViewStatsTitle: String = "Log in to view your game stats",
            logInToViewStatsBody: String = "See your streaks, scores, and more",
            logInButton: String = "Log in",
            articlesReferencedTitle: String = "Articles referenced in today's game"
        ) {
            self.shareScoreButton = shareScoreButton
            self.nextGameCountdown = nextGameCountdown
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
    public var onOpenArticle: ((WMFWhichCameFirstResultsArticle) -> Void)?

    public init(
        score: Int,
        totalQuestions: Int,
        isLoggedIn: Bool,
        gamesPlayed: Int? = nil,
        currentStreak: Int? = nil,
        bestStreak: Int? = nil,
        averageScore: Int? = nil,
        referencedArticles: [WMFWhichCameFirstResultsArticle] = [],
        nextGameCountdownString: String = "08:24:15",
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
        self.nextGameCountdownString = nextGameCountdownString
        self.localizedStrings = localizedStrings
    }

    func shareScore() { onShareScore?() }
    func playArchive() { onPlayArchive?() }
    func logIn() { onLogIn?() }
    func openArticle(_ article: WMFWhichCameFirstResultsArticle) { onOpenArticle?(article) }
}
