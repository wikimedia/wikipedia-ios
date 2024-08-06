import Foundation

@objc public final class WMFGrowthTasksDataController: NSObject {

    private var service = WMFDataEnvironment.current.mediaWikiService
    let project: WMFProject
    
    private static var currentImageRecommendations: [WMFProject: [WMFImageRecommendation.Page]] = [:]

    public init (project: WMFProject) {
        self.project = project
    }

    // MARK: GET Methods
    
    public func remove(pageId: Int, from project: WMFProject) {
        guard let recommendations = Self.currentImageRecommendations[project] else {
            return
        }
        
        Self.currentImageRecommendations[project] = recommendations.filter { $0.pageid != pageId }
    }
    
    public func reset(for project: WMFProject) {
        Self.currentImageRecommendations[project] = []
    }

    public func getImageRecommendationsCombined(completion: @escaping (Result<[WMFImageRecommendation.Page], Error>) -> Void) {
        guard let service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
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
                           "pilicense": "any",
                           "rvprop": "ids|timestamp|flags|comment|user|content",
                           "rvslots": "main",
                           "rvsection": 0,
                           "gsrlimit": "10",
                           "formatversion": "2",
                           "format": "json"
        ]

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
        service.performDecodableGET(request: request) { [weak self] (result: Result<WMFImageRecommendationAPIResponse, Error>) in
            
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

    fileprivate func getImageSuggestions(from response: WMFImageRecommendationAPIResponse) -> [WMFImageRecommendation.Page] {
        var recommendationsPerPage:[WMFImageRecommendation.Page] = []

        for page in response.query.pages {
            
            if page.pageimage != nil {
                continue
            }

            let page = WMFImageRecommendation.Page(
                pageid: page.pageid,
                title: page.title,
                growthimagesuggestiondata: getGrowthAPIImageSuggestions(for: page),
                revisions: getImageSuggestionRevisionData(for: page))

            recommendationsPerPage.append(page)
        }

        return recommendationsPerPage

    }

   fileprivate func getGrowthAPIImageSuggestions(for page: WMFImageRecommendationAPIResponse.Page) -> [WMFImageRecommendation.GrowthImageSuggestionData] {
       
        var suggestions: [WMFImageRecommendation.GrowthImageSuggestionData] = []

        for item in page.growthimagesuggestiondata ?? [] {
            let item = WMFImageRecommendation.GrowthImageSuggestionData(
                titleNamespace: item.titleNamespace,
                titleText: item.titleText,
                images: getImageSuggestionData(from: item))

            suggestions.append(item)

        }
        return suggestions
    }

    fileprivate func getImageSuggestionRevisionData(for page: WMFImageRecommendationAPIResponse.Page) -> [WMFImageRecommendation.Revision] {
        var revisions: [WMFImageRecommendation.Revision] = []

        for item in page.revisions {
            let item = WMFImageRecommendation.Revision(revID: item.revid, wikitext: item.wikitext.main.content)
            revisions.append(item)
        }
        return revisions
    }

    fileprivate func getImageSuggestionData(from suggestion: WMFImageRecommendationAPIResponse.GrowthImageSuggestionData) -> [WMFImageRecommendation.ImageSuggestion] {
        var images: [WMFImageRecommendation.ImageSuggestion] = []

        for image in suggestion.images {
            let imageSuggestion = WMFImageRecommendation.ImageSuggestion(
                image: image.image,
                displayFilename: image.displayFilename,
                source: image.source,
                projects: image.projects,
                metadata: getMetadataObject(from: image.metadata))
            images.append(imageSuggestion)
        }

        return images
    }

    fileprivate func getMetadataObject(from image: WMFImageRecommendationAPIResponse.ImageMetadata) -> WMFImageRecommendation.ImageMetadata {
        let metadata = WMFImageRecommendation.ImageMetadata(descriptionUrl: image.descriptionUrl, thumbUrl: image.thumbUrl, fullUrl: image.fullUrl, originalWidth: image.originalWidth, originalHeight: image.originalHeight, mediaType: image.mediaType, description: image.description, author: image.author, license: image.license, date: image.date, caption: image.caption, categories: image.categories, reason: image.reason, contentLanguageName: image.contentLanguageName, sectionNumber: image.sectionNumber)

        return metadata
    }

}

// MARK: Types

public enum WMFGrowthTaskType: String {
    case imageRecommendation = "image-recommendation"
}

// MARK: Objective-C Helpers

public extension WMFGrowthTasksDataController {
    
    @objc convenience init(languageCode: String) {
        let language = WMFLanguage(languageCode: languageCode, languageVariantCode: nil)
        self.init(project: WMFProject.wikipedia(language))
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
