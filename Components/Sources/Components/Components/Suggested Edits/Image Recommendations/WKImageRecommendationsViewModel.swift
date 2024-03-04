import Foundation
import WKData
import Combine

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
    
    final class ImageRecommendationArticle: ObservableObject {
        
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
    let localizedStrings: LocalizedStrings
    
    private(set) var articleRecommendations: [ImageRecommendationArticle] = []
    @Published var currentArticleRecommendation: ImageRecommendationArticle?
    @Published private var loading: Bool = true
    @Published var debouncedLoading: Bool = true
    private var subscriptions = Set<AnyCancellable>()
    
    let growthTasksDataController: WKGrowthTasksDataController
    let articleSummaryDataController: WKArticleSummaryDataController
    
    // MARK: - Lifecycle
    
    public init(project: WKProject, localizedStrings: LocalizedStrings) {
        self.project = project
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
    
    func fetchImageRecommendationsArticleIfNeeded(completion: @escaping () -> Void) {
        
        guard articleRecommendations.isEmpty else {
            completion()
            return
        }
        
        loading = true
        
        growthTasksDataController.getGrowthAPITask(task: .imageRecommendation) { [weak self] result in
            
            guard let self else {
                completion()
                return
            }
            
            switch result {
            case .success(let pages):
                DispatchQueue.main.async {
                    self.articleRecommendations = pages.map { ImageRecommendationArticle(pageId: $0.pageid, title: $0.title) }
                    if let firstRecommendation = self.articleRecommendations.first {
                        self.populateCurrentArticleRecommendation(for: firstRecommendation, completion: {
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
        guard !articleRecommendations.isEmpty else {
            self.currentArticleRecommendation = nil
            completion()
            return
        }
        
        articleRecommendations.removeFirst()
        guard let nextRecommendation = articleRecommendations.first else {
            self.currentArticleRecommendation = nil
            completion()
            return
        }
        
        loading = true
        
        populateCurrentArticleRecommendation(for: nextRecommendation, completion: { [weak self] in
            completion()
            self?.loading = false
        })
    }
    
    func populateCurrentArticleRecommendation(for imageRecommendationArticle: ImageRecommendationArticle, completion: @escaping () -> Void) {
        
        articleSummaryDataController.fetchArticleSummary(project: project, title: imageRecommendationArticle.title) { [weak self] result in
            
            guard let self else {
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            switch result {
            case .success(let summary):
                DispatchQueue.main.async {
                    imageRecommendationArticle.articleSummary = summary
                    self.currentArticleRecommendation = imageRecommendationArticle
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
