import Foundation
import WKData

public final class WKImageRecommendationsViewModel: ObservableObject {
    
    // MARK: - Nested Types
    
    final class ImageRecommendation: ObservableObject {
        
        let pageId: Int
        let title: String
        @Published var articleSummary: WKArticleSummary? = nil
        
        fileprivate init(pageId: Int, title: String, articleSummary: WKArticleSummary? = nil) {
            self.pageId = pageId
            self.title = title
            self.articleSummary = articleSummary
        }
    }
    
    // MARK: - Properties
    
    let project: WKProject
    private(set) var recommendations: [ImageRecommendation] = []
    @Published var currentRecommendation: ImageRecommendation?
    
    let growthTasksDataController: WKGrowthTasksDataController
    let articleSummaryDataController: WKArticleSummaryDataController
    
    // MARK: - Lifecycle
    
    public init(project: WKProject) {
        self.project = project
        self.growthTasksDataController = WKGrowthTasksDataController(project: project)
        self.articleSummaryDataController = WKArticleSummaryDataController()
    }
    
    // MARK: - Internal
    
    func fetchImageRecommendations(completion: @escaping () -> Void) {
        growthTasksDataController.getGrowthAPITask(task: .imageRecommendation) { [weak self] result in
            
            guard let self else {
                completion()
                return
            }
            
            switch result {
            case .success(let pages):
                recommendations = pages.map { ImageRecommendation(pageId: $0.pageid, title: $0.title) }
                currentRecommendation = recommendations.first
                fetchCurrentRecommendationArticleSummary {
                    completion()
                }
            case .failure(let error):
                completion()
                print(error)
            }
        }
    }
    
    func next(completion: @escaping () -> Void) {
        recommendations.removeFirst()
        self.currentRecommendation = recommendations.first
        fetchCurrentRecommendationArticleSummary {
            completion()
        }
    }
    
    func fetchCurrentRecommendationArticleSummary(completion: @escaping () -> Void) {
  
        guard let currentRecommendation else {
            completion()
            return
        }
        
        articleSummaryDataController.fetchArticleSummary(project: project, title: currentRecommendation.title) { [weak self] result in
            
            guard let self else {
                completion()
                return
            }
            
            switch result {
            case .success(let summary):
                self.currentRecommendation?.articleSummary = summary
                completion()
            case .failure(let error):
                print(error)
                completion()
            }
        }
    }
}
