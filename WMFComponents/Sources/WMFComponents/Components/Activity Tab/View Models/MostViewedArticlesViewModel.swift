import WMFData
import SwiftUI

@MainActor
final class MostViewedArticlesViewModel: ObservableObject {
    let topViewedArticles: [WMFUserImpactData.TopViewedArticle]
    
    init?(data: WMFUserImpactData) {
        let topViewedArticles = Array(data.topViewedArticles.prefix(3))
        guard !topViewedArticles.isEmpty else {
            return nil
        }
        
        self.topViewedArticles = topViewedArticles
    }
}
