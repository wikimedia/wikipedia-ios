import SwiftUI
import WMFData

@MainActor
final class WMFSavedArticleCellViewModel: ObservableObject, Identifiable {
    
    let id: String
    let title: String
    let project: WMFProject
    let readingListNames: [String]
    
    @Published private(set) var description: String?
    @Published private(set) var thumbnailURL: URL?
    @Published private(set) var isLoading: Bool = false
    
    private let dataController: WMFArticleSummaryDataController
    
    init(article: WMFSavedArticle) {
        self.id = article.id
        self.title = article.title
        self.project = article.project
        self.readingListNames = article.readingListNames
        self.dataController = WMFArticleSummaryDataController()
    }
    
    func fetchArticleDetails() async {
        guard !isLoading else {
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let summary = try await dataController.fetchArticleSummary(project: project, title: title)
            self.description = summary.description
            self.thumbnailURL = summary.thumbnailURL
        } catch {
            // Silently fail - cell will display without description/image
        }
    }
}
