import Foundation

public struct WMFWhichCameFirstGameState: Codable, Sendable {
    public let questions: [WMFWhichCameFirstQuestion]
    public var answers: [String: String] // questionID (UUID string) → "A" or "B"; absent key = unanswered

    public init(questions: [WMFWhichCameFirstQuestion], answers: [String: String] = [:]) {
        self.questions = questions
        self.answers = answers
    }
}

public struct WMFWhichCameFirstQuestion: Codable, Sendable {
    public let id: UUID
    public let optionA: WMFWhichCameFirstEvent
    public let optionB: WMFWhichCameFirstEvent
    public let correctAnswer: String // "A" or "B"

    public init(id: UUID = UUID(), optionA: WMFWhichCameFirstEvent, optionB: WMFWhichCameFirstEvent, correctAnswer: String) {
        self.id = id
        self.optionA = optionA
        self.optionB = optionB
        self.correctAnswer = correctAnswer
    }
}

public struct WMFWhichCameFirstEvent: Codable, Sendable {
    public let title: String
    public let date: Date
    public let articleTitle: String?
    public let thumbnailURL: URL?

    public init(title: String, date: Date, articleTitle: String? = nil, thumbnailURL: URL? = nil) {
        self.title = title
        self.date = date
        self.articleTitle = articleTitle
        self.thumbnailURL = thumbnailURL
    }
}

/// Stored in `WMFContentGroup.contentPreview` so the Explore cell can configure
/// its layout synchronously, including the current session state.
public struct WMFDailyGameContentPreview: Codable, Sendable {
    public enum GameState: Codable, Sendable {
        case notStarted
        case inProgress(questionsAnswered: Int, score: Int)
        case completed(score: Int, totalQuestions: Int)
    }
    public let optionA: WMFWhichCameFirstEvent?
    public let optionB: WMFWhichCameFirstEvent?
    public let state: GameState

    public init(optionA: WMFWhichCameFirstEvent?, optionB: WMFWhichCameFirstEvent?, state: GameState) {
        self.optionA = optionA
        self.optionB = optionB
        self.state = state
    }
}
