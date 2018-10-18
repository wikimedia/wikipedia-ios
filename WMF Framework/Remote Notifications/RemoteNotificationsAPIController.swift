struct RemoteNotificationsAPIController {
    private let session: Session

    init(with session: Session) {
        self.session = session
    }
    
    // MARK: NotificationsAPI constants

    private struct NotificationsAPI {
        static let scheme = "https"
        static let host = "www.mediawiki.org"
        static let path = "/w/api.php"
    }

    // MARK: Decodable: NotificationsResult

    struct ResultError: Decodable {
        let code, info: String?
    }

    struct NotificationsResult: Decodable {
        struct Notification: Decodable, Hashable {
            let wiki: String?
            let type: String?
            let category: String?
            let id: String?
            let message: Message?
            let timestamp: Timestamp?
            let agent: Agent?
            let affectedPageID: AffectedPageID?

            enum CodingKeys: String, CodingKey {
                case wiki
                case type
                case category
                case id
                case message = "*"
                case timestamp
                case agent
                case affectedPageID = "title"
            }
        }
        struct Notifications: Decodable {
            let list: [Notification]
        }
        struct Query: Decodable {
            let notifications: Notifications?
        }
        struct Message: Decodable, Hashable {
            let header: String?
        }
        struct Timestamp: Decodable, Hashable {
            let utciso8601: String?
        }
        struct Agent: Decodable, Hashable {
            let name: String?
        }
        struct AffectedPageID: Decodable, Hashable {
            let full: String?
        }
        let error: ResultError?
        let query: Query?
    }

    // MARK: Decodable: MarkReadResult

    struct MarkReadResult: Decodable {
        let query: Query?
        let error: ResultError?

        var succeeded: Bool {
            return query?.markAsRead?.result == .success
        }

        struct Query: Decodable {
            let markAsRead: MarkedAsRead?

            enum CodingKeys: String, CodingKey {
                case markAsRead = "echomarkread"
            }
        }
        struct MarkedAsRead: Decodable {
            let result: Result?
        }
        enum Result: String, Decodable {
            case success
        }
    }

    enum MarkReadError: LocalizedError {
        case unknown
    }

    private func notifications(from result: NotificationsResult?) -> Set<NotificationsResult.Notification>? {
        guard let result = result else {
            return nil
        }
        guard let list = result.query?.notifications?.list else {
            return nil
        }
        return Set(list)
    }

    public func getAllUnreadNotifications(from subdomains: [String], completion: @escaping (Set<NotificationsResult.Notification>?, Error?) -> Void) {
        let completion: (NotificationsResult?, URLResponse?, Bool?, Error?) -> Void = { result, _, _, error in
            guard error == nil else {
                completion([], error)
                return
            }
            let notifications = self.notifications(from: result)
            completion(notifications, result?.error)
        }
        request(Query.notifications(from: subdomains, limit: .max, filter: .unread), completion: completion)
    }

    public func markAsRead(_ notifications: Set<RemoteNotification>, completion: @escaping (Error?) -> Void) {
        let maxNumberOfNotificationsPerRequest = 50

        guard notifications.count <= maxNumberOfNotificationsPerRequest else {
            // TODO: Split requests? 50 is the limit.
            assertionFailure()
            return
        }

        request(Query.markAsRead(notifications: notifications), method: .post) { (result: MarkReadResult?, _, _, error) in
            if let error = error {
                completion(error)
            }
            guard let result = result, result.succeeded else {
                assertionFailure()
                completion(MarkReadError.unknown)
                return
            }
            completion(result.error)
        }
    }

    private func request<T: Decodable>(_ queryParameters: Query.Parameters?, method: Session.Request.Method = .get, completion: @escaping (T?, URLResponse?, Bool?, Error?) -> Void) {
        if method == .get {
            let _ = session.jsonDecodableTask(host: NotificationsAPI.host, scheme: NotificationsAPI.scheme, method: .get, path: NotificationsAPI.path, queryParameters: queryParameters, completionHandler: completion)
        } else {
            let _ = session.requestWithCSRF(type: CSRFTokenJSONDecodableOperation.self, scheme: NotificationsAPI.scheme, host: NotificationsAPI.host, path: NotificationsAPI.path, method: method, queryParameters: queryParameters, bodyEncoding: .form, tokenContext: CSRFTokenOperation.TokenContext(tokenName: "token", tokenPlacement: .body, shouldPercentEncodeToken: true), completion: completion)
        }
    }

    // MARK: Query parameters

    private struct Query {
        typealias Parameters = [String: String]

        enum Limit {
            case max
            case numeric(Int)

            var value: String {
                switch self {
                case .max:
                    return "max"
                case .numeric(let number):
                    return "\(number)"
                }
            }
        }

        enum Filter: String {
            case read = "read"
            case unread = "!read"
            case none = "read|!read"
        }

        static func notifications(from subdomains: [String] = [], limit: Limit = .max, filter: Filter = .none) -> Parameters {
            var dictionary = ["action": "query",
                    "format": "json",
                    "formatversion": "2",
                    "notformat": "model",
                    "meta": "notifications",
                    "notlimit": limit.value,
                    "notfilter": filter.rawValue]

            let wikis = subdomains.compactMap { "\($0)wiki" }
            if let listOfWikis = WMFJoinedPropertyParameters(wikis) {
                dictionary["notwikis"] = listOfWikis
            }

            return dictionary
        }

        static func markAsRead(notifications: Set<RemoteNotification>) -> Parameters? {
            let IDs = notifications.compactMap { $0.id }
            let wikis = notifications.compactMap { $0.wiki }
            guard let listOfIDs = WMFJoinedPropertyParameters(IDs) else {
                assertionFailure("List of IDs cannot be nil")
                return nil
            }
            guard let listOfWikis = WMFJoinedPropertyParameters(wikis) else {
                assertionFailure("List of wikis cannot be nil")
                return nil
            }
            return ["action": "echomarkread",
                    "format": "json",
                    "wikis": listOfWikis,
                    "list": listOfIDs]
        }
    }
}

extension RemoteNotificationsAPIController.ResultError: LocalizedError {
    var errorDescription: String? {
        return info
    }
}
