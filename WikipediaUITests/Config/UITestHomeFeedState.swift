import Foundation

/// The Home feed state a test wants on device before launch.
/// Mirrors `UITestHomeFeedState` in the app, which decodes it from the launch arguments.
/// Launching with it also clears what earlier tests left in the Home feed: hidden cards, module
/// settings, the stored feeds, the reading history, and the page interests.
struct UITestHomeFeedState: Encodable {
    enum SeeFirst: String, Encodable {
        case community
        case personalized
    }

    let interestTopics: [String]
    let seeFirst: SeeFirst

    init(interestTopics: [String] = [], seeFirst: SeeFirst = .community) {
        self.interestTopics = interestTopics
        self.seeFirst = seeFirst
    }

    /// One interest topic, so the For You feed has one module of fixture-backed cards.
    static let oneInterest = UITestHomeFeedState(interestTopics: ["biography"])

    /// No interests and no reading history: the For You feed has no module.
    static let noInterests = UITestHomeFeedState()

    /// Base64 keeps the JSON out of the launch-argument plist parsing.
    var launchArgumentValue: String {
        guard let data = try? JSONEncoder().encode(self) else {
            preconditionFailure("UITestHomeFeedState must encode to JSON.")
        }
        return data.base64EncodedString()
    }
}

/// A request that fails as if the device were offline. The matchers are those of a row in
/// `TestNetworkFixtures.json`. `count` is the number of matching requests that fail before the
/// fixture answers again, so a retry can succeed. Without `count`, every matching request fails.
struct UITestOfflineRequest: Encodable {
    let host: String?
    let path: String?
    let pathPrefix: String?
    let queryItems: [String: String]?
    let count: Int?

    init(host: String? = nil, path: String? = nil, pathPrefix: String? = nil, queryItems: [String: String]? = nil, count: Int? = nil) {
        self.host = host
        self.path = path
        self.pathPrefix = pathPrefix
        self.queryItems = queryItems
        self.count = count
    }

    static func launchArgumentValue(for requests: [UITestOfflineRequest]) -> String {
        guard let data = try? JSONEncoder().encode(requests) else {
            preconditionFailure("UITestOfflineRequest must encode to JSON.")
        }
        return data.base64EncodedString()
    }
}
