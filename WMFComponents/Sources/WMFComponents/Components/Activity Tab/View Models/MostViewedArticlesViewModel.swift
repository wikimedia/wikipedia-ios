import WMFData
import SwiftUI

@MainActor
public final class MostViewedArticlesViewModel: ObservableObject {
    let topViewedArticles: [WMFUserImpactData.TopViewedArticle]
    public var projectID: String?
    
    public init?(data: WMFUserImpactData) {
        let topViewedArticles = Array(data.topViewedArticles.prefix(3))
        guard !topViewedArticles.isEmpty else {
            return nil
        }
        
        self.topViewedArticles = topViewedArticles
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
