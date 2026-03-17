import Foundation

public struct PerformerData: Encodable {
    public var id: Int?
    public var name: String?
    public var isLoggedIn: Bool?
    public var isTemp: Bool?
    public var sessionId: String?
    public var pageviewId: String?
    public var groups: [String]?
    public var languageGroups: String?
    public var languagePrimary: String?
    public var registrationDt: Date?

    public init(
        id: Int? = nil,
        name: String? = nil,
        isLoggedIn: Bool? = nil,
        isTemp: Bool? = nil,
        sessionId: String? = nil,
        pageviewId: String? = nil,
        groups: [String]? = nil,
        languageGroups: String? = nil,
        languagePrimary: String? = nil,
        registrationDt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.isLoggedIn = isLoggedIn
        self.isTemp = isTemp
        self.sessionId = sessionId
        self.pageviewId = pageviewId
        self.groups = groups
        self.languageGroups = languageGroups
        self.languagePrimary = languagePrimary
        self.registrationDt = registrationDt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isLoggedIn = "is_logged_in"
        case isTemp = "is_temp"
        case sessionId = "session_id"
        case pageviewId = "pageview_id"
        case groups
        case languageGroups = "language_groups"
        case languagePrimary = "language_primary"
        case registrationDt = "registration_dt"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(isLoggedIn, forKey: .isLoggedIn)
        try container.encodeIfPresent(isTemp, forKey: .isTemp)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        try container.encodeIfPresent(pageviewId, forKey: .pageviewId)
        try container.encodeIfPresent(groups, forKey: .groups)
        try container.encodeIfPresent(languageGroups, forKey: .languageGroups)
        try container.encodeIfPresent(languagePrimary, forKey: .languagePrimary)
        if let registrationDt {
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: registrationDt), forKey: .registrationDt)
        }
    }
}
