import Foundation

/// Fetches per-page counts used to give readers a sense of an article's provenance: how many
/// editors have contributed to it and how many references it cites. Results are cached in memory,
/// and concurrent requests for the same count share one network call.
public actor WMFPageStatsDataController {

    public static let shared = WMFPageStatsDataController()

    private var cache: [String: Int] = [:]
    private var inFlightRequests: [String: Task<Int, Error>] = [:]

    private var basicService: WMFService? { WMFDataEnvironment.current.basicService }

    public init() {}

    /// Number of distinct editors who have contributed to the page.
    public func fetchContributorCount(title: String, project: WMFProject) async throws -> Int {
        try await count(forKey: "contributors-\(project.id)-\(title)") { [self] in
            try await performContributorCountFetch(title: title, project: project)
        }
    }

    /// Number of references the page cites.
    public func fetchReferenceCount(title: String, project: WMFProject) async throws -> Int {
        try await count(forKey: "references-\(project.id)-\(title)") { [self] in
            try await performReferenceCountFetch(title: title, project: project)
        }
    }

    // MARK: - Caching

    private func count(forKey key: String, fetch: @escaping @Sendable () async throws -> Int) async throws -> Int {

        if let cachedCount = cache[key] {
            return cachedCount
        }

        if let inFlightRequest = inFlightRequests[key] {
            return try await inFlightRequest.value
        }

        let task = Task { try await fetch() }
        inFlightRequests[key] = task

        do {
            let count = try await task.value
            inFlightRequests[key] = nil
            cache[key] = count
            return count
        } catch {
            inFlightRequests[key] = nil
            throw error
        }
    }

    // MARK: - Fetching

    private func performContributorCountFetch(title: String, project: WMFProject) async throws -> Int {

        guard let basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard !title.isEmpty,
              let url = URL.mediaWikiRestAPIURL(project: project, additionalPathComponents: ["v1", "page", title.spacesToUnderscores, "history", "counts", "editors"]) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, acceptType: .json)

        let response: EditorCountResponse = try await withCheckedThrowingContinuation { continuation in
            basicService.performDecodableGET(request: request) { (result: Result<EditorCountResponse, Error>) in
                continuation.resume(with: result)
            }
        }

        guard let count = response.count else {
            throw WMFDataControllerError.unexpectedResponse
        }

        return count
    }

    private func performReferenceCountFetch(title: String, project: WMFProject) async throws -> Int {

        guard let basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard !title.isEmpty,
              let url = URL.mediaWikiRestAPIURL(project: project, additionalPathComponents: ["attribution", "v0-beta", "pages", title.spacesToUnderscores, "signals"]) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let parameters: [String: Any] = [
            "redirect": "true",
            "expand": "trust_and_relevance"
        ]

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: parameters, acceptType: .json)

        let response: AttributionSignalsResponse = try await withCheckedThrowingContinuation { continuation in
            basicService.performDecodableGET(request: request) { (result: Result<AttributionSignalsResponse, Error>) in
                continuation.resume(with: result)
            }
        }

        guard let count = response.trustAndRelevance?.referenceCount else {
            throw WMFDataControllerError.unexpectedResponse
        }

        return count
    }

    @_spi(Testing) public func reset() {
        cache.removeAll()
        inFlightRequests.removeAll()
    }
}

// MARK: - API Responses

private struct EditorCountResponse: Decodable {
    let count: Int?
}

private struct AttributionSignalsResponse: Decodable {

    struct TrustAndRelevance: Decodable {
        let referenceCount: Int?

        enum CodingKeys: String, CodingKey {
            case referenceCount = "reference_count"
        }
    }

    let trustAndRelevance: TrustAndRelevance?

    enum CodingKeys: String, CodingKey {
        case trustAndRelevance = "trust_and_relevance"
    }
}
