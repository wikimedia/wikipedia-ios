import Foundation

@objc public final class WKGrowthTasksDataController: NSObject {

    private var service = WKDataEnvironment.current.mediaWikiService
    let project: WKProject
    
    private static var currentImageRecommendations: [WKProject: [WKImageRecommendation.Page]] = [:]

    public init (project: WKProject) {
        self.project = project
    }

    // MARK: GET Methods
    
    public func remove(pageId: Int, from project: WKProject) {
        guard let recommendations = Self.currentImageRecommendations[project] else {
            return
        }
        
        Self.currentImageRecommendations[project] = recommendations.filter { $0.pageid != pageId }
    }
    
    public func reset(for project: WKProject) {
        Self.currentImageRecommendations[project] = []
    }

    public func getImageRecommendationsCombined(completion: @escaping (Result<[WKImageRecommendation.Page], Error>) -> Void) {
        guard let service else {
            completion(.failure(WKDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        if let currentRecommendations = Self.currentImageRecommendations[project],
           !currentRecommendations.isEmpty {
            completion(.success(currentRecommendations))
            return
        }

        let parameters: [String: Any] = [ "action": "query",
                           "generator": "search",
                           "gsrsearch": "hasrecommendation:image",
                           "gsrnamespace": 0,
                           "gsrsort": "random",
                           "prop": "growthimagesuggestiondata|revisions|pageimages",
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

        let request = WKMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
        service.performDecodableGET(request: request) { [weak self] (result: Result<WKImageRecommendationAPIResponse, Error>) in
            
            guard let self else {
                return
            }
            
            switch result {
            case .success(let response):
                Self.currentImageRecommendations[project, default: []].append(contentsOf: self.getImageSuggestions(from: response))
                completion(.success(Self.currentImageRecommendations[project] ?? []))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: Private methods

    fileprivate func getImageSuggestions(from response: WKImageRecommendationAPIResponse) -> [WKImageRecommendation.Page] {
        var recommendationsPerPage:[WKImageRecommendation.Page] = []

        for page in response.query.pages {
            
            if page.pageimage != nil {
                continue
            }

            let page = WKImageRecommendation.Page(
                pageid: page.pageid,
                title: page.title,
                growthimagesuggestiondata: getGrowthAPIImageSuggestions(for: page),
                revisions: getImageSuggestionRevisionData(for: page))

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

    fileprivate func getImageSuggestionRevisionData(for page: WKImageRecommendationAPIResponse.Page) -> [WKImageRecommendation.Revision] {
        var revisions: [WKImageRecommendation.Revision] = []

        for item in page.revisions {
            let item = WKImageRecommendation.Revision(revID: item.revid, wikitext: item.wikitext.main.content)
            revisions.append(item)
        }
        return revisions
    }

    fileprivate func getImageSuggestionData(from suggestion: WKImageRecommendationAPIResponse.GrowthImageSuggestionData) -> [WKImageRecommendation.ImageSuggestion] {
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
        let metadata = WKImageRecommendation.ImageMetadata(descriptionUrl: image.descriptionUrl, thumbUrl: image.thumbUrl, fullUrl: image.fullUrl, originalWidth: image.originalWidth, originalHeight: image.originalHeight, mediaType: image.mediaType, description: image.description, author: image.author, license: image.license, date: image.date, caption: image.caption, categories: image.categories, reason: image.reason, contentLanguageName: image.contentLanguageName, sectionNumber: image.sectionNumber)

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
