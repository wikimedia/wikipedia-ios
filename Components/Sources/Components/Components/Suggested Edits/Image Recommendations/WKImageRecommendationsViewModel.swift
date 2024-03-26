import Foundation
import WKData
import Combine
import UIKit

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
        let bottomSheetTitle: String
        let yesButtonTitle: String
        let noButtonTitle: String
        let notSureButtonTitle: String

        public init(title: String, viewArticle: String, onboardingStrings: OnboardingStrings, bottomSheetTitle: String, yesButtonTitle: String, noButtonTitle: String, notSureButtonTitle: String) {
            self.title = title
            self.viewArticle = viewArticle
            self.onboardingStrings = onboardingStrings
            self.bottomSheetTitle = bottomSheetTitle
            self.yesButtonTitle = yesButtonTitle
            self.noButtonTitle = noButtonTitle
            self.notSureButtonTitle = notSureButtonTitle
        }
    }

    public struct WKImageRecommendationData {
        public let pageId: Int
        public let image: String
        public let filename: String
        public let thumbUrl: String
        public let fullUrl: String
        public let description: String?
        public let reason: String

        public init(pageId: Int, image: String, filename: String, thumbUrl: String, fullUrl: String, description: String?, reason: String) {
            self.pageId = pageId
            self.image = image
            self.filename = filename
            self.thumbUrl = thumbUrl
            self.fullUrl = fullUrl
            self.description = description
            self.reason = reason
        }
    }

    final class ImageRecommendation: ObservableObject {
        
        let pageId: Int
        let title: String
        @Published var articleSummary: WKArticleSummary? = nil
        let imageData: WKImageRecommendationData

        fileprivate init(pageId: Int, title: String, articleSummary: WKArticleSummary? = nil, imageData: WKImageRecommendationData) {
            self.pageId = pageId
            self.title = title
            self.articleSummary = articleSummary
            self.imageData = imageData
        }
    }
    
    // MARK: - Properties
    
    let project: WKProject
    let semanticContentAttribute: UISemanticContentAttribute
    let localizedStrings: LocalizedStrings
    
    private(set) var imageRecommendations: [ImageRecommendation] = []
    private var recommendationData: [WKImageRecommendation.Page] = []
    @Published var currentRecommendation: ImageRecommendation?
    @Published var loading: Bool = true
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
        
        guard imageRecommendations.isEmpty else {
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
                    self.recommendationData = pages
                    let imageDataArray = self.getFirstImageData(for: pages)

                    for page in pages {
                        if let imageData = imageDataArray.first(where: { $0.pageId == page.pageid}) {
                            let combinedImageRecommendation = ImageRecommendation(pageId: page.pageid, title: page.title, imageData: imageData)
                            self.imageRecommendations.append(combinedImageRecommendation)
                        }
                    }

                    if let firstRecommendation = self.imageRecommendations.first {
                        self.populateCurrentArticleSummary(for: firstRecommendation, completion: {
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
        guard !imageRecommendations.isEmpty else {
            self.currentRecommendation = nil
            completion()
            return
        }
        
        imageRecommendations.removeFirst()
        guard let nextRecommendation = imageRecommendations.first else {
            self.currentRecommendation = nil
            completion()
            return
        }
        
        loading = true
        
        populateCurrentArticleSummary(for: nextRecommendation, completion: { [weak self] in
            completion()
            self?.loading = false
        })
    }

    func populateCurrentArticleSummary(for imageRecommendation: ImageRecommendation, completion: @escaping () -> Void) {
        
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

    fileprivate func getFirstImageData(for pages: [WKImageRecommendation.Page]) -> [WKImageRecommendationData] {

        var imageData: [WKImageRecommendationData] = []
        for page in pages {
            if let firstPageSuggestion = page.growthimagesuggestiondata?.first,
               let firstImage = firstPageSuggestion.images.first {
                let metadata = firstImage.metadata
                let imageRecommendation = WKImageRecommendationData(
                    pageId: page.pageid,
                    image: firstImage.image,
                    filename: firstImage.displayFilename,
                    thumbUrl: metadata.thumbUrl,
                    fullUrl: metadata.fullUrl,
                    description: metadata.description,
                    descriptionURL: metadata.descriptionUrl,
                    reason: metadata.reason
                )
                imageData.append(imageRecommendation)
            }
        }
        return imageData
    }
}
