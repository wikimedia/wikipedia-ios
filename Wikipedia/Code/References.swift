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
    
    public init(revision: String, tid: String, referenceLists: [ReferenceList], referencesByID: [String: Reference]) {
        self.revision = revision
        self.tid = tid
        self.referenceLists = referenceLists
        self.referencesByID = referencesByID
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
        
        public init(html: String, type: String?) {
            self.html = html
            self.type = type
        }
    }
    public let backLinks: [BackLink]
    public let content: Content
    enum CodingKeys: String, CodingKey {
        case backLinks = "back_links"
        case content
    }
    
    public init(backLinks: [BackLink], content: Content) {
        self.backLinks = backLinks
        self.content = content
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
