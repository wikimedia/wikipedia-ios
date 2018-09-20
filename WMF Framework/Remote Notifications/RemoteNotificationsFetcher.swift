struct RemoteNotificationsFetcher {

    // MARK: NotificationsAPI constants

    private struct NotificationsAPI {
        static let scheme = "https"
        static let host = "www.mediawiki.org"
        static let path = "/w/api.php"
    }

    // MARK: Decodable

    struct NotificationsAPIResult: Decodable {
        struct Error: Decodable {
            let code, info: String?
        }
        struct Notification: Decodable {
            let wiki: String?
            let type: Type?
            let category: Category?

            enum `Type`: String, Decodable {
                case talkPageEdit = "edit-user-talk"
                case thankYouEdit = "thank-you-edit"
                case loginSuccess = "login-success"
                case editReverted = "reverted"
            }

            enum Category: String, Decodable {
                case system
                case loginSuccess = "login-success"
                case talkPageEdit = "edit-user-talk"
            }
        }
        struct Notifications: Decodable {
            let list: [Notification]
        }
        struct Query: Decodable {
            let notifications: Notifications?
        }
        let error: Error?
        let query: Query?
    }

    private func notifications(from result: NotificationsAPIResult?) -> [NotificationsAPIResult.Notification] {
        guard let result = result else {
            return []
        }
        return result.query?.notifications?.list ?? []
    }

    public func getAllNotifications() {
        request(Query.allNotifications)
    }

    public func getAllUnreadNotifications() {
        request(Query.allUnreadNotifications)
    }

    private func request(_ queryParameters: Query.Parameters) {
        let _ = Session.shared.requestWithCSRF(type: CSRFTokenJSONDecodableOperation.self, scheme: NotificationsAPI.scheme, host: NotificationsAPI.host, path: NotificationsAPI.path, method: .get, queryParameters: queryParameters, bodyEncoding: .form, tokenContext: CSRFTokenOperation.TokenContext(tokenName: "token", tokenPlacement: .body, shouldPercentEncodeToken: false), operationCompletion: completion)
    }

    private func completion(result: NotificationsAPIResult?, response: URLResponse?, error: Error?) {
        guard error == nil else {
            assertionFailure()
            return
        }
        guard result?.error == nil else {
            return
        }
        let n = self.notifications(from: result)
        print(n)
    }

    // MARK: Query parameters

    private struct Query {
        typealias Parameters = [String: String]

        enum Wiki: Equatable {
            case all
            case single(String)

            var value: String {
                switch self {
                case .all:
                    return "*"
                case .single(let name):
                    return "\(name)wiki"
                }
            }
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

extension RemoteNotificationsFetcher.NotificationsAPIResult.Error: LocalizedError {
    var errorDescription: String? {
        return info
    }
}
