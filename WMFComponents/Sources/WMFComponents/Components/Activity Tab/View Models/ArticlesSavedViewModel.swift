import WMFData
import SwiftUI

public class SavedArticleModuleData: NSObject, Codable {
    public let savedArticlesCount: Int
    public let articleUrlStrings: [String]
    public let dateLastSaved: Date?

    public init(savedArticlesCount: Int, articleUrlStrings: [String], dateLastSaved: Date?) {
        self.savedArticlesCount = savedArticlesCount
        self.articleUrlStrings = articleUrlStrings
        self.dateLastSaved = dateLastSaved
    }
}

public protocol SavedArticleModuleDataDelegate: AnyObject {
    func getSavedArticleModuleData(from startDate: Date, to endDate: Date) async -> SavedArticleModuleData
}

@MainActor
public final class ArticlesSavedViewModel: ObservableObject {
    @Published public var articlesSavedAmount: Int = 0
    @Published public var dateTimeLastSaved: String = ""
    @Published public var articlesSavedImages: [URL] = []

    private weak var delegate: SavedArticleModuleDataDelegate?
    private let formatDateTime: (Date) -> String
    private let calendar: Calendar

    public init(
        delegate: SavedArticleModuleDataDelegate?,
        formatDateTime: @escaping (Date) -> String,
        calendar: Calendar = .current
    ) {
        self.delegate = delegate
        self.formatDateTime = formatDateTime
        self.calendar = calendar
    }

    public func fetch(daysLookback: Int = 30) async {
        Task { [weak self] in
            guard let self else { return }
            let end = Date()
            let start = calendar.date(byAdding: .day, value: -daysLookback, to: end) ?? end

            guard let d = delegate else {
                self.articlesSavedAmount = 0
                self.dateTimeLastSaved = ""
                self.articlesSavedImages = []
                return
            }

            let data = await d.getSavedArticleModuleData(from: start, to: end)

            self.articlesSavedAmount = data.savedArticlesCount
            self.dateTimeLastSaved = data.dateLastSaved.map(self.formatDateTime) ?? ""
            self.articlesSavedImages = data.articleUrlStrings.compactMap(URL.init(string:))
        }
    }
}
