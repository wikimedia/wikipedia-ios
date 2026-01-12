import Foundation

struct UserContributionsAPIResponse: Codable {
    let batchcomplete: Bool?
    let `continue`: ContinueData?
    let query: UserContributionsQuery?

    struct ContinueData: Codable {
        let uccontinue: String?
    }

    struct UserContributionsQuery: Codable {
        let usercontribs: [UserContribution]
    }
}

struct UserContribution: Codable {
    let userid: Int
    let user: String
    let pageid: Int
    let revid: Int
    let parentid: Int
    let ns: Int
    let title: String
    let timestamp: String
    let isNew: Bool?
    let isMinor: Bool?
    let isTop: Bool?
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case userid, user, pageid, revid, parentid, ns, title, timestamp, tags
        case isNew = "new"
        case isMinor = "minor"
        case isTop = "top"
    }
}
