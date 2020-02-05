public struct References: Codable {
    public let revision: String
    public let tid: String
    public let referenceLists: [ReferenceList]
    public let referencesByID: [String: Reference]
    enum CodingKeys: String, CodingKey {
        case revision
        case tid
        case referenceLists = "reference_lists"
        case referencesByID = "references_by_id"
    }
}

public struct Reference: Codable {
    public struct BackLink: Codable {
        public let href: String
        public let text: String
    }
    public struct Content: Codable {
        public let html: String
        public let type: String?
    }
    public let backLinks: [BackLink]
    public let content: Content
    enum CodingKeys: String, CodingKey {
        case backLinks = "back_links"
        case content
    }
}

public struct ReferenceList: Codable {
    public struct Heading: Codable {
        public let id: String
        public let html: String
    }
    public let id: String
    public let heading: Heading
    public let order: [String]
    enum CodingKeys: String, CodingKey {
        case id
        case order
        case heading = "section_heading"
    }
}
