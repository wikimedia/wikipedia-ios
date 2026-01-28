import SwiftUI
import WMFData

@MainActor
final class WMFAsyncPageRowSavedViewModel: ObservableObject, Identifiable {
    
    let id: String
    let title: String
    let project: WMFProject
    let readingListNames: [String]
    
    @Published private(set) var description: String?
    @Published private(set) var uiImage: UIImage?
    @Published private(set) var isLoading: Bool = false
    
    private let dataController: WMFArticleSummaryDataController
    
    init(id: String, title: String, project: WMFProject, readingListNames: [String]) {
        self.id = id
        self.title = title
        self.project = project
        self.readingListNames = readingListNames
        self.dataController = WMFArticleSummaryDataController.shared
        Task {
            await self.fetchArticleDetails()
        }
    }
    
    @MainActor
    private func fetchArticleDetails() async {
        guard !isLoading else {
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let summary = try await dataController.fetchArticleSummary(project: project, title: title)
            self.description = summary.description
            
            let imageDataController = WMFImageDataController()
            
            guard let thumbnailURL = summary.thumbnailURL else {
                return
            }
            let data = try await imageDataController.fetchImageData(url: thumbnailURL)
            
            self.uiImage = UIImage(data: data)
        } catch {
            // Silently fail - cell will display without description/image
        }
    }
}
