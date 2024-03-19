import Foundation
import WKData
import Combine
import UIKit

public final class WKImageRecommendationsViewModel: ObservableObject {
    
    // MARK: - Nested Types
    
    public struct LocalizedStrings {
        let title: String
        let viewArticle: String
        
        public init(title: String, viewArticle: String) {
            self.title = title
            self.viewArticle = viewArticle
        }
    }
    
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
    let semanticContentAttribute: UISemanticContentAttribute
    let localizedStrings: LocalizedStrings
    
    private(set) var recommendations: [ImageRecommendation] = []
    @Published var currentRecommendation: ImageRecommendation?
    @Published private var loading: Bool = true
    @Published var debouncedLoading: Bool = true
    private var subscriptions = Set<AnyCancellable>()
    
    let growthTasksDataController: WKGrowthTasksDataController
    let articleSummaryDataController: WKArticleSummaryDataController
    
    // MARK: - Lifecycle
    
    public init(project: WKProject, semanticContentAttribute: UISemanticContentAttribute, localizedStrings: LocalizedStrings) {
        self.project = project
        self.semanticContentAttribute = semanticContentAttribute
        self.localizedStrings = localizedStrings
        self.growthTasksDataController = WKGrowthTasksDataController(project: project)
        self.articleSummaryDataController = WKArticleSummaryDataController()
        
        $loading
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
                    .sink(receiveValue: { [weak self] t in
                        self?.debouncedLoading = t
                    })
                    .store(in: &subscriptions)
    }
    
    // MARK: - Internal
    
    func fetchImageRecommendationsIfNeeded(completion: @escaping () -> Void) {
        
        guard recommendations.isEmpty else {
            completion()
            return
        }
        
        loading = true
        
        growthTasksDataController.getImageRecommendationsCombined { [weak self] result in
            
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
                                self.loading = false
                                completion()
                            }
                        })
                    }
                }
                
            case .failure(let error):
                self.loading = false
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
        
        loading = true
        
        populateCurrentRecommendation(for: nextRecommendation, completion: { [weak self] in
            completion()
            self?.loading = false
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
