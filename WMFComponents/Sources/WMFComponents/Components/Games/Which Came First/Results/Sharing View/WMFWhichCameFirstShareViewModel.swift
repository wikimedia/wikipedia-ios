import SwiftUI
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFWhichCameFirstShareViewModel: ObservableObject {

    // MARK: - Nested Types

    struct QuestionResult {
        let isCorrect: Bool
    }

    public struct ArticleItem {
        public let title: String
        public let description: String?
        public let image: UIImage?

        public init(title: String, description: String? = nil, image: UIImage? = nil) {
            self.title = title
            self.description = description
            self.image = image
        }
    }

    // MARK: - Properties

    let score: Int
    let totalQuestions: Int
    let questionResults: [QuestionResult]
    let articles: [ArticleItem]

    // MARK: - Localized Strings

    let topicsIncludedTitle: String = WMFLocalizedString(
        "which-came-first-share-topics-title",
        value: "Topics included:",
        comment: "Header label above the list of article topics on the Which Came First share image."
    )

    var scoreSummaryText: String {
        let format = WMFLocalizedString(
            "which-came-first-share-score-summary",
            value: "I scored %1$d/%2$d on \"Which came first?\" today.",
            comment: "Score summary text on the Which Came First share image. %1$d is the user's score, %2$d is the total number of questions."
        )
        guard format.contains("%") else {
            return "I scored \(score)/\(totalQuestions) on \u{201C}Which came first?\u{201D} today."
        }
        return String(format: format, score, totalQuestions)
    }

    // MARK: - Init

    public init(score: Int, totalQuestions: Int, questionResults: [Bool], articles: [ArticleItem]) {
        self.score = score
        self.totalQuestions = totalQuestions
        self.questionResults = questionResults.map { QuestionResult(isCorrect: $0) }
        self.articles = articles
    }
}
