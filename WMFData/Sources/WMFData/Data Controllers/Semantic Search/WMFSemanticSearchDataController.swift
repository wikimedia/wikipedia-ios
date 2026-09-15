import Foundation

public final class WMFSemanticSearchDataController {

    public enum ExperimentAssignment: String, Sendable {
        case control
        case groupB
    }

    public enum ExperimentError: Error {
        case missingExperimentStore
        case unexpectedBucketValue
    }

    public static let shared = WMFSemanticSearchDataController()

    // TODO: Remove when the `iosv1.semanticSearchLanguages` in the remote feature config is available.
    public static let defaultTargetLanguageCodes = ["fr", "ar", "ja"]

    private static let experimentControlPercentage = 50

    private var experimentStore: WMFKeyValueStore? { WMFDataEnvironment.current.sharedCacheStore }

    private let stateLock = NSLock()

    private init() {}

    // MARK: - Availability

    /// True when the semantic search entry point can render for a search in `languageCode`.
    /// The developer toggle, the target language gate and the experiment bucket must all pass.
    public func isEntryPointAvailable(languageCode: String) -> Bool {
        guard isEligible(languageCode: languageCode) else {
            return false
        }

        return experimentAssignment == .groupB
    }

    /// True when a search in `languageCode` can enroll the reader in the experiment.
    public func isEligible(languageCode: String) -> Bool {
        guard WMFDeveloperSettingsDataController.shared.enableSemanticSearch else {
            return false
        }

        if developerSettingsForcedAssignment != nil {
            return true
        }

        return isTargetLanguage(languageCode: languageCode)
    }

    public func isTargetLanguage(languageCode: String) -> Bool {
        targetLanguageCodes.contains(languageCode)
    }

    /// The languages from `iosv1.semanticSearchLanguages` in the remote feature config. Until the
    /// remote config has the key, the default target languages apply.
    public var targetLanguageCodes: [String] {
        let remoteLanguageCodes = WMFDeveloperSettingsDataController.shared.loadFeatureConfig()?.ios.semanticSearchLanguages ?? []
        return remoteLanguageCodes.isEmpty ? Self.defaultTargetLanguageCodes : remoteLanguageCodes
    }

    // MARK: - Experiment Assignment

    /// Rolls the experiment bucket the first time a reader runs an eligible search, and returns
    /// the persisted bucket after that. Returns nil when the search is not eligible.
    @discardableResult
    public func assignExperimentIfNeeded(languageCode: String) throws -> ExperimentAssignment? {
        stateLock.lock()
        defer { stateLock.unlock() }

        guard isEligible(languageCode: languageCode) else {
            return nil
        }

        guard let experimentStore else {
            throw ExperimentError.missingExperimentStore
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        let bucketValue = try experimentsDataController.determineBucketForExperiment(.semanticSearch, withPercentage: Self.experimentControlPercentage)

        guard let assignment = ExperimentAssignment(bucketValue: bucketValue) else {
            throw ExperimentError.unexpectedBucketValue
        }

        return developerSettingsForcedAssignment ?? assignment
    }

    public var experimentAssignment: ExperimentAssignment? {
        if let developerSettingsForcedAssignment {
            return developerSettingsForcedAssignment
        }

        guard let experimentStore else {
            return nil
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        guard let bucketValue = experimentsDataController.bucketForExperiment(.semanticSearch) else {
            return nil
        }

        return ExperimentAssignment(bucketValue: bucketValue)
    }

    public func clearExperimentAssignment() throws {
        guard let experimentStore else {
            throw ExperimentError.missingExperimentStore
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        try experimentsDataController.resetExperiment(.semanticSearch)
    }

    // Overrides assignment at read time only, so the persisted bucket survives
    // turning the developer setting back off.
    private var developerSettingsForcedAssignment: ExperimentAssignment? {
        WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment
    }

    // MARK: - Results

    /// Number of results requested per page. This is the lever for tuning page size - the API
    /// itself defaults to 10 when `gsrlimit` is absent. Max allowed by the API is 500.
    public static let resultsPerPage = 10

    private var basicService: WMFService? { WMFDataEnvironment.current.basicService }

    /// Runs a semantic search against the project's MediaWiki search API. Snippets may contain
    /// `<span class="searchmatch">` markup, so callers are responsible for rendering the HTML.
    ///
    /// - Parameter continuation: pass the `continuation` from a previous page's response to fetch
    /// the next page. A nil continuation fetches the first page.
    public func fetchResults(searchTerm: String, project: WMFProject, limit: Int = WMFSemanticSearchDataController.resultsPerPage, continuation: WMFSemanticSearchContinuation? = nil) async throws -> WMFSemanticSearchPage {

        guard let basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard !searchTerm.isEmpty,
              let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        var parameters: [String: Any] = [
            "action": "query",
            "format": "json",
            "formatversion": "2",
            "generator": "search",
            "gsrsearch": searchTerm,
            "gsrprop": "snippet|sectiontitle",
            "gsrlimit": String(limit),
            "cirrusSemanticSearch": "1",
            "prop": "pageimages",
            "piprop": "thumbnail"
        ]

        if let continuation {
            parameters["gsroffset"] = String(continuation.offset)
            parameters["continue"] = continuation.continueValue
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: parameters, acceptType: .json)

        let response: SemanticSearchResponse = try await withCheckedThrowingContinuation { taskContinuation in
            basicService.performDecodableGET(request: request) { (result: Result<SemanticSearchResponse, Error>) in
                taskContinuation.resume(with: result)
            }
        }

        let pages = response.query?.pages ?? []

        // The generator returns pages in arbitrary order. `index` carries the search ranking.
        let results = pages
            .sorted { ($0.index ?? .max) < ($1.index ?? .max) }
            .map { page in
                WMFSemanticSearchResult(
                    pageID: page.pageid,
                    title: page.title,
                    snippetHTML: page.snippet,
                    sectionTitle: page.sectiontitle,
                    thumbnailURL: page.thumbnail?.source.flatMap { URL(string: $0) }
                )
            }

        var nextContinuation: WMFSemanticSearchContinuation?
        if let offset = response.continueData?.gsroffset,
           let continueValue = response.continueData?.continueValue {
            nextContinuation = WMFSemanticSearchContinuation(offset: offset, continueValue: continueValue)
        }

        return WMFSemanticSearchPage(results: results, continuation: nextContinuation)
    }
}

// MARK: - Result Models

/// One page of search results plus the token needed to request the following page.
public struct WMFSemanticSearchPage: Sendable {
    public let results: [WMFSemanticSearchResult]

    /// Nil when the API reported no further results.
    public let continuation: WMFSemanticSearchContinuation?

    public init(results: [WMFSemanticSearchResult], continuation: WMFSemanticSearchContinuation?) {
        self.results = results
        self.continuation = continuation
    }
}

/// Opaque paging token mirroring the API's `continue` object.
public struct WMFSemanticSearchContinuation: Sendable, Equatable {
    public let offset: Int
    public let continueValue: String

    public init(offset: Int, continueValue: String) {
        self.offset = offset
        self.continueValue = continueValue
    }
}

public struct WMFSemanticSearchResult: Sendable, Identifiable {
    public let pageID: Int
    public let title: String

    /// Raw snippet from the API. May contain `<span class="searchmatch">` markup.
    public let snippetHTML: String?
    public let sectionTitle: String?
    public let thumbnailURL: URL?

    public var id: Int { pageID }

    public init(pageID: Int, title: String, snippetHTML: String?, sectionTitle: String?, thumbnailURL: URL?) {
        self.pageID = pageID
        self.title = title
        self.snippetHTML = snippetHTML
        self.sectionTitle = sectionTitle
        self.thumbnailURL = thumbnailURL
    }
}

// MARK: - API Response

private struct SemanticSearchResponse: Decodable {

    struct Query: Decodable {

        struct Page: Decodable {

            struct Thumbnail: Decodable {
                let source: String?
            }

            let pageid: Int
            let title: String
            let snippet: String?
            let sectiontitle: String?
            let index: Int?
            let thumbnail: Thumbnail?
        }

        let pages: [Page]?
    }

    struct Continue: Decodable {
        let gsroffset: Int?
        let continueValue: String?

        enum CodingKeys: String, CodingKey {
            case gsroffset
            case continueValue = "continue"
        }
    }

    let query: Query?
    let continueData: Continue?

    enum CodingKeys: String, CodingKey {
        case query
        case continueData = "continue"
    }
}

private extension WMFSemanticSearchDataController.ExperimentAssignment {
    init?(bucketValue: WMFExperimentsDataController.BucketValue) {
        switch bucketValue {
        case .semanticSearchControl:
            self = .control
        case .semanticSearchGroupB:
            self = .groupB
        default:
            return nil
        }
    }
}
