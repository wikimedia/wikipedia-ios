import WMFData
import SwiftUI

@MainActor
public final class MostViewedArticlesViewModel: ObservableObject {

    public let topViewedArticles: [WMFUserImpactData.TopViewedArticle]
    public let project: WMFProject
    public let projectID: String

    private let getURL: (WMFUserImpactData.TopViewedArticle, WMFProject) -> URL?

    public init?(
        data: WMFUserImpactData,
        getURL: @escaping (WMFUserImpactData.TopViewedArticle, WMFProject) -> URL?
    ) {
        let topThree = data.topViewedArticles
            .sorted { $0.viewsCount > $1.viewsCount }
            .prefix(3)

        guard !topThree.isEmpty else {
            return nil
        }

        guard let primaryAppLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return nil
        }

        let project = WMFProject.wikipedia(primaryAppLanguage)

        self.topViewedArticles = Array(topThree)
        self.project = project
        self.projectID = project.id
        self.getURL = getURL
    }

    public func getArticleURL(
        for article: WMFUserImpactData.TopViewedArticle
    ) -> URL? {
        getURL(article, project)
    }
    
    func hasSameArticles(as data: WMFUserImpactData) -> Bool {
        let incomingTopThree = data.topViewedArticles
            .sorted { $0.viewsCount > $1.viewsCount }
            .prefix(3)
        
        guard incomingTopThree.count == topViewedArticles.count else {
            return false
        }
        
        let existingIds = topViewedArticles.map { $0.id }
        let incomingIds = incomingTopThree.map { $0.id }
        
        return existingIds == incomingIds
    }
}
