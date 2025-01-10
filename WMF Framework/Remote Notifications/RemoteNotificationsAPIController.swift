import CocoaLumberjackSwift
import WMFComponents

public class RemoteNotificationsAPIController: Fetcher {

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
            let sources: [String: [String: String]]?

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
                case sources
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
                sources = try? values.decode([String: [String: String]].self, forKey: .sources)
            }
        }
        
        
    }

    // MARK: Decodable: MarkReadResult

    private struct MarkReadResult: Decodable {
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
        
        var errorDescription: String? {
            
            switch self {
            case .multiple(let errors):
                if let firstError = errors.first {
                    return (firstError as NSError).alertMessage()
                }
            case .noResult, .unknown:
                return RequestError.unexpectedResponse.errorDescription ?? CommonStrings.genericErrorDescription
            }
            
            return CommonStrings.genericErrorDescription
        }
    }
    
    // MARK: Decodable: MarkSeenResult
    
    struct MarkSeenResult: Decodable {
        let query: Query?
        let error: ResultError?
        
        var succeeded: Bool {
            return query?.markAsSeen?.result == .success
        }
        
        struct Query: Decodable {
            let markAsSeen: MarkAsSeen?
            
            enum CodingKeys: String, CodingKey {
                case markAsSeen = "echomarkseen"
            }
        }
        
        struct MarkAsSeen: Decodable {
            let result: Result?
        }
        
        enum Result: String, Decodable {
            case success
        }
    }
    
    enum MarkSeenError: LocalizedError {
        case noResult
        case unknown
        
        var errorDescription: String? {
            return RequestError.unexpectedResponse.errorDescription ?? CommonStrings.genericErrorDescription
        }
    }
    
    // MARK: Public
    
    public func getUnreadPushNotifications(from project: WikimediaProject, completion: @escaping (Set<NotificationsResult.Notification>, Error?) -> Void) {
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
    
    func getAllNotifications(from project: WikimediaProject, needsCrossWikiSummary: Bool = false, filter: Query.Filter = .none, continueId: String?, completion: @escaping (NotificationsResult.Query.Notifications?, Error?) -> Void) {
        let completion: (NotificationsResult?, URLResponse?, Error?) -> Void = { result, _, error in
            guard error == nil else {
                completion(nil, error)
                return
            }
            completion(result?.query?.notifications, result?.error)
        }
        
        request(project: project, queryParameters: Query.notifications(from: [project], limit: .max, filter: filter, needsCrossWikiSummary: needsCrossWikiSummary, continueId: continueId), completion: completion)
    }
    
    func markAllAsSeen(project: WikimediaProject, completion: @escaping ((Result<Void, Error>) -> Void)) {
        request(project: project, queryParameters: Query.markAllAsSeen(project: project), method: .post) { (result: MarkSeenResult?, _, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let result = result else {
                assertionFailure("Expected result")
                completion(.failure(MarkSeenError.noResult))
                return
            }
            
            if let error = result.error {
                completion(.failure(error))
                return
            }
            
            if !result.succeeded {
                completion(.failure(MarkSeenError.unknown))
                return
            }
            completion(.success(()))
        }
    }
    
    func markAllAsRead(project: WikimediaProject, completion: @escaping (Error?) -> Void) {
        
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

    func markAsReadOrUnread(project: WikimediaProject, identifierGroups: Set<RemoteNotification.IdentifierGroup>, shouldMarkRead: Bool, completion: @escaping (Error?) -> Void) {
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
    
    // MARK: Private

    private func request<T: Decodable>(project: WikimediaProject?, queryParameters: Query.Parameters?, method: Session.Request.Method = .get, completion: @escaping (T?, URLResponse?, Error?) -> Void) {

        guard let url = project?.mediaWikiAPIURL(configuration: configuration, queryParameters: queryParameters) else {
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

    struct Query {
        typealias Parameters = [String: Any]
        
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
        
        static func notifications(from projects: [WikimediaProject] = [], limit: Limit = .max, filter: Filter = .none, notifierType: NotifierType? = nil, needsCrossWikiSummary: Bool = false, continueId: String?) -> Parameters {
            var dictionary: [String: Any] = ["action": "query",
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
            
            if needsCrossWikiSummary {
                dictionary["notcrosswikisummary"] = 1
            }
            
            let wikis = projects.map { $0.notificationsApiWikiIdentifier }
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
        
        static func markAllAsRead(project: WikimediaProject) -> Parameters? {
            let dictionary = ["action": "echomarkread",
                              "all": "true",
                              "wikis": project.notificationsApiWikiIdentifier,
                              "format": "json"]
            return dictionary
        }
        
        static func markAllAsSeen(project: WikimediaProject) -> Parameters? {
            let dictionary = ["action": "echomarkseen",
                              "wikis": project.notificationsApiWikiIdentifier,
                              "format": "json",
                              "type": "all"]
            return dictionary
        }
    }
}

extension RemoteNotificationsAPIController.ResultError: LocalizedError {
    var errorDescription: String? {
        return info
    }
}

// MARK: Public Notification Extensions

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

// MARK: Test Helpers

#if TEST

extension RemoteNotificationsAPIController.NotificationsResult.Notification {
    
    init?(project: WikimediaProject, titleText: String, titleNamespace: PageNamespace, remoteNotificationType: RemoteNotificationType, date: Date, customID: String? = nil) {
        
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
        self.sources = nil
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
        self.links = RemoteNotificationLinks(primary: primaryLink, secondary: nil, legacyPrimary: primaryLink)
    }
}

#endif
