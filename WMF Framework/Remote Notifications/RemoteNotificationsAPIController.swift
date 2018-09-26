struct RemoteNotificationsAPIController {
    
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

            enum CodingKeys: String, CodingKey {
                case wiki
                case type
                case category
                case id
                case message = "*"
                case timestamp
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
        let completion: (NotificationsResult?, URLResponse?, Error?) -> Void = { result, response, error in
            guard error == nil else {
                completion([], error)
                return
            }
            let notifications = self.notifications(from: result)
            completion(notifications, result?.error)
        }
        request(Query.notifications(from: subdomains, limit: .max, filter: .unread), completion: completion)
    }

    // MARK: Query parameters
    public func markAsRead(_ notifications: Set<RemoteNotification>, completion: @escaping (Error?) -> Void) {
        let maxNumberOfNotificationsPerRequest = 50

    private struct Query {
        typealias Parameters = [String: String]

        enum Wiki: Equatable {
            case all
            case single(String)
        guard notifications.count <= maxNumberOfNotificationsPerRequest else {
            // TODO: Split requests? 50 is the limit.
            assertionFailure()
            return
        }

            var value: String {
                switch self {
                case .all:
                    return "*"
                case .single(let name):
                    return "\(name)wiki"
                }
        request(Query.markAsRead(notifications: notifications), method: .post) { (result: MarkReadResult?, _, error) in
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

        static var allNotifications: Parameters {
            return notifications()
        }

        static var allUnreadNotifications: Parameters {
            return notifications(filter: .unread)
        }

        static var lastNotification: Parameters {
            return notifications(limit: .numeric(1))
        }

        static var lastUnreadNotification: Parameters {
            return notifications(limit: .numeric(1), filter: .unread)
        }

        static func notifications(for wiki: Wiki = .all, limit: Limit = .max, filter: Filter = .none) -> Parameters {
            return ["action": "query",
                    "format": "json",
                    "formatversion": "2",
                    "notformat": "model",
                    "meta": "notifications",
                    "notlimit": limit.value,
                    "notwikis": wiki.value,
                    "notfilter": filter.rawValue]
        }
    }
}

extension RemoteNotificationsAPIController.ResultError: LocalizedError {
    var errorDescription: String? {
        return info
    }
}
