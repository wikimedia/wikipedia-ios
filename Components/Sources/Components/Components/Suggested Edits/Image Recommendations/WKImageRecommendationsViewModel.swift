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
                DispatchQueue.main.async {
                    self.recommendations = pages.map { ImageRecommendation(pageId: $0.pageid, title: $0.title) }
                    if let firstRecommendation = self.recommendations.first {
                        self.populateCurrentRecommendation(for: firstRecommendation, completion: {
                            DispatchQueue.main.async {
                                completion()
                            }
                        })
                    }
                }
                
            case .failure(let error):
                completion()
                print(error)
            }
        }
    }
    
    func next(completion: @escaping () -> Void) {
        guard !recommendations.isEmpty else {
            self.currentRecommendation = nil
            completion()
            return
        }
        
        recommendations.removeFirst()
        guard let nextRecommendation = recommendations.first else {
            self.currentRecommendation = nil
            completion()
            return
        }
        
        populateCurrentRecommendation(for: nextRecommendation, completion: {
            completion()
        })
    }
    
    func populateCurrentRecommendation(for imageRecommendation: ImageRecommendation, completion: @escaping () -> Void) {
        
        articleSummaryDataController.fetchArticleSummary(project: project, title: imageRecommendation.title) { [weak self] result in
            
            guard let self else {
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            switch result {
            case .success(let summary):
                DispatchQueue.main.async {
                    imageRecommendation.articleSummary = summary
                    self.currentRecommendation = imageRecommendation
                    completion()
                }
                
            case .failure(let error):
                print(error)
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
}
