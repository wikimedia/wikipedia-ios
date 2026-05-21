import SwiftUI

@MainActor
public final class WMFWhichCameFirstShareViewModel: ObservableObject {

    // MARK: - Nested Types

    struct QuestionResult {
        let isCorrect: Bool
    }

    // MARK: - Properties

    let score: Int
    let totalQuestions: Int
    let questionResults: [QuestionResult]
    let articleTitles: [String]
    let projectID: String

    // MARK: - Init

    public init(score: Int, totalQuestions: Int, questionResults: [Bool], articleTitles: [String], projectID: String) {
        self.score = score
        self.totalQuestions = totalQuestions
        self.questionResults = questionResults.map { QuestionResult(isCorrect: $0) }
        self.articleTitles = articleTitles
        self.projectID = projectID
    }
}
