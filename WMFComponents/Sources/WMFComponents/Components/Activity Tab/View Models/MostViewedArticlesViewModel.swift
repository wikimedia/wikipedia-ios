import WMFData
import SwiftUI

@MainActor
final class MostViewedArticlesViewModel: ObservableObject {
    let topViewedArticles: [WMFUserImpactData.TopViewedArticle]
    
    init(data: WMFUserImpactData) {
        self.topViewedArticles = Array(data.topViewedArticles.prefix(3))
    }
}
