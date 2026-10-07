import Foundation

/// One revision of a page. The MediaWiki action API returns this data in the `revisions` array.
public struct WMFPageRevision: Codable, Sendable, Equatable, Hashable {
    public let revisionID: Int
    public let parentID: Int
    public let user: String?
    public let revisionDate: Date?
    public let parsedComment: String?
    public let isAnon: Bool
    public let isMinor: Bool
    public let isTemp: Bool
    /// The size of the page in bytes after this revision.
    public let articleSizeAtRevision: Int
    /// The size difference in bytes between this revision and the parent revision.
    /// The value is 0 until the parent size is known.
    public var revisionSize: Int

    public init(revisionID: Int, parentID: Int, user: String?, revisionDate: Date?, parsedComment: String?, isAnon: Bool, isMinor: Bool, isTemp: Bool, articleSizeAtRevision: Int, revisionSize: Int = 0) {
        self.revisionID = revisionID
        self.parentID = parentID
        self.user = user
        self.revisionDate = revisionDate
        self.parsedComment = parsedComment
        self.isAnon = isAnon
        self.isMinor = isMinor
        self.isTemp = isTemp
        self.articleSizeAtRevision = articleSizeAtRevision
        self.revisionSize = revisionSize
    }

    enum CodingKeys: String, CodingKey {
        case revisionID = "revid"
        case parentID = "parentid"
        case user
        case revisionDate = "timestamp"
        case parsedComment = "parsedcomment"
        case isAnon = "anon"
        case isMinor = "minor"
        case isTemp = "temp"
        case articleSizeAtRevision = "size"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        revisionID = try container.decode(Int.self, forKey: .revisionID)
        parentID = try container.decodeIfPresent(Int.self, forKey: .parentID) ?? 0
        user = try container.decodeIfPresent(String.self, forKey: .user)
        parsedComment = try container.decodeIfPresent(String.self, forKey: .parsedComment)
        isAnon = try container.decodeIfPresent(Bool.self, forKey: .isAnon) ?? false
        isMinor = try container.decodeIfPresent(Bool.self, forKey: .isMinor) ?? false
        isTemp = try container.decodeIfPresent(Bool.self, forKey: .isTemp) ?? false
        articleSizeAtRevision = try container.decodeIfPresent(Int.self, forKey: .articleSizeAtRevision) ?? 0
        revisionSize = 0

        if let timestamp = try container.decodeIfPresent(String.self, forKey: .revisionDate) {
            revisionDate = DateFormatter.mediaWikiAPIDateFormatter.date(from: timestamp)
        } else {
            revisionDate = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(revisionID, forKey: .revisionID)
        try container.encode(parentID, forKey: .parentID)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(parsedComment, forKey: .parsedComment)
        try container.encode(isAnon, forKey: .isAnon)
        try container.encode(isMinor, forKey: .isMinor)
        try container.encode(isTemp, forKey: .isTemp)
        try container.encode(articleSizeAtRevision, forKey: .articleSizeAtRevision)
        if let revisionDate {
            try container.encode(DateFormatter.mediaWikiAPIDateFormatter.string(from: revisionDate), forKey: .revisionDate)
        }
    }

    /// The number of whole days between the revision date and now, in UTC.
    public func daysFromToday(now: Date = Date()) -> Int {
        guard let revisionDate else {
            return 0
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let start = calendar.startOfDay(for: revisionDate)
        let end = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}

/// One page of revisions from the action API, with the tokens for the next page.
public struct WMFPageRevisionsPage: Sendable, Equatable {
    public let title: String?
    /// The revisions in the order the API returned them. The `revisionSize` values are set for every revision except the last one.
    public let revisions: [WMFPageRevision]
    public let continueToken: String?
    public let rvContinueToken: String?
    public let batchComplete: Bool

    public init(title: String?, revisions: [WMFPageRevision], continueToken: String?, rvContinueToken: String?, batchComplete: Bool) {
        self.title = title
        self.revisions = revisions
        self.continueToken = continueToken
        self.rvContinueToken = rvContinueToken
        self.batchComplete = batchComplete
    }
}

/// Fetches the revision history of a page from the MediaWiki action API.
public actor WMFPageHistoryDataController {

    public enum Direction: String, Sendable {
        case older
        case newer
    }

    public static let shared = WMFPageHistoryDataController()

    private let basicService: WMFService?

    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService) {
        self.basicService = basicService
    }

    // MARK: - Public

    /// Fetch one page of revisions.
    ///
    /// The result sets `revisionSize` on each revision from the size of the next older revision in the same page.
    /// The last revision keeps a `revisionSize` of 0, unless it is the first revision of the page.
    /// - Parameters:
    ///   - project: The project of the page.
    ///   - title: The title of the page.
    ///   - limit: The maximum number of revisions to return.
    ///   - direction: The sort order of the revisions.
    ///   - startRevisionID: The revision to start from. The API includes this revision in the result.
    ///   - continueToken: The `continue` token from the previous page.
    ///   - rvContinueToken: The `rvcontinue` token from the previous page.
    public func fetchRevisions(project: WMFProject, title: String, limit: Int = 50, direction: Direction = .older, startRevisionID: Int? = nil, continueToken: String? = nil, rvContinueToken: String? = nil) async throws -> WMFPageRevisionsPage {
        var parameters: [String: Any] = [
            "action": "query",
            "prop": "revisions",
            "rvprop": "ids|timestamp|user|size|parsedcomment|flags",
            "rvlimit": String(limit),
            "rvdir": direction.rawValue,
            "titles": title,
            "continue": continueToken ?? "",
            "format": "json",
            "formatversion": "2"
        ]

        if let startRevisionID {
            parameters["rvstartid"] = String(startRevisionID)
        }

        if let rvContinueToken {
            parameters["rvcontinue"] = rvContinueToken
        }

        let response = try await performQuery(project: project, parameters: parameters)
        let page = response.query?.pages?.first

        var revisions = page?.revisions ?? []
        WMFPageHistoryDataController.setRevisionSizes(&revisions)

        return WMFPageRevisionsPage(
            title: page?.title,
            revisions: revisions,
            continueToken: response.continue?.continue,
            rvContinueToken: response.continue?.rvcontinue,
            batchComplete: response.batchcomplete ?? false
        )
    }

    /// Fetch the first revision of a page.
    public func fetchFirstRevision(project: WMFProject, title: String) async throws -> WMFPageRevision {
        let page = try await fetchRevisions(project: project, title: title, limit: 1, direction: .newer)
        guard let revision = page.revisions.first else {
            throw WMFDataControllerError.unexpectedResponse
        }
        return revision
    }

    /// Fetch one revision by ID.
    public func fetchRevision(project: WMFProject, title: String, revisionID: Int) async throws -> WMFPageRevision {
        let page = try await fetchRevisions(project: project, title: title, limit: 1, direction: .older, startRevisionID: revisionID)
        guard let revision = page.revisions.first else {
            throw WMFDataControllerError.unexpectedResponse
        }
        return revision
    }

    /// Fetch the revision next to a source revision.
    /// - Parameters:
    ///   - direction: `.older` returns the parent revision. `.newer` returns the child revision.
    public func fetchAdjacentRevision(project: WMFProject, title: String, revisionID: Int, direction: Direction) async throws -> WMFPageRevision {
        let page = try await fetchRevisions(project: project, title: title, limit: 2, direction: direction, startRevisionID: revisionID)
        guard let revision = page.revisions.first(where: { $0.revisionID != revisionID }) else {
            throw WMFDataControllerError.unexpectedResponse
        }
        return revision
    }

    /// Fetch the ID of the latest revision of a page. The request follows redirects.
    public func fetchLatestRevisionID(project: WMFProject, title: String) async throws -> Int {
        let parameters: [String: Any] = [
            "action": "query",
            "prop": "revisions",
            "rvprop": "ids",
            "rvlimit": "1",
            "redirects": "1",
            "titles": title,
            "format": "json",
            "formatversion": "2"
        ]

        let response = try await performQuery(project: project, parameters: parameters)
        guard let revisionID = response.query?.pages?.first?.revisions?.first?.revisionID else {
            throw WMFDataControllerError.unexpectedResponse
        }
        return revisionID
    }

    /// Set `revisionSize` on each revision from the size of the next older revision in the array.
    ///
    /// The array must be in `.older` order. The last revision gets its full size when it has no parent.
    public static func setRevisionSizes(_ revisions: inout [WMFPageRevision]) {
        guard !revisions.isEmpty else {
            return
        }
        for index in 0..<(revisions.count - 1) {
            revisions[index].revisionSize = revisions[index].articleSizeAtRevision - revisions[index + 1].articleSizeAtRevision
        }
        if let last = revisions.last, last.parentID == 0 {
            revisions[revisions.count - 1].revisionSize = last.articleSizeAtRevision
        }
    }

    // MARK: - Private

    private func performQuery(project: WMFProject, parameters: [String: Any]) async throws -> WMFPageRevisionsAPIResponse {
        guard let service = basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: parameters, acceptType: .json)
        return try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<WMFPageRevisionsAPIResponse, Error>) in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: - Response models

struct WMFPageRevisionsAPIResponse: Decodable, Sendable {
    let batchcomplete: Bool?
    let `continue`: WMFPageRevisionsAPIContinue?
    let query: WMFPageRevisionsAPIQuery?
}

struct WMFPageRevisionsAPIContinue: Decodable, Sendable {
    let `continue`: String?
    let rvcontinue: String?
}

struct WMFPageRevisionsAPIQuery: Decodable, Sendable {
    let pages: [WMFPageRevisionsAPIPage]?
}

struct WMFPageRevisionsAPIPage: Decodable, Sendable {
    let title: String?
    let missing: Bool?
    let revisions: [WMFPageRevision]?
}
