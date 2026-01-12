import WMFData
import SwiftUI

@MainActor
public final class MostViewedArticlesViewModel: ObservableObject {
    let topViewedArticles: [WMFUserImpactData.TopViewedArticle]
    
    public init?(data: WMFUserImpactData) {
        let topViewedArticles = Array(data.topViewedArticles.prefix(3))
        guard !topViewedArticles.isEmpty else {
            return nil
        }
        
        self.topViewedArticles = topViewedArticles
    }
}
