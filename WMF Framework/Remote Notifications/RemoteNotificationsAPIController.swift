import CocoaLumberjackSwift

public class RemoteNotificationsAPIController: Fetcher {
    // MARK: NotificationsAPI constants

    private struct NotificationsAPI {
        static let components: URLComponents = {
            var components = URLComponents()
            components.scheme = "https"
            components.host = "www.mediawiki.org"
            components.path = "/w/api.php"
            return components
        }()
    }

    // MARK: Decodable: NotificationsResult

    struct ResultError: Decodable {
        let code, info: String?
    }

    public struct NotificationsResult: Decodable {
        
        struct Query: Decodable {
            
            struct Notifications: Decodable {
                let list: [Notification]
                let continueId: String?
                
                enum CodingKeys: String, CodingKey {
                    case list
                    case continueId = "continue"
                }
            }
            
            let notifications: Notifications?
        }
        
        let error: ResultError?
        let query: Query?
        
        public struct Notification: Codable, Hashable {
            
            struct Timestamp: Codable, Hashable {
                let utciso8601: String
                let utcunix: String
                
                enum CodingKeys: String, CodingKey {
                    case utciso8601
                    case utcunix
                }
                
                init(from decoder: Decoder) throws {
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    utciso8601 = try values.decode(String.self, forKey: .utciso8601)
                    do {
                        utcunix = String(try values.decode(Int.self, forKey: .utcunix))
                    } catch {
                        utcunix = try values.decode(String.self, forKey: .utcunix)
                    }
                }
            }
            struct Agent: Codable, Hashable {
                let id: String?
                let name: String?
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                }
                
                init(from decoder: Decoder) throws {
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    name = try values.decode(String.self, forKey: .name)
                    do {
                        id = String(try values.decode(Int.self, forKey: .id))
                    } catch {
                        id = try values.decode(String.self, forKey: .id)
                    }
                }
            }
            struct Title: Codable, Hashable {
                let full: String?
                let namespace: String?
                let namespaceKey: Int?
                let text: String?
                
                enum CodingKeys: String, CodingKey {
                    case full
                    case namespace
                    case namespaceKey = "namespace-key"
                    case text
                }
            }
            
            struct Message: Codable, Hashable {
                let header: String?
                let body: String?
                let links: RemoteNotificationLinks?
            }
            
            let wiki: String
            let id: String
            let type: String
            let category: String
            let section: String
            let timestamp: Timestamp
            let title: Title?
            let agent: Agent?
            let readString: String?
            let revisionID: String?
            let message: Message?

            enum CodingKeys: String, CodingKey {
                case wiki
                case id
                case type
                case category
                case section
                case timestamp
                case title = "title"
                case agent
                case readString = "read"
                case revisionID = "revid"
                case message = "*"
            }
            
            public func hash(into hasher: inout Hasher) {
                hasher.combine(key)
            }
            
            public static func ==(lhs: Notification, rhs: Notification) -> Bool {
                return lhs.key == rhs.key &&
                    lhs.readString == rhs.readString
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                wiki = try values.decode(String.self, forKey: .wiki)
                do {
                    id = String(try values.decode(Int.self, forKey: .id))
                } catch {
                    id = try values.decode(String.self, forKey: .id)
                }
                
                type = try values.decode(String.self, forKey: .type)
                category = try values.decode(String.self, forKey: .category)
                section = try values.decode(String.self, forKey: .section)
                timestamp = try values.decode(Timestamp.self, forKey: .timestamp)
                title = try? values.decode(Title.self, forKey: .title)
                agent = try? values.decode(Agent.self, forKey: .agent)
                readString = try? values.decode(String.self, forKey: .readString)
                
                if let intRevID = try? values.decode(Int.self, forKey: .revisionID) {
                    revisionID = String(intRevID)
                } else {
                    revisionID = (try? values.decode(String.self, forKey: .revisionID)) ?? nil
                }
                
                message = try? values.decode(Message.self, forKey: .message)
            }
        }
        
        
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
        case noResult
        case unknown
        case multiple([Error])
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
    public func getUnreadPushNotifications(from project: RemoteNotificationsProject, completion: @escaping (Set<NotificationsResult.Notification>, Error?) -> Void) {
        let completion: (NotificationsResult?, URLResponse?, Error?) -> Void = { result, _, error in
            guard error == nil else {
                completion([], error)
                return
            }
            let result = result?.query?.notifications?.list ?? []
            completion(Set(result), nil)
        }
        request(project: project, queryParameters: Query.notifications(limit: .max, filter: .unread, notifierType: .push, continueId: nil), completion: completion)
    }
    
    func getAllNotifications(from project: RemoteNotificationsProject, continueId: String?, completion: @escaping (NotificationsResult.Query.Notifications?, Error?) -> Void) {
        let completion: (NotificationsResult?, URLResponse?, Error?) -> Void = { result, _, error in
            guard error == nil else {
                completion(nil, error)
                return
            }
            completion(result?.query?.notifications, result?.error)
        }
        
        request(project: project, queryParameters: Query.notifications(from: [project], limit: .max, filter: .none, continueId: continueId), completion: completion)
    }
    
    public func markAllAsRead(project: RemoteNotificationsProject, completion: @escaping (Error?) -> Void) {
        
        request(project: project, queryParameters: Query.markAllAsRead(project: project), method: .post) { (result: MarkReadResult?, _, error) in
            if let error = error {
                completion(error)
                return
            }
            guard let result = result else {
                assertionFailure("Expected result; make sure MarkReadResult maps the expected result correctly")
                completion(MarkReadError.noResult)
                return
            }
            if let error = result.error {
                completion(error)
                return
            }
            if !result.succeeded {
                completion(MarkReadError.unknown)
                return
            }
            completion(nil)
        }
    }

    public func markAsReadOrUnread(project: RemoteNotificationsProject, identifierGroups: Set<RemoteNotification.IdentifierGroup>, shouldMarkRead: Bool, completion: @escaping (Error?) -> Void) {
        let maxNumberOfNotificationsPerRequest = 50
        let identifierGroups = Array(identifierGroups)
        let split = identifierGroups.chunked(into: maxNumberOfNotificationsPerRequest)

        split.asyncCompactMap({ (identifierGroups, completion: @escaping (Error?) -> Void) in
            request(project: project, queryParameters: Query.markAsReadOrUnread(identifierGroups: identifierGroups, shouldMarkRead: shouldMarkRead), method: .post) { (result: MarkReadResult?, _, error) in
                if let error = error {
                    completion(error)
                    return
                }
                guard let result = result else {
                    assertionFailure("Expected result; make sure MarkReadResult maps the expected result correctly")
                    completion(MarkReadError.noResult)
                    return
                }
                if let error = result.error {
                    completion(error)
                    return
                }
                if !result.succeeded {
                    completion(MarkReadError.unknown)
                    return
                }
                completion(nil)
            }
        }) { (errors) in
            if errors.isEmpty {
                completion(nil)
            } else {
                DDLogError("\(errors.count) of \(split.count) mark as read requests failed")
                completion(MarkReadError.multiple(errors))
            }
        }
    }

    private func request<T: Decodable>(project: RemoteNotificationsProject?, queryParameters: Query.Parameters?, method: Session.Request.Method = .get, completion: @escaping (T?, URLResponse?, Error?) -> Void) {
        
        let url: URL?
        if let project = project {
            switch project {
            case .commons:
                url = configuration.commonsAPIURLComponents(with: queryParameters).url
            case .wikidata:
                url = configuration.wikidataAPIURLComponents(with: queryParameters).url
            case .language(let languageCode, _, _):
                url = configuration.mediaWikiAPIURLForLanguageCode(languageCode, with: queryParameters).url
            }
        } else {
            var components = NotificationsAPI.components
            components.replacePercentEncodedQueryWithQueryParameters(queryParameters)
            url = components.url
        }
        
        guard let url = url else {
            completion(nil, nil, RequestError.invalidParameters)
            return
        }
        
        if method == .get {
            session.jsonDecodableTask(with: url, method: .get, completionHandler: completion)
        } else {
            requestMediaWikiAPIAuthToken(for:url, type: .csrf) { (result) in
                switch result {
                case .failure(let error):
                    completion(nil, nil, error)
                case .success(let token):
                    self.session.jsonDecodableTask(with: url, method: method, bodyParameters: ["token": token.value], bodyEncoding: .form, completionHandler: completion)
                }
            }
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
        
        enum NotifierType: String {
            case web
            case push
            case email
        }

        static func notifications(from projects: [RemoteNotificationsProject] = [], limit: Limit = .max, filter: Filter = .none, notifierType: NotifierType? = nil, continueId: String?) -> Parameters {
            var dictionary = ["action": "query",
                    "format": "json",
                    "formatversion": "2",
                    "notformat": "model",
                    "meta": "notifications",
                    "notlimit": limit.value,
                    "notfilter": filter.rawValue]

            if let continueId = continueId {
                dictionary["notcontinue"] = continueId
            }
            
            if let notifierType = notifierType {
                dictionary["notnotifiertypes"] = notifierType.rawValue
            }
            
            let wikis = projects.map{ $0.notificationsApiWikiIdentifier }
            dictionary["notwikis"] = wikis.isEmpty ? "*" : wikis.joined(separator: "|")
            
            return dictionary
        }

        static func markAsReadOrUnread(identifierGroups: [RemoteNotification.IdentifierGroup], shouldMarkRead: Bool) -> Parameters? {
            let IDs = identifierGroups.compactMap { $0.id }
            
            var dictionary = ["action": "echomarkread",
                              "format": "json"]
            if shouldMarkRead {
                dictionary["list"] = IDs.joined(separator: "|")
            } else {
                dictionary["unreadlist"] = IDs.joined(separator: "|")
            }
            
            return dictionary
        }
        
        static func markAllAsRead(project: RemoteNotificationsProject) -> Parameters? {
            let dictionary = ["action": "echomarkread",
                              "all": "true",
                              "wikis": project.notificationsApiWikiIdentifier,
                              "format": "json"]
            return dictionary
        }
    }
}

extension RemoteNotificationsAPIController.ResultError: LocalizedError {
    var errorDescription: String? {
        return info
    }
}

//MARK: Public Notification Extensions

public extension RemoteNotificationsAPIController.NotificationsResult.Notification {

    var key: String {
        return "\(wiki)-\(id)"
    }
    
    var date: Date? {
        return DateFormatter.wmf_iso8601()?.date(from: timestamp.utciso8601)
    }
    
    var pushContentText: String? {
        return self.message?.header?.removingHTML
    }
    
    var namespaceKey: Int? {
        return self.title?.namespaceKey
    }
    
    var titleFull: String? {
        return self.title?.full
    }
    
    func isNewerThan(timeAgo: TimeInterval) -> Bool {
        guard let date = date else {
            return false
        }

        return date > Date().addingTimeInterval(-timeAgo)
    }
    
    var namespace: PageNamespace? {
        return PageNamespace(namespaceValue: title?.namespaceKey)
    }
}

#if TEST

extension RemoteNotificationsAPIController.NotificationsResult.Notification {
    
    init?(project: RemoteNotificationsProject, titleText: String, titleNamespace: PageNamespace, remoteNotificationType: RemoteNotificationType, date: Date, customID: String? = nil) {
        
        switch remoteNotificationType {
        case .userTalkPageMessage:
            self.category = "edit-user-talk"
            self.type = "edit-user-talk"
            self.section = "alert"
        case .editReverted:
            self.category = "reverted"
            self.type = "reverted"
            self.section = "alert"
        default:
            assertionFailure("Haven't set up test models for this type.")
            return nil
        }
        
        self.wiki = project.notificationsApiWikiIdentifier

        let identifier = customID ?? UUID().uuidString
        self.id = identifier
        
        let timestamp = Timestamp(date: date)
        self.timestamp = timestamp
        self.title = Title(titleText: titleText, titleNamespace: titleNamespace)
        self.agent = Agent()
        
        self.revisionID = nil
        self.readString = nil
       
        self.message = Message(identifier: identifier)
    }
}

extension RemoteNotificationsAPIController.NotificationsResult.Notification.Timestamp {
    init(date: Date) {
        let dateString8601 = DateFormatter.wmf_iso8601().string(from: date)
        let unixTimeInterval = date.timeIntervalSince1970
        self.utciso8601 = dateString8601
        self.utcunix = String(unixTimeInterval)
    }
}

extension RemoteNotificationsAPIController.NotificationsResult.Notification.Title {
    init(titleText: String, titleNamespace: PageNamespace) {
        
        let namespaceText = titleNamespace.canonicalName
        self.full = "\(namespaceText):\(titleText)"
        self.namespace = titleNamespace.canonicalName.denormalizedPageTitle
        self.namespaceKey = titleNamespace.rawValue
        self.text = titleText
    }
}

extension RemoteNotificationsAPIController.NotificationsResult.Notification.Agent {
    init() {
        self.id = String(12345)
        self.name = "Test Agent Name"
    }
}

extension RemoteNotificationsAPIController.NotificationsResult.Notification.Message {
    init(identifier: String) {
        self.header = "\(identifier)"
        self.body = "Test body text for identifier: \(identifier)"
        let primaryLink = RemoteNotificationLink(type: nil, url: URL(string:"https://en.wikipedia.org/wiki/Cat")!, label: "Label for primary link")
        self.links = RemoteNotificationLinks(primary: primaryLink, secondary: nil)
    }
}

#endif
