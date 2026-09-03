import Foundation

/// One announcement from the `feed/announcements` REST endpoint.
public struct WMFFeedAnnouncement: Codable, Sendable, Equatable {
    public let identifier: String
    public let type: String?
    public let startTime: Date?
    public let endTime: Date?
    public let platforms: [String]
    public let countries: [String]
    public let placement: String?
    public let text: String?
    public let actionTitle: String?
    public let actionURLString: String?
    public let captionHTML: String?
    public let imageURLString: String?
    public let imageHeight: Int?
    public let negativeText: String?
    public let loggedIn: Bool?
    public let readingListSyncEnabled: Bool?
    public let beta: Bool?
    public let domain: String?
    public let articleTitles: [String]?
    public let percentReceivingExperiment: Int?
    public let displayDelay: Int?

    public init(identifier: String, type: String?, startTime: Date?, endTime: Date?, platforms: [String], countries: [String], placement: String?, text: String?, actionTitle: String?, actionURLString: String?, captionHTML: String?, imageURLString: String?, imageHeight: Int?, negativeText: String?, loggedIn: Bool?, readingListSyncEnabled: Bool?, beta: Bool?, domain: String?, articleTitles: [String]?, percentReceivingExperiment: Int?, displayDelay: Int?) {
        self.identifier = identifier
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.platforms = platforms
        self.countries = countries
        self.placement = placement
        self.text = text
        self.actionTitle = actionTitle
        self.actionURLString = actionURLString
        self.captionHTML = captionHTML
        self.imageURLString = imageURLString
        self.imageHeight = imageHeight
        self.negativeText = negativeText
        self.loggedIn = loggedIn
        self.readingListSyncEnabled = readingListSyncEnabled
        self.beta = beta
        self.domain = domain
        self.articleTitles = articleTitles
        self.percentReceivingExperiment = percentReceivingExperiment
        self.displayDelay = displayDelay
    }

    public var actionURL: URL? {
        guard let actionURLString else { return nil }
        return URL(string: actionURLString)
    }

    public var imageURL: URL? {
        guard let imageURLString else { return nil }
        return URL(string: imageURLString)
    }

    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case type
        case startTime = "start_time"
        case endTime = "end_time"
        case platforms
        case countries
        case placement
        case text
        case action
        case captionHTML = "caption_HTML"
        case image
        case imageURL = "image_url"
        case imageHeight = "image_height"
        case negativeText = "negative_text"
        case loggedIn = "logged_in"
        case readingListSyncEnabled = "reading_list_sync_enabled"
        case beta
        case domain
        case articleTitles
        case percentReceivingExperiment = "percent_receiving_experiment"
        case displayDelay
    }

    private enum ActionKeys: String, CodingKey {
        case title
        case url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        platforms = try container.decodeIfPresent([String].self, forKey: .platforms) ?? []
        countries = try container.decodeIfPresent([String].self, forKey: .countries) ?? []
        placement = try container.decodeIfPresent(String.self, forKey: .placement)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        captionHTML = try container.decodeIfPresent(String.self, forKey: .captionHTML)
        imageHeight = try container.decodeIfPresent(Int.self, forKey: .imageHeight)
        negativeText = try container.decodeIfPresent(String.self, forKey: .negativeText)
        loggedIn = try container.decodeIfPresent(Bool.self, forKey: .loggedIn)
        readingListSyncEnabled = try container.decodeIfPresent(Bool.self, forKey: .readingListSyncEnabled)
        beta = try container.decodeIfPresent(Bool.self, forKey: .beta)
        domain = try container.decodeIfPresent(String.self, forKey: .domain)
        articleTitles = try container.decodeIfPresent([String].self, forKey: .articleTitles)
        percentReceivingExperiment = try container.decodeIfPresent(Int.self, forKey: .percentReceivingExperiment)
        displayDelay = try container.decodeIfPresent(Int.self, forKey: .displayDelay)

        // The endpoint uses `image` or `image_url` for the same value.
        imageURLString = try container.decodeIfPresent(String.self, forKey: .image) ?? container.decodeIfPresent(String.self, forKey: .imageURL)

        if let action = try? container.nestedContainer(keyedBy: ActionKeys.self, forKey: .action) {
            actionTitle = try action.decodeIfPresent(String.self, forKey: .title)
            actionURLString = try action.decodeIfPresent(String.self, forKey: .url)
        } else {
            actionTitle = nil
            actionURLString = nil
        }

        let formatter = DateFormatter.mediaWikiAPIDateFormatter
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime).flatMap { formatter.date(from: $0) }
        endTime = try container.decodeIfPresent(String.self, forKey: .endTime).flatMap { formatter.date(from: $0) }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encode(platforms, forKey: .platforms)
        try container.encode(countries, forKey: .countries)
        try container.encodeIfPresent(placement, forKey: .placement)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(captionHTML, forKey: .captionHTML)
        try container.encodeIfPresent(imageURLString, forKey: .imageURL)
        try container.encodeIfPresent(imageHeight, forKey: .imageHeight)
        try container.encodeIfPresent(negativeText, forKey: .negativeText)
        try container.encodeIfPresent(loggedIn, forKey: .loggedIn)
        try container.encodeIfPresent(readingListSyncEnabled, forKey: .readingListSyncEnabled)
        try container.encodeIfPresent(beta, forKey: .beta)
        try container.encodeIfPresent(domain, forKey: .domain)
        try container.encodeIfPresent(articleTitles, forKey: .articleTitles)
        try container.encodeIfPresent(percentReceivingExperiment, forKey: .percentReceivingExperiment)
        try container.encodeIfPresent(displayDelay, forKey: .displayDelay)

        if actionTitle != nil || actionURLString != nil {
            var action = container.nestedContainer(keyedBy: ActionKeys.self, forKey: .action)
            try action.encodeIfPresent(actionTitle, forKey: .title)
            try action.encodeIfPresent(actionURLString, forKey: .url)
        }

        let formatter = DateFormatter.mediaWikiAPIDateFormatter
        try container.encodeIfPresent(startTime.map { formatter.string(from: $0) }, forKey: .startTime)
        try container.encodeIfPresent(endTime.map { formatter.string(from: $0) }, forKey: .endTime)
    }
}

/// Fetches announcements for the Explore feed.
public actor WMFAnnouncementsDataController {

    /// The platform name that the announcements endpoint uses for this app.
    public static let iOSPlatform = "iOSAppV5"

    public static let shared = WMFAnnouncementsDataController()

    private let basicService: WMFService?

    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService) {
        self.basicService = basicService
    }

    /// Fetch all announcements for the project. The result is not filtered.
    public func fetchAnnouncements(project: WMFProject) async throws -> [WMFFeedAnnouncement] {
        guard let service = basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard let url = URL.wikimediaRestAPIURL(project: project, additionalPathComponents: ["feed", "announcements"]) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: [:], acceptType: .json)
        let response: WMFFeedAnnouncementsAPIResponse = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<WMFFeedAnnouncementsAPIResponse, Error>) in
                continuation.resume(with: result)
            }
        }

        return response.announce ?? []
    }

    /// Keep the announcements that target this app and the country of the user.
    /// - Parameters:
    ///   - countryCode: The country code from the GeoIP cookie. Announcements with a country list need a match. Announcements without a country list always pass.
    public static func filter(_ announcements: [WMFFeedAnnouncement], countryCode: String?) -> [WMFFeedAnnouncement] {
        return announcements.filter { announcement in
            guard announcement.platforms.contains(iOSPlatform) else {
                return false
            }
            guard !announcement.countries.isEmpty else {
                return true
            }
            guard let countryCode else {
                return false
            }
            return announcement.countries.contains { countryCode.hasPrefix($0) }
        }
    }
}

// MARK: - Response models

struct WMFFeedAnnouncementsAPIResponse: Decodable, Sendable {
    let announce: [WMFFeedAnnouncement]?
}
