import WMFData
import SwiftUI


@MainActor
public final class ArticlesSavedViewModel: ObservableObject {
    @Published public var articlesSavedAmount: Int = 0
    @Published public var dateTimeLastSaved: String = ""
    @Published public var articlesSavedImages: [URL] = []

    private var dataController: WMFActivityTabDataController
    private let formatDateTime: (Date) -> String
    private let calendar: Calendar

    public init(
        dataController: WMFActivityTabDataController = .shared,
        formatDateTime: @escaping (Date) -> String,
        calendar: Calendar = .current
    ) {
        self.dataController = dataController
        self.formatDateTime = formatDateTime
        self.calendar = calendar
    }

    public func fetch(daysLookback: Int = 30) async {
        Task { [weak self] in
            guard let self else { return }
            let end = Date()
            let start = calendar.date(byAdding: .day, value: -daysLookback, to: end) ?? end

            if let data = await dataController.getSavedArticleModuleData(from: start, to: end) {
                
                self.articlesSavedAmount = data.savedArticlesCount
                self.dateTimeLastSaved = data.dateLastSaved.map(self.formatDateTime) ?? ""
                self.articlesSavedImages = data.articleUrlStrings.compactMap(URL.init(string:))
            }
        }
    }
}
