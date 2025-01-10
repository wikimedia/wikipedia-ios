import Foundation
import WMFData
import Combine
import UIKit

public final class WMFImageRecommendationsViewModel: ObservableObject {
    
    // MARK: - Nested Types
    
    enum ImageRecommendationsError: Error {
        case cannotFindCurrentRecommendation
        case invalidImageFullUrl
    }
    
    public struct LocalizedStrings {
		public typealias SurveyLocalizedStrings =  WMFSurveyViewModel.LocalizedStrings
        public typealias EmptyLocalizedStrings = WMFEmptyViewModel.LocalizedStrings
        public typealias TooltipLocalizedStrings = WMFTooltipViewModel.LocalizedStrings
        public typealias ErrorLocalizedStrings = WMFErrorViewModel.LocalizedStrings

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
        
        public struct AltTextFeedbackStrings {
            let feedbackTitle: String
            let feedbackSubtitle: String
            let yesButton: String
            let noButton: String

            public init(feedbackTitle: String, feedbackSubtitle: String, yesButton: String, noButton: String) {
                self.feedbackTitle = feedbackTitle
                self.feedbackSubtitle = feedbackSubtitle
                self.yesButton = yesButton
                self.noButton = noButton
            }
        }

        let title: String
        let viewArticle: String
		let onboardingStrings: OnboardingStrings
        let surveyLocalizedStrings: SurveyLocalizedStrings
        let emptyLocalizedStrings: EmptyLocalizedStrings
        let errorLocalizedStrings: ErrorLocalizedStrings
        let firstTooltipStrings: TooltipLocalizedStrings
        let secondTooltipStrings: TooltipLocalizedStrings
        let thirdTooltipStrings: TooltipLocalizedStrings
        let altTextFeedbackStrings: AltTextFeedbackStrings
        let bottomSheetTitle: String
        let yesButtonTitle: String
        let noButtonTitle: String
        let notSureButtonTitle: String
        let learnMoreButtonTitle: String
        let tutorialButtonTitle: String
        let problemWithFeatureButtonTitle: String

        public init(title: String, viewArticle: String, onboardingStrings: OnboardingStrings, surveyLocalizedStrings: SurveyLocalizedStrings, emptyLocalizedStrings: EmptyLocalizedStrings, errorLocalizedStrings: ErrorLocalizedStrings, firstTooltipStrings: TooltipLocalizedStrings, secondTooltipStrings: TooltipLocalizedStrings, thirdTooltipStrings: TooltipLocalizedStrings, altTextFeedbackStrings: AltTextFeedbackStrings, bottomSheetTitle: String, yesButtonTitle: String, noButtonTitle: String, notSureButtonTitle: String, learnMoreButtonTitle: String, tutorialButtonTitle: String, problemWithFeatureButtonTitle: String) {
            self.title = title
            self.viewArticle = viewArticle
            self.onboardingStrings = onboardingStrings
            self.surveyLocalizedStrings = surveyLocalizedStrings
            self.emptyLocalizedStrings = emptyLocalizedStrings
            self.errorLocalizedStrings = errorLocalizedStrings
            self.firstTooltipStrings = firstTooltipStrings
            self.secondTooltipStrings = secondTooltipStrings
            self.thirdTooltipStrings = thirdTooltipStrings
            self.altTextFeedbackStrings = altTextFeedbackStrings
            self.bottomSheetTitle = bottomSheetTitle
            self.yesButtonTitle = yesButtonTitle
            self.noButtonTitle = noButtonTitle
            self.notSureButtonTitle = notSureButtonTitle
            self.learnMoreButtonTitle = learnMoreButtonTitle
            self.tutorialButtonTitle = tutorialButtonTitle
            self.problemWithFeatureButtonTitle = problemWithFeatureButtonTitle
        }
    }

    public class WMFImageRecommendationData {
        public let pageId: Int
        public let pageTitle: String
        public let image: String
        public let filename: String
        public let displayFilename: String
        public let source: String
        public let thumbUrl: String
        public let fullUrl: String
        public let description: String?
        public let descriptionURL: String
        public let reason: String
        public internal(set) var uiImage: UIImage?
        public let wikitext: String?

        public init(pageId: Int, pageTitle: String, image: String, filename: String, displayFilename: String, source: String, thumbUrl: String, fullUrl: String, description: String?, descriptionURL: String, reason: String, wikitext: String?) {
            self.pageId = pageId
            self.pageTitle = pageTitle
            self.image = image
            self.filename = filename
            self.displayFilename = displayFilename
            self.source = source
            self.thumbUrl = thumbUrl
            self.fullUrl = fullUrl
            self.description = description
            self.descriptionURL = descriptionURL
            self.reason = reason
            self.wikitext = wikitext
        }
    }

    public final class ImageRecommendation: ObservableObject {
        
        let pageId: Int
        public let title: String
        @Published var articleSummary: WMFArticleSummary? = nil
        public let imageData: WMFImageRecommendationData
        public var caption: String?
        public var altText: String?
        public var imageWikitext: String?
        public var fullArticleWikitextWithImage: String?
        public var suggestionAcceptDate: Date?
        public var altTextExperimentAcceptDate: Date?
        public var lastRevisionID: UInt64?
        public var localizedFileTitle: String?

        fileprivate init(pageId: Int, title: String, articleSummary: WMFArticleSummary? = nil, imageData: WMFImageRecommendationData) {
            self.pageId = pageId
            self.title = title
            self.articleSummary = articleSummary
            self.imageData = imageData
        }
    }
    
    // MARK: - Properties

    public let project: WMFProject
    public let semanticContentAttribute: UISemanticContentAttribute
    public let isPermanent: Bool
    let localizedStrings: LocalizedStrings
    let surveyOptions: [WMFSurveyViewModel.OptionViewModel]

    private(set) var imageRecommendations: [ImageRecommendation] = []
    @Published public private(set) var currentRecommendation: ImageRecommendation?
    public private(set) var lastRecommendation: ImageRecommendation?
    @Published var loading: Bool = true
    @Published var debouncedLoading: Bool = true
    @Published var loadingError: Error? = nil
    private var subscriptions = Set<AnyCancellable>()
    private let needsSuppressPosting: Bool

    let growthTasksDataController: WMFGrowthTasksDataController
    let articleSummaryDataController: WMFArticleSummaryDataController
    let imageDataController: WMFImageDataController
    let imageRecommendationsDataController: WMFImageRecommendationsDataController
    let learnMoreURL = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_Suggested_edits#Add_an_image")

    private(set) public var startTime: Date?

    // MARK: - Lifecycle
    
    public init(project: WMFProject, semanticContentAttribute: UISemanticContentAttribute, isPermanent: Bool, localizedStrings: LocalizedStrings, surveyOptions: [WMFSurveyViewModel.OptionViewModel], needsSuppressPosting: Bool) {
        self.isPermanent = isPermanent
        self.project = project
        self.semanticContentAttribute = semanticContentAttribute
        self.localizedStrings = localizedStrings
        self.surveyOptions = surveyOptions
        self.needsSuppressPosting = needsSuppressPosting
        self.growthTasksDataController = WMFGrowthTasksDataController(project: project)
        self.articleSummaryDataController = WMFArticleSummaryDataController()
        self.imageDataController = WMFImageDataController()
        self.imageRecommendationsDataController = WMFImageRecommendationsDataController()
        
        $loading
            .removeDuplicates()
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.main)
                    .sink(receiveValue: { [weak self] t in
                        self?.debouncedLoading = t
                    })
                    .store(in: &subscriptions)
    }
    
    // MARK: - Internal
    
    func tryAgainAfterLoadingError() {
        if let currentRecommendation {
            loading = true
            populateImageAndArticleSummary(for: currentRecommendation) { [weak self] error in
                self?.loading = false
                self?.loadingError = error
            }
        } else {
            fetchImageRecommendationsIfNeeded {
                
            }
        }
    }
    
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
                    self.loadingError = nil
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
                    
                    self.populateImageAndArticleSummary(for: firstRecommendation) { [weak self] error in
                        self?.currentRecommendation = firstRecommendation
                        self?.loading = false
                        self?.loadingError = error
                        completion()
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.loading = false
                    self.loadingError = error
                    completion()
                }
            }
        }
    }
    
    public func next(completion: @escaping () -> Void) {
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
        
        populateImageAndArticleSummary(for: nextRecommendation) { [weak self] error in

            guard let self else { return }

            if let currentRecommendation {
                self.lastRecommendation = currentRecommendation
            }
            self.currentRecommendation = nextRecommendation
            self.loading = false
            self.loadingError = error
            completion()
        }
    }
    
    public func sendFeedback(editRevId: UInt64?, accepted: Bool, reasons: [String] = [], caption: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard !needsSuppressPosting else {
            completion(.success(()))
            return
        }
        
        guard let currentRecommendation else {
            completion(.failure(ImageRecommendationsError.cannotFindCurrentRecommendation))
            return
        }
        
        imageRecommendationsDataController.sendFeedback(project: project, pageTitle: currentRecommendation.imageData.pageTitle.spacesToUnderscores, editRevId: editRevId, fileName: currentRecommendation.imageData.filename, accepted: accepted, reasons: reasons, caption: caption, completion: completion)
    }


    private func populateImageAndArticleSummary(for imageRecommendation: ImageRecommendation, completion: @escaping (Error?) -> Void) {
        let group = DispatchGroup()
        var populateError: Error? = nil

        group.enter()
        self.populateCurrentArticleSummary(for: imageRecommendation, completion: { error in
            if let error {
                populateError = error
            }
            group.leave()
        })
        
        group.enter()
        self.populateUIImage(for: imageRecommendation.imageData) { error in
            if let error {
                populateError = error
            }
            group.leave()
        }

        startTime = Date()

        group.notify(queue: .main) {
            completion(populateError)
        }
    }

    private func populateCurrentArticleSummary(for imageRecommendation: ImageRecommendation, completion: @escaping (Error?) -> Void) {
        
        articleSummaryDataController.fetchArticleSummary(project: project, title: imageRecommendation.title) { result in
            
            switch result {
            case .success(let summary):
                imageRecommendation.articleSummary = summary
                completion(nil)
                
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    private func populateUIImage(for imageData: WMFImageRecommendationData, completion: @escaping (Error?) -> Void) {
        
        guard let url = URL(string: "https:\(imageData.fullUrl)") else {
            completion(ImageRecommendationsError.invalidImageFullUrl)
            return
        }
        
        imageDataController.fetchImageData(url: url) { result in
            switch result {
            case .success(let data):
                let image = UIImage(data: data)
                imageData.uiImage = image
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    fileprivate func getFirstImageData(for pages: [WMFImageRecommendation.Page]) -> [WMFImageRecommendationData] {

        var imageData: [WMFImageRecommendationData] = []
        for page in pages {
            if let firstPageSuggestion = page.growthimagesuggestiondata?.first,
               let firstImage = firstPageSuggestion.images.first {
                let metadata = firstImage.metadata
                let imageRecommendation = WMFImageRecommendationData(
                    pageId: page.pageid,
                    pageTitle: firstPageSuggestion.titleText,
                    image: firstImage.image,
                    filename: firstImage.image,
                    displayFilename: firstImage.displayFilename,
                    source: firstImage.source,
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
