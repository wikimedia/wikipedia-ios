import Foundation

// MARK: - Controller

public actor WMFOnThisDayDataController {

    // MARK: Properties

    public static let shared = WMFOnThisDayDataController()

    private let basicService: WMFService?
    private var responseCache: [String: WMFOnThisDayResponse] = [:]

    /// Languages known to support the On This Day feed endpoint.
    /// Sourced from the WMFOnThisDayEventsFetcher supported-language list in the main app.
    private static let supportedLanguageCodes: Set<String> = [
        "en", "de", "fr", "sv", "pt", "ru", "es", "ar", "bs", "uk",
        "it", "tr", "zh", "cs"
    ]

    // MARK: Init

    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService) {
        self.basicService = basicService
    }

    // MARK: Public API

    /// Fetches On This Day events for a given `WMFProject` and date components.
    ///
    /// - Parameters:
    ///   - project: The wiki project to fetch events for. Only `.wikipedia` projects whose
    ///              language code appears in the supported-language list are accepted
    ///   - month: The calendar month (1–12).
    ///   - day: The calendar day (1–31).
    ///   - completion: Called on an arbitrary queue with the result.
    private func fetchOnThisDay(
        project: WMFProject,
        month: Int,
        day: Int,
        completion: @escaping @Sendable (Result<WMFOnThisDayResponse, Error>) -> Void
    ) {
        guard isSupported(project: project) else {
            completion(.failure(WMFDataControllerError.unsupportedProject))
            return
        }

        guard let basicService else {
            completion(.failure(WMFDataControllerError.basicServiceUnavailable))
            return
        }

        guard let url = url(for: project, month: month, day: day) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, acceptType: .json)
        basicService.performDecodableGET(request: request) { (result: Result<WMFOnThisDayResponse, Error>) in
            completion(result)
        }
    }

    /// Fetches On This Day events with in-memory caching.
    /// Repeated calls for the same project+month+day return the cached response immediately.
    public func fetchOnThisDay(
        project: WMFProject,
        month: Int,
        day: Int
    ) async throws -> WMFOnThisDayResponse {
        let key = "\(project.id)-\(month)-\(day)"
        if let cached = responseCache[key] {
            return cached
        }
        let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<WMFOnThisDayResponse, Error>) in
            fetchOnThisDay(project: project, month: month, day: day) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        responseCache[key] = response
        return response
    }

    @_spi(Testing) public func reset() {
        responseCache = [:]
    }

    // MARK: Private helpers

    nonisolated private func isSupported(project: WMFProject) -> Bool {
        guard case .wikipedia(let language) = project else { return false }
        return Self.supportedLanguageCodes.contains(language.languageCode)
    }

    /// Builds the REST v1 feed URL:
    /// `https://{lang}.wikipedia.org/api/rest_v1/feed/onthisday/events/{M}/{D}`
    nonisolated private func url(for project: WMFProject, month: Int, day: Int) -> URL? {
        guard case .wikipedia = project else { return nil }
        return URL.wikimediaRestAPIURL(project: project, additionalPathComponents: [
            "feed",
            "onthisday",
            "events",
            String(month),
            String(day)
        ])
    }
}

// MARK: - Response Models

/// Top-level response from `/api/rest_v1/feed/onthisday/events/{M}/{D}`.
public struct WMFOnThisDayResponse: Codable, Sendable {
    /// General historical events.
    public let events: [WMFOnThisDayEvent]

    public init(events: [WMFOnThisDayEvent]) {
        self.events = events
    }
}

/// A single on-this-day event.
public struct WMFOnThisDayEvent: Codable, Sendable {
    /// Plain-text description of the event.
    public let text: String
    /// The year the event occurred (may be negative for BCE).
    public let year: Int
    /// Wikipedia article previews associated with this event.
    public let pages: [WMFOnThisDayPage]

    public init(text: String, year: Int, pages: [WMFOnThisDayPage]) {
        self.text = text
        self.year = year
        self.pages = pages
    }
}

/// Summarised Wikipedia article attached to an event.
public struct WMFOnThisDayPage: Codable, Sendable {
    public let title: String
    /// Short description of the article, if available.
    public let description: String?
    /// Short plain-text extract of the article.
    public let extract: String?
    /// Thumbnail image metadata, if available.
    public let thumbnail: WMFOnThisDayThumbnail?
    /// Canonical and mobile URLs for the article.
    public let contentUrls: WMFOnThisDayContentURLs?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case extract
        case thumbnail
        case contentUrls = "content_urls"
    }

    public init(
        title: String,
        description: String?,
        extract: String?,
        thumbnail: WMFOnThisDayThumbnail?,
        contentUrls: WMFOnThisDayContentURLs?
    ) {
        self.title = title
        self.description = description
        self.extract = extract
        self.thumbnail = thumbnail
        self.contentUrls = contentUrls
    }
}

/// Thumbnail metadata for a page.
public struct WMFOnThisDayThumbnail: Codable, Sendable {
    public let source: URL
    public let width: Int
    public let height: Int

    public init(source: URL, width: Int, height: Int) {
        self.source = source
        self.width = width
        self.height = height
    }
}

/// Desktop and mobile URL pair for a page.
public struct WMFOnThisDayContentURLs: Codable, Sendable {
    public let desktop: WMFOnThisDayURLPair?
    public let mobile: WMFOnThisDayURLPair?

    public init(desktop: WMFOnThisDayURLPair?, mobile: WMFOnThisDayURLPair?) {
        self.desktop = desktop
        self.mobile = mobile
    }
}

/// A single canonical page URL.
public struct WMFOnThisDayURLPair: Codable, Sendable {
    public let page: URL?

    public init(page: URL?) {
        self.page = page
    }
}
