import Foundation
import WKData
import Combine

public final class WKImageRecommendationsViewModel: ObservableObject {
    
    // MARK: - Nested Types
    
    public struct LocalizedStrings {
		
		public struct OnboardingStrings {
			let title: String
			let firstItemTitle: String
			let firstItemBody: String
			let secondItemTitle: String
			let secondItemBody: String
			let thirdItemTitle: String
			let thirdItemBody: String
			let continueButton: String
			let learnMoreButton: String

			public init(title: String, firstItemTitle: String, firstItemBody: String, secondItemTitle: String, secondItemBody: String, thirdItemTitle: String, thirdItemBody: String, continueButton: String, learnMoreButton: String) {
				self.title = title
				self.firstItemTitle = firstItemTitle
				self.firstItemBody = firstItemBody
				self.secondItemTitle = secondItemTitle
				self.secondItemBody = secondItemBody
				self.thirdItemTitle = thirdItemTitle
				self.thirdItemBody = thirdItemBody
				self.continueButton = continueButton
				self.learnMoreButton = learnMoreButton
			}
		}

        let title: String
        let viewArticle: String
		let onboardingStrings: OnboardingStrings

		public init(title: String, viewArticle: String, onboardingStrings: OnboardingStrings) {
            self.title = title
            self.viewArticle = viewArticle
			self.onboardingStrings = onboardingStrings
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
    let localizedStrings: LocalizedStrings
    
    private(set) var recommendations: [ImageRecommendation] = []
    @Published var currentRecommendation: ImageRecommendation?
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
    
    func fetchImageRecommendationsIfNeeded(completion: @escaping () -> Void) {
        
        guard recommendations.isEmpty else {
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
