import WMFData
import SwiftUI

@MainActor
public final class MostViewedArticlesViewModel: ObservableObject {
    let topViewedArticles: [WMFUserImpactData.TopViewedArticle]
    public var projectID: String?
    
    public init?(data: WMFUserImpactData) {
        let topViewedArticles = data.topViewedArticles
            .sorted { $0.viewsCount > $1.viewsCount }
            .prefix(3)

        let topThree = Array(topViewedArticles)
        guard !topThree.isEmpty else {
            return nil
        }

        self.topViewedArticles = topThree
        try? getProject()
    }
    
    public func getProject() throws {
        guard let primaryAppLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
             throw WMFDataControllerError.failureCreatingRequestURL
        }

        let project = WMFProject.wikipedia(primaryAppLanguage)
        projectID = project.id
    }
}
