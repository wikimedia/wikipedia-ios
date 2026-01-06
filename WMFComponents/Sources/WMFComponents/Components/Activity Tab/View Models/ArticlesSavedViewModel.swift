import WMFData
import SwiftUI

@MainActor
public final class ArticlesSavedViewModel: ObservableObject {
    @Published public var articlesSavedAmount: Int = 0
    @Published public var dateTimeLastSaved: String = ""
    @Published public var articlesSavedThumbURLs: [URL?] = []
    @Published public var articleTitles: [String] = []
    public var onTapSaved: (() -> Void)?

    private var dataController: WMFSavedArticlesDataController
    private let dateFormatter: (Date) -> String
    private let calendar: Calendar

    public init(
        dataController: WMFSavedArticlesDataController = .shared,
        dateFormatter: @escaping (Date) -> String,
        calendar: Calendar = .current
    ) {
        self.dataController = dataController
        self.dateFormatter = dateFormatter
        self.calendar = calendar
    }

    public func fetch(daysLookback: Int = 30) async {
        Task { [weak self] in
            guard let self else { return }
            let end = Date()
            let start = calendar.date(byAdding: .day, value: -daysLookback, to: end) ?? end

            if let data = await dataController.getSavedArticleModuleData(from: start, to: end) {
                
                self.articlesSavedAmount = data.savedArticlesCount
                self.dateTimeLastSaved = data.dateLastSaved.map(self.dateFormatter) ?? ""
                self.articlesSavedThumbURLs = data.articleThumbURLs
                self.articleTitles = data.articleTitles
            }
        }
    }
}
