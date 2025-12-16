import WMFData
import SwiftUI

@MainActor
final class MostViewedArticlesViewModel: ObservableObject {
    let titles: [String]
    
    init(response: WMFUserImpactDataController.APIResponse) {
        self.titles = Array(response.topViewedArticles.sorted { $0.viewsCount > $1.viewsCount }.prefix(3)).map { $0.title }
    }
}
