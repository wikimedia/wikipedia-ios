import Foundation

// MARK: - Pure Swift Actor (Clean Implementation)

@objc public actor WMFGrowthTasksDataController: NSObject {

    private let service: WMFService?
    private let project: WMFProject
    
    private static var currentImageRecommendations: [WMFProject: [WMFImageRecommendation.Page]] = [:]

    public init(project: WMFProject, service: WMFService? = WMFDataEnvironment.current.mediaWikiService) {
        self.project = project
        self.service = service
    }
    
    @objc public init(languageCode: String, languageVariantCode: String?) {
        self.project = .wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))
        self.service = WMFDataEnvironment.current.mediaWikiService
    }

    // MARK: Public Methods
    
    public func remove(pageId: Int, from project: WMFProject) {
        guard let recommendations = Self.currentImageRecommendations[project] else {
            return
        }
        
        Self.currentImageRecommendations[project] = recommendations.filter { $0.pageid != pageId }
    }
    
    public func reset(for project: WMFProject) {
        Self.currentImageRecommendations[project] = []
    }

    public func getImageRecommendationsCombined() async throws -> [WMFImageRecommendation.Page] {
        guard let service else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
        }
        
        if let currentRecommendations = Self.currentImageRecommendations[project],
           !currentRecommendations.isEmpty {
            return currentRecommendations
        }

        let parameters: [String: Any] = [
            "action": "query",
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
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
        
        let response: WMFImageRecommendationAPIResponse = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<WMFImageRecommendationAPIResponse, Error>) in
                continuation.resume(with: result)
            }
        }
        
        let suggestions = getImageSuggestions(from: response)
        Self.currentImageRecommendations[project, default: []].append(contentsOf: suggestions)
        return Self.currentImageRecommendations[project] ?? []
    }

    // MARK: Private Methods

    private func getImageSuggestions(from response: WMFImageRecommendationAPIResponse) -> [WMFImageRecommendation.Page] {
        var recommendationsPerPage: [WMFImageRecommendation.Page] = []

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

    private func getGrowthAPIImageSuggestions(for page: WMFImageRecommendationAPIResponse.Page) -> [WMFImageRecommendation.GrowthImageSuggestionData] {
       
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

    private func getImageSuggestionRevisionData(for page: WMFImageRecommendationAPIResponse.Page) -> [WMFImageRecommendation.Revision] {
        var revisions: [WMFImageRecommendation.Revision] = []

        for item in page.revisions {
            let item = WMFImageRecommendation.Revision(revID: item.revid, wikitext: item.wikitext.main.content)
            revisions.append(item)
        }
        return revisions
    }

    private func getImageSuggestionData(from suggestion: WMFImageRecommendationAPIResponse.GrowthImageSuggestionData) -> [WMFImageRecommendation.ImageSuggestion] {
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

    private func getMetadataObject(from image: WMFImageRecommendationAPIResponse.ImageMetadata) -> WMFImageRecommendation.ImageMetadata {
        let metadata = WMFImageRecommendation.ImageMetadata(
            descriptionUrl: image.descriptionUrl,
            thumbUrl: image.thumbUrl,
            fullUrl: image.fullUrl,
            originalWidth: image.originalWidth,
            originalHeight: image.originalHeight,
            mediaType: image.mediaType,
            description: image.description,
            author: image.author,
            license: image.license,
            date: image.date,
            caption: image.caption,
            categories: image.categories,
            reason: image.reason,
            contentLanguageName: image.contentLanguageName,
            sectionNumber: image.sectionNumber)

        return metadata
    }
}

// MARK: - Types

public enum WMFGrowthTaskType: String {
    case imageRecommendation = "image-recommendation"
}

// Sync Bridge Methods

extension WMFGrowthTasksDataController {
    @objc nonisolated public func hasImageRecommendationsSyncBridge(completion: @escaping @Sendable (Bool) -> Void) {
        Task {
            do {
                let pages = try await getImageRecommendationsCombined()
                let pagesWithSuggestions = pages.filter { !($0.growthimagesuggestiondata ?? []).isEmpty }
                completion(!pagesWithSuggestions.isEmpty)
            } catch {
                completion(false)
            }
        }
    }
}
