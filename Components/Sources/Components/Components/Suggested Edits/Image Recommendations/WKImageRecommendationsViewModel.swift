import Foundation
import WKData
import Combine
import UIKit

public final class WKImageRecommendationsViewModel: ObservableObject {
    
    // MARK: - Nested Types
    
    public struct LocalizedStrings {
		public typealias SurveyLocalizedStrings =  WKImageRecommendationsSurveyViewModel.LocalizedStrings
        public typealias EmptyLocalizedStrings = WKEmptyViewModel.LocalizedStrings

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
		let surveyLocalizedStrings: SurveyLocalizedStrings
        let emptyLocalizedStrings: EmptyLocalizedStrings
        let bottomSheetTitle: String
        let yesButtonTitle: String
        let noButtonTitle: String
        let notSureButtonTitle: String

        public init(title: String, viewArticle: String, onboardingStrings: OnboardingStrings, surveyLocalizedStrings: SurveyLocalizedStrings, emptyLocalizedStrings: EmptyLocalizedStrings, bottomSheetTitle: String, yesButtonTitle: String, noButtonTitle: String, notSureButtonTitle: String) {
            self.title = title
            self.viewArticle = viewArticle
            self.onboardingStrings = onboardingStrings
			self.surveyLocalizedStrings = surveyLocalizedStrings
            self.emptyLocalizedStrings = emptyLocalizedStrings
            self.bottomSheetTitle = bottomSheetTitle
            self.yesButtonTitle = yesButtonTitle
            self.noButtonTitle = noButtonTitle
            self.notSureButtonTitle = notSureButtonTitle
        }

    }

    public struct WKImageRecommendationData {
        public let pageId: Int
        public let pageTitle: String
        public let image: String
        public let filename: String
        public let displayFilename: String
        public let thumbUrl: String
        public let fullUrl: String
        public let description: String?
        public let descriptionURL: String
        public let reason: String
        public let wikitext: String?

        public init(pageId: Int, pageTitle: String, image: String, filename: String, displayFilename: String, thumbUrl: String, fullUrl: String, description: String?, descriptionURL: String, reason: String, wikitext: String?) {
            self.pageId = pageId
            self.pageTitle = pageTitle
            self.image = image
            self.filename = filename
            self.displayFilename = displayFilename
            self.thumbUrl = thumbUrl
            self.fullUrl = fullUrl
            self.description = description
            self.descriptionURL = descriptionURL
            self.reason = reason
            self.wikitext = wikitext
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
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.main)
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
                    let imageDataArray = self.getFirstImageData(for: pages)

                    for page in pages {
                        if let imageData = imageDataArray.first(where: { $0.pageId == page.pageid}) {
                            let combinedImageRecommendation = ImageRecommendation(pageId: page.pageid, title: page.title, imageData: imageData)
                            self.imageRecommendations.append(combinedImageRecommendation)
                        }
                    }

                    guard let firstRecommendation = self.imageRecommendations.first else {
                        DispatchQueue.main.async {
                            self.loading = false
                            completion()
                        }
                        return
                    }
                    
                    self.populateCurrentArticleSummary(for: firstRecommendation, completion: {
                        DispatchQueue.main.async {
                            self.loading = false
                            completion()
                        }
                    })
                    
                    
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
        
        let removedPage = imageRecommendations.removeFirst()
        growthTasksDataController.remove(pageId: removedPage.pageId, from: project)
        
        guard let nextRecommendation = imageRecommendations.first else {
            growthTasksDataController.reset(for: project)
            fetchImageRecommendationsIfNeeded {
                completion()
            }
            
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
                    pageTitle: firstPageSuggestion.titleText,
                    image: firstImage.image,
                    filename: firstImage.image,
                    displayFilename: firstImage.displayFilename,
                    thumbUrl: metadata.thumbUrl,
                    fullUrl: metadata.fullUrl,
                    description: metadata.description,
                    descriptionURL: metadata.descriptionUrl,
                    reason: metadata.reason,
                    wikitext: page.revisions.first?.wikitext
                )
                imageData.append(imageRecommendation)
            }
        }
        return imageData
    }
}
