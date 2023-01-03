import Foundation
enum SignificantEventsDecodeError: Error {
    case unableToParseIntoTypedEvents
}

public struct SignificantEvents: Decodable {
    public let nextRvStartId: UInt?
    public let sha: String?
    private let untypedEvents: [UntypedEvent]
    public let typedEvents: [TypedEvent]
    public let summary: Summary
    
    enum CodingKeys: String, CodingKey {
        case nextRvStartId
        case sha
        case untypedEvents = "timeline"
        case typedEvents
        case summary
    }
    
    public struct Summary: Decodable {
        public let earliestTimestampString: String
        public let numChanges: UInt
        public let numUsers: UInt
        
        enum CodingKeys: String, CodingKey {
            case earliestTimestampString = "earliestTimestamp"
            case numChanges
            case numUsers
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nextRvStartId = try? container.decode(UInt.self, forKey: .nextRvStartId)
        sha = try? container.decode(String.self, forKey: .sha)
        summary = try container.decode(Summary.self, forKey: .summary)
        let untypedEvents = try container.decode([UntypedEvent].self, forKey: .untypedEvents)
        
        var typedEvents: [TypedEvent] = []
        
        for untypedEvent in untypedEvents {
            switch untypedEvent.outputType {
            case .small:
                if let event = Event.Small(untypedEvent: untypedEvent) {
                    typedEvents.append(.small(event))
                }
            case .large:
                if let event = Event.Large(untypedEvent: untypedEvent) {
                    typedEvents.append(.large(event))
                }
            case .vandalismRevert:
                if let event = Event.VandalismRevert(untypedEvent: untypedEvent) {
                    typedEvents.append(.vandalismRevert(event))
                }
            case .newTalkPageTopic:
                if let event = Event.NewTalkPageTopic(untypedEvent: untypedEvent) {
                    typedEvents.append(.newTalkPageTopic(event))
                }
            }
        }

        // zero untyped events is a valid case if the user has paged to the end of the endpoint cache
        // unTypedEvents > 0 and typedEvents == 0 is invalid, meaning all events failed to convert
        guard typedEvents.count > 0 || untypedEvents.count == 0 else {
            throw SignificantEventsDecodeError.unableToParseIntoTypedEvents
        }
        
        self.typedEvents = typedEvents
        self.untypedEvents = untypedEvents
    }
    
    public enum SnippetType: Int, Decodable {
        case addedLine = 1
        case addedAndDeletedInLine = 3
        case addedAndDeletedInMovedLine = 5
    }
    
    public enum EventOutputType: String, Decodable {
        case large = "large-change"
        case small = "small-change"
        case newTalkPageTopic = "new-talk-page-topic"
        case vandalismRevert = "vandalism-revert"
    }
    
    public enum ChangeOutputType: String, Decodable {
        case addedText = "added-text"
        case deletedText = "deleted-text"
        case newTemplate = "new-template"
    }
    
    public enum TypedEvent {
        case large(Event.Large)
        case small(Event.Small)
        case vandalismRevert(Event.VandalismRevert)
        case newTalkPageTopic(Event.NewTalkPageTopic)
    }
    
    public enum TypedChange {
        case addedText(Change.AddedText)
        case deletedText(Change.DeletedText)
        case newTemplate(Change.NewTemplates)
    }
}

// MARK: Events

public extension SignificantEvents {
    
    struct Event {
        
        public struct Large {
            let outputType: EventOutputType
            public let revId: UInt
            public let parentId: UInt
            public let timestampString: String
            public let user: String
            public let userId: UInt
            public let userGroups: [String]?
            public let userEditCount: UInt?
            public let typedChanges: [TypedChange]
            
            init?(untypedEvent: UntypedEvent) {
                guard let revId = untypedEvent.revId,
                      let parentId = untypedEvent.parentId,
                      let timestampString = untypedEvent.timestampString,
                      let user = untypedEvent.user,
                      let userId = untypedEvent.userId,
                      let untypedChanges = untypedEvent.untypedChanges else {
                    return nil
                }
                
                self.outputType = untypedEvent.outputType
                self.revId = revId
                self.parentId = parentId
                self.timestampString = timestampString
                self.user = user
                self.userId = userId
                self.userGroups = untypedEvent.userGroups
                self.userEditCount = untypedEvent.userEditCount
                
                var changes: [TypedChange] = []
                
                for untypedChange in untypedChanges {
                    switch untypedChange.outputType {
                    case .addedText:
                        if let change = Change.AddedText(untypedChange: untypedChange) {
                            changes.append(.addedText(change))
                        }
                    case .deletedText:
                        if let change = Change.DeletedText(untypedChange: untypedChange) {
                            changes.append(.deletedText(change))
                        }
                    case .newTemplate:
                        if let change = Change.NewTemplates(untypedChange: untypedChange) {
                            changes.append(.newTemplate(change))
                        }
                    }
                }
                
                guard changes.count == untypedChanges.count else {
                    return nil
                }
                
                self.typedChanges = changes
            }
        }
        
        public struct Small: Equatable {
            let outputType: EventOutputType
            public let revId: UInt
            public let parentId: UInt
            public let timestampString: String
            
            fileprivate init?(untypedEvent: UntypedEvent) {
                guard let revId = untypedEvent.revId,
                      let parentId = untypedEvent.parentId,
                      let timestampString = untypedEvent.timestampString else {
                    return nil
                }
                
                self.outputType = untypedEvent.outputType
                self.revId = revId
                self.parentId = parentId
                self.timestampString = timestampString
            }
            
            public static func == (lhs: SignificantEvents.Event.Small, rhs: SignificantEvents.Event.Small) -> Bool {
                return lhs.revId == rhs.revId
            }
        }
        
        public struct VandalismRevert {
            let outputType: EventOutputType
            public let revId: UInt
            public let parentId: UInt
            public let timestampString: String
            public let user: String
            public let userId: UInt
            public let sections: [String]
            public let userGroups: [String]?
            public let userEditCount: UInt?
            
            fileprivate init?(untypedEvent: UntypedEvent) {
                guard let revId = untypedEvent.revId,
                      let parentId = untypedEvent.parentId,
                      let timestampString = untypedEvent.timestampString,
                      let user = untypedEvent.user,
                      let userId = untypedEvent.userId,
                      let sections = untypedEvent.sections else {
                    return nil
                }
                
                self.outputType = untypedEvent.outputType
                self.revId = revId
                self.parentId = parentId
                self.timestampString = timestampString
                self.user = user
                self.userId = userId
                self.sections = sections
                self.userGroups = untypedEvent.userGroups
                self.userEditCount = untypedEvent.userEditCount
            }
        }
        
        public struct NewTalkPageTopic {
            let outputType: EventOutputType
            let revId: UInt
            let parentId: UInt
            public let timestampString: String
            public let user: String
            public let userId: UInt
            public let section: String?
            public let snippet: String
            public let userGroups: [String]?
            public let userEditCount: UInt?
            
            fileprivate init?(untypedEvent: UntypedEvent) {
                guard let revId = untypedEvent.revId,
                      let parentId = untypedEvent.parentId,
                      let timestampString = untypedEvent.timestampString,
                      let user = untypedEvent.user,
                      let userId = untypedEvent.userId,
                      let snippet = untypedEvent.snippet else {
                    return nil
                }
                
                self.outputType = untypedEvent.outputType
                self.revId = revId
                self.parentId = parentId
                self.timestampString = timestampString
                self.user = user
                self.userId = userId
                self.section = untypedEvent.section
                self.snippet = snippet
                self.userGroups = untypedEvent.userGroups
                self.userEditCount = untypedEvent.userEditCount
            }
        }
    }
}

// MARK: Changes

public extension SignificantEvents {
    
    struct Change {
        
        public struct AddedText {
            let outputType: ChangeOutputType
            public let sections: [String]
            public let snippet: String?
            public let snippetType: SnippetType
            public let characterCount: UInt
            
            fileprivate init?(untypedChange: UntypedChange) {
                guard let snippetType = untypedChange.snippetType,
                      let characterCount = untypedChange.characterCount else {
                    return nil
                }
                
                self.outputType = untypedChange.outputType
                self.sections = untypedChange.sections
                self.snippet = untypedChange.snippet
                self.snippetType = snippetType
                self.characterCount = characterCount
            }
        }
        
        public struct DeletedText {
            let outputType: ChangeOutputType
            public let sections: [String]
            public let characterCount: UInt
            
            fileprivate init?(untypedChange: UntypedChange) {
                guard let characterCount = untypedChange.characterCount else {
                    return nil
                }
                
                self.outputType = untypedChange.outputType
                self.sections = untypedChange.sections
                self.characterCount = characterCount
            }
        }
        
        public struct NewTemplates {
            let outputType: ChangeOutputType
            public let sections: [String]
            private let untypedTemplates: [[String: String]]
            public let typedTemplates: [Template]
            
            fileprivate init?(untypedChange: UntypedChange) {
                guard let untypedTemplates = untypedChange.untypedTemplates else {
                    return nil
                }
                
                var typedTemplates: [Template] = []
                self.outputType = untypedChange.outputType
                self.sections = untypedChange.sections
                self.untypedTemplates = untypedTemplates
                
                for untypedTemplate in untypedTemplates {
                    guard let name = untypedTemplate["name"] else {
                        continue
                    }
                    if name.localizedCaseInsensitiveContains("cite") {
                        if name.localizedCaseInsensitiveContains("book"), let bookCitation = Citation.Book(dict: untypedTemplate) {
                            typedTemplates.append(.bookCitation(bookCitation))
                        } else if name.localizedCaseInsensitiveContains("journal"), let journalCitation = Citation.Journal(dict: untypedTemplate) {
                            typedTemplates.append(.journalCitation(journalCitation))
                        } else if name.localizedCaseInsensitiveContains("web"), let webCitation = Citation.Website(dict: untypedTemplate) {
                            typedTemplates.append(.websiteCitation(webCitation))
                        } else if name.localizedCaseInsensitiveContains("news"), let newsCitation = Citation.News(dict: untypedTemplate) {
                            typedTemplates.append(.newsCitation(newsCitation))
                        }
                    } else if name.localizedCaseInsensitiveContains("short description"), let articleDescription = ArticleDescription(dict: untypedTemplate) {
                        typedTemplates.append(.articleDescription(articleDescription))
                    }
                }
                
                self.typedTemplates = typedTemplates
            }
        }
    }
}

// MARK: Templates

public extension SignificantEvents {
    
    enum Template {
        case bookCitation(Citation.Book)
        case articleDescription(ArticleDescription)
        case journalCitation(Citation.Journal)
        case newsCitation(Citation.News)
        case websiteCitation(Citation.Website)
    }
    
    struct Citation {
        
        // https://en.wikipedia.org/wiki/Template:Cite_book/TemplateData
        public struct Book {
            public let title: String
            public let lastName: String?
            public let firstName: String?
            public let yearPublished: String?
            public let locationPublished: String?
            public let publisher: String?
            public let pagesCited: String?
            public let isbn: String?
            
            init?(dict: [String: String]) {
                guard let title = dict.nonEmptyValueForKey(key: "title") else {
                    return nil
                }
                
                self.title = title
                
                let batch1 = dict.nonEmptyValueForKey(key: "last") ??
                    dict.nonEmptyValueForKey(key: "last1") ??
                    dict.nonEmptyValueForKey(key: "author") ??
                    dict.nonEmptyValueForKey(key: "author1") ??
                    dict.nonEmptyValueForKey(key: "author1-last")
                let batch2 = dict.nonEmptyValueForKey(key: "author-last") ??
                    dict.nonEmptyValueForKey(key: "surname1") ??
                    dict.nonEmptyValueForKey(key: "author-last1") ??
                    dict.nonEmptyValueForKey(key: "subject1") ??
                    dict.nonEmptyValueForKey(key: "surname")
                let batch3 = dict.nonEmptyValueForKey(key: "author-last") ??
                    dict.nonEmptyValueForKey(key: "subject")
                
                self.lastName = batch1 ?? batch2 ?? batch3
                
                self.firstName = dict.nonEmptyValueForKey(key: "first") ??
                                dict.nonEmptyValueForKey(key: "given") ??
                                dict.nonEmptyValueForKey(key: "author-first") ??
                                dict.nonEmptyValueForKey(key: "first1") ??
                                dict.nonEmptyValueForKey(key: "given1") ??
                                dict.nonEmptyValueForKey(key: "author-first1") ??
                                dict.nonEmptyValueForKey(key: "author1-first")
                
                self.yearPublished = dict.nonEmptyValueForKey(key: "year")
                self.locationPublished = dict.nonEmptyValueForKey(key: "location") ??
                                            dict.nonEmptyValueForKey(key: "place")
                
                self.publisher = dict.nonEmptyValueForKey(key: "publisher") ??
                                dict.nonEmptyValueForKey(key: "distributor") ??
                                dict.nonEmptyValueForKey(key: "institution") ??
                                dict.nonEmptyValueForKey(key: "newsgroup")
                
                self.pagesCited = dict.nonEmptyValueForKey(key: "pages") ??
                    dict.nonEmptyValueForKey(key: "pp")
                
                self.isbn = dict.nonEmptyValueForKey(key: "isbn", caseInsensitive: true) ??
                            dict.nonEmptyValueForKey(key: "isbn13", caseInsensitive: true)
            }
        }
        
        // https://en.wikipedia.org/wiki/Template:Cite_journal#TemplateData
        public struct Journal {
            public let lastName: String?
            public let firstName: String?
            public let sourceDateString: String?
            public let title: String
            public let journal: String
            public let urlString: String?
            public let volumeNumber: String?
            public let pages: String?
            public let database: String?
            
            init?(dict: [String: String]) {
                guard let title = dict.nonEmptyValueForKey(key: "title"),
                let journal = dict.nonEmptyValueForKey(key: "journal") else {
                    return nil
                }
                
                self.title = title
                self.journal = journal
                
                self.lastName = dict.nonEmptyValueForKey(key: "last") ??
                dict.nonEmptyValueForKey(key: "author") ??
                dict.nonEmptyValueForKey(key: "author1") ??
                dict.nonEmptyValueForKey(key: "authors") ??
                dict.nonEmptyValueForKey(key: "last1")
                
                self.firstName = dict.nonEmptyValueForKey(key: "first") ??
                dict.nonEmptyValueForKey(key: "first1")
                
                self.sourceDateString = dict.nonEmptyValueForKey(key: "date")
                self.urlString = dict.nonEmptyValueForKey(key: "url", caseInsensitive: true)
                self.volumeNumber = dict.nonEmptyValueForKey(key: "volume")
                self.pages = dict.nonEmptyValueForKey(key: "pages")
                self.database = dict.nonEmptyValueForKey(key: "via")
            }
        }
        
        // https://en.wikipedia.org/wiki/Template:Cite_news#TemplateData
        public struct News {
            public let lastName: String?
            public let firstName: String?
            public let sourceDateString: String?
            public let title: String
            public let urlString: String?
            public let publication: String?
            public let accessDateString: String?
            
            init?(dict: [String: String]) {
                guard let title = dict.nonEmptyValueForKey(key: "title") else {
                    return nil
                }
                
                self.title = title
                self.lastName = dict.nonEmptyValueForKey(key: "last") ??
                                dict.nonEmptyValueForKey(key: "last1") ??
                                dict.nonEmptyValueForKey(key: "author") ??
                                dict.nonEmptyValueForKey(key: "author1") ??
                                dict.nonEmptyValueForKey(key: "authors")
                
                self.firstName = dict.nonEmptyValueForKey(key: "first") ??
                                dict.nonEmptyValueForKey(key: "first1")
                
                self.sourceDateString = dict.nonEmptyValueForKey(key: "date")
                self.publication = dict.nonEmptyValueForKey(key: "work") ??
                                    dict.nonEmptyValueForKey(key: "journal") ??
                                    dict.nonEmptyValueForKey(key: "magazine") ??
                                    dict.nonEmptyValueForKey(key: "periodical") ??
                                    dict.nonEmptyValueForKey(key: "newspaper") ??
                                    dict.nonEmptyValueForKey(key: "website")
                
                self.urlString = dict.nonEmptyValueForKey(key: "url", caseInsensitive: true)
                self.accessDateString = dict.nonEmptyValueForKey(key: "access-date") ?? dict.nonEmptyValueForKey(key: "accessdate")
            }
        }
        
        // https://en.wikipedia.org/wiki/Template:Cite_web#TemplateData
        public struct Website {
            
            public let urlString: String
            public let title: String
            public let publisher: String?
            public let accessDateString: String?
            public let archiveDateString: String?
            public let archiveDotOrgUrlString: String?
            
            init?(dict: [String: String]) {
                guard let title = dict.nonEmptyValueForKey(key: "title"),
                      let urlString = dict.nonEmptyValueForKey(key: "url", caseInsensitive: true) else {
                    return nil
                }
                
                self.title = title
                self.urlString = urlString
                
                self.publisher = dict.nonEmptyValueForKey(key: "publisher") ??
                                dict.nonEmptyValueForKey(key: "website") ??
                                dict.nonEmptyValueForKey(key: "work")
                
                self.accessDateString = dict.nonEmptyValueForKey(key: "access-date") ?? dict.nonEmptyValueForKey(key: "accessdate")
                self.archiveDateString = dict.nonEmptyValueForKey(key: "archive-date") ?? dict.nonEmptyValueForKey(key: "archivedate")
                self.archiveDotOrgUrlString = dict.nonEmptyValueForKey(key: "archive-url") ?? dict.nonEmptyValueForKey(key: "archiveurl")
            }
        }
    }
    
    struct ArticleDescription {
        public let text: String
        
        init?(dict: [String: String]) {
            guard let text = dict.nonEmptyValueForKey(key: "1") else {
                return nil
            }
            
            self.text = text
        }
    }
    
    
}

// MARK: Untyped

public extension SignificantEvents {
    struct UntypedEvent: Decodable {
        let outputType: EventOutputType
        let revId: UInt?
        let parentId: UInt?
        let timestampString: String?
        let user: String?
        let userId: UInt?
        let userGroups: [String]?
        let userEditCount: UInt?
        let count: UInt?
        let sections: [String]?
        let section: String?
        let snippet: String?
        let untypedChanges: [UntypedChange]?
        
        enum CodingKeys: String, CodingKey {
                case revId = "revid"
                case parentId = "parentid"
                case timestampString = "timestamp"
                case outputType
                case user
                case userId = "userid"
                case userGroups
                case userEditCount
                case count
                case sections
                case section
                case snippet
                case untypedChanges = "significantChanges"
            }
    }
    
    struct UntypedChange: Decodable {
        let outputType: ChangeOutputType
        let sections: [String]
        let snippet: String?
        let snippetType: SnippetType?
        let characterCount: UInt?
        let untypedTemplates: [[String: String]]?
        
        enum CodingKeys: String, CodingKey {
            case outputType
            case sections
            case snippet
            case snippetType
            case characterCount
            case untypedTemplates = "templates"
        }
    }
}

private extension Dictionary where Key == String, Value == String {
    func nonEmptyValueForKey(key: String, caseInsensitive: Bool = false) -> String? {
        guard let key = caseInsensitive
                ? keys.first(where: {$0.caseInsensitiveCompare(key) == .orderedSame})
                : key else {
                    return nil
         }

        if let value = self[key], !value.isEmpty {
            return value
        }

        return nil
    }
}
