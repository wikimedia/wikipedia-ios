import Foundation

@objc public final class WKGrowthTasksDataController: NSObject {

    private var service = WKDataEnvironment.current.mediaWikiService
    let project: WKProject

    public init (project: WKProject) {
        self.project = project
    }

    // MARK: GET Methods

    public func getImageRecommendationsCombined(completion: @escaping (Result<[WKImageRecommendation.Page], Error>) -> Void) {
        guard let service else {
            completion(.failure(WKDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        var recommendationsPerPage: [WKImageRecommendation.Page] = []

        let parameters: [String: Any] = [ "action": "query",
                           "generator": "search",
                           "gsrsearch": "hasrecommendation:image",
                           "gsrnamespace": 0,
                           "gsrsort": "random",
                           "prop": "growthimagesuggestiondata|revisions",
                           "rvprop": "ids|timestamp|flags|comment|user|content",
                           "rvslots": "main",
                           "rvsection": 0,
                           "gsrlimit": "10",
                           "formatversion": "2",
                           "format": "json"
        ]

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            completion(.failure(WKDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WKMediaWikiServiceRequest(url: url, method: .GET, parameters: parameters)
        service.performDecodableGET(request: request) { (result: Result<WKImageRecommendationAPIResponse, Error>) in
            switch result {
            case .success(let response):
                print(response)
                recommendationsPerPage.append(contentsOf: self.getImageSuggestions(from: response))
                completion(.success(recommendationsPerPage))
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }

    // MARK: Private methods

    fileprivate func getImageSuggestions(from response: WKImageRecommendationAPIResponse) -> [WKImageRecommendation.Page] {
        var recommendationsPerPage:[WKImageRecommendation.Page] = []

        for page in response.query.pages {

            let page = WKImageRecommendation.Page(
                pageid: page.pageid,
                title: page.title,
                growthimagesuggestiondata: getGrowthAPIImageSuggestions(for: page))

            recommendationsPerPage.append(page)
        }

        return recommendationsPerPage

    }

   fileprivate func getGrowthAPIImageSuggestions(for page: WKImageRecommendationAPIResponse.Page) -> [WKImageRecommendation.GrowthImageSuggestionData] {
       
        var suggestions: [WKImageRecommendation.GrowthImageSuggestionData] = []

        for item in page.growthimagesuggestiondata ?? [] {
            let item = WKImageRecommendation.GrowthImageSuggestionData(
                titleNamespace: item.titleNamespace,
                titleText: item.titleText,
                images: getImageSuggestionData(from: item))

            suggestions.append(item)

        }
        return suggestions
    }

    internal func getImageSuggestionData(from suggestion: WKImageRecommendationAPIResponse.GrowthImageSuggestionData) -> [WKImageRecommendation.ImageSuggestion] {
        var images: [WKImageRecommendation.ImageSuggestion] = []

        for image in suggestion.images {
            let imageSuggestion = WKImageRecommendation.ImageSuggestion(
                image: image.image,
                displayFilename: image.displayFilename,
                source: image.source,
                projects: image.projects,
                metadata: getMetadataObject(from: image.metadata))
            images.append(imageSuggestion)
        }

        return images
    }

    fileprivate func getMetadataObject(from image: WKImageRecommendationAPIResponse.ImageMetadata) -> WKImageRecommendation.ImageMetadata {
        let metadata = WKImageRecommendation.ImageMetadata(descriptionUrl: image.descriptionUrl, thumbUrl: image.thumbUrl, fullUrl: image.fullUrl, originalWidth: image.originalWidth, originalHeight: image.originalHeight, mediaType: image.mediaType, description: image.description, author: image.author, license: image.license, date: image.date, caption: image.caption, categories: image.categories, reason: image.reason, contentLanguageName: image.contentLanguageName)

        return metadata
    }

}

// MARK: Types

public enum WKGrowthTaskType: String {
    case imageRecommendation = "image-recommendation"
}

// MARK: Objective-C Helpers

public extension WKGrowthTasksDataController {
    
    @objc convenience init(languageCode: String) {
        let language = WKLanguage(languageCode: languageCode, languageVariantCode: nil)
        self.init(project: WKProject.wikipedia(language))
    }
    
    @objc func hasImageRecommendations(completion: @escaping (Bool) -> Void) {
        getImageRecommendationsCombined { result in
            switch result {
            case .success(let pages):
                let pagesWithSuggestions = pages.filter { !($0.growthimagesuggestiondata ?? []).isEmpty }
                completion(!pagesWithSuggestions.isEmpty)
            case .failure:
                completion(false)
            }
        }
    }
}
