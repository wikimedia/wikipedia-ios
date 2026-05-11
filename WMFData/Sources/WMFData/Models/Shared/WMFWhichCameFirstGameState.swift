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
    public let year: Int
    public let articleTitle: String?
    public let thumbnailURL: URL?

    public init(title: String, year: Int, articleTitle: String? = nil, thumbnailURL: URL? = nil) {
        self.title = title
        self.year = year
        self.articleTitle = articleTitle
        self.thumbnailURL = thumbnailURL
    }
}
