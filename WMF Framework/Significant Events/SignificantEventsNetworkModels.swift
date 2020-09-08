
import Foundation
enum SignificantEventsDecodeError: Error {
    case unableToParseIntoTimelineEvents
}

public struct SignificantEvents: Decodable {
    public let nextRvStartId: UInt?
    public let sha: String?
    private let untypedEvents: [UntypedTimelineEvent]
    public let typedEvents: [TimelineEvent]
    public let summary: Summary
    
    public enum SnippetType: Int, Decodable {
        case addedLine = 1
        case addedAndDeletedInLine = 3
        case addedAndDeletedInMovedLine = 5
    }
    
    struct UntypedChange: Decodable {
        let outputType: LargeChangeOutputType
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
    
    struct UntypedTimelineEvent: Decodable {
        let outputType: TimelineEventOutputType
        let revId: UInt?
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
        
        init(forPrototypeText prototypeText: String) {
            self.outputType = .largeChange
            self.revId = 1
            self.timestampString = "2015-07-08T21:16:25Z"
            self.user = "Test.Name"
            self.userId = 2
            self.userGroups = ["autoreviewer", "extendedconfirmed", "*", "user", "autoconfirmed"]
            self.userEditCount = 3
            self.count = nil
            self.sections = ["== Test =="]
            self.section = nil
            self.snippet = prototypeText
            let untypedChange = SignificantEvents.UntypedChange(outputType: .addedText, sections: ["== Test =="], snippet: prototypeText, snippetType: .addedLine, characterCount: UInt(prototypeText.count), untypedTemplates: nil)
            self.untypedChanges = [untypedChange]
        }
    }
    
    public enum TimelineEventOutputType: String, Decodable {
        case largeChange = "large-change"
        case smallChange = "small-change"
        case newTalkPageTopic = "new-talk-page-topic"
        case vandalismRevert = "vandalism-revert"
    }
    
    public enum LargeChangeOutputType: String, Decodable {
        case addedText = "added-text"
        case deletedText = "deleted-text"
        case newTemplate = "new-template"
    }
    
    public enum TimelineEvent {
        case largeChange(LargeChange)
        case smallChange(SmallChange)
        case vandalismRevert(VandalismRevert)
        case newTalkPageTopic(NewTalkPageTopic)
    }
    
    public enum Change {
        case addedText(AddedTextChange)
        case deletedText(DeletedTextChange)
        case newTemplate(NewTemplatesChange)
    }
    
    public enum Template {
        case bookCitation(BookCitation)
        case articleDescription(ArticleDescription)
        case journalCitation(JournalCitation)
        case newsCitation(NewsCitation)
        case websiteCitation(WebsiteCitation)
    }
    
    public struct AddedTextChange {
        let outputType: LargeChangeOutputType
        public let sections: [String]
        public let snippet: String
        public let snippetType: SnippetType
        public let characterCount: UInt
        
        init?(untypedChange: UntypedChange) {
            guard let snippet = untypedChange.snippet,
                  let snippetType = untypedChange.snippetType,
                  let characterCount = untypedChange.characterCount else {
                return nil
            }
            
            self.outputType = untypedChange.outputType
            self.sections = untypedChange.sections
            self.snippet = snippet
            self.snippetType = snippetType
            self.characterCount = characterCount
        }
    }
    
    public struct DeletedTextChange {
        let outputType: LargeChangeOutputType
        public let sections: [String]
        public let characterCount: UInt
        
        init?(untypedChange: UntypedChange) {
            guard let characterCount = untypedChange.characterCount else {
                return nil
            }
            
            self.outputType = untypedChange.outputType
            self.sections = untypedChange.sections
            self.characterCount = characterCount
        }
    }
    
    public struct NewTemplatesChange {
        let outputType: LargeChangeOutputType
        public let sections: [String]
        private let untypedTemplates: [[String: String]]
        public let typedTemplates: [Template]
        
        init?(untypedChange: UntypedChange) {
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
                let lowercaseName = name.lowercased()
                if lowercaseName.contains("cite") {
                    if lowercaseName.contains("book") {
                        if let bookCitation = BookCitation(dict: untypedTemplate) {
                            typedTemplates.append(.bookCitation(bookCitation))
                        }
                    } else if lowercaseName.contains("journal") {
                        if let journalCitation = JournalCitation(dict: untypedTemplate) {
                            typedTemplates.append(.journalCitation(journalCitation))
                        }
                    } else if lowercaseName.contains("web") {
                        if let webCitation = WebsiteCitation(dict: untypedTemplate) {
                            typedTemplates.append(.websiteCitation(webCitation))
                        }
                    } else if lowercaseName.contains("news") {
                        if let newsCitation = NewsCitation(dict: untypedTemplate) {
                            typedTemplates.append(.newsCitation(newsCitation))
                        }
                    }
                } else if lowercaseName.contains("short description") {
                    if let articleDescription = ArticleDescription(dict: untypedTemplate) {
                        typedTemplates.append(.articleDescription(articleDescription))
                    }
                }
            }
            
            self.typedTemplates = typedTemplates
        }
    }
    
    public struct LargeChange {
        let outputType: TimelineEventOutputType
        public let revId: UInt
        public let timestampString: String
        public let user: String
        public let userId: UInt
        public let userGroups: [String]?
        public let userEditCount: UInt?
        public let typedChanges: [Change]
        
        init?(untypedEvent: UntypedTimelineEvent) {
            guard let revId = untypedEvent.revId,
                  let timestampString = untypedEvent.timestampString,
                  let user = untypedEvent.user,
                  let userId = untypedEvent.userId,
                  let untypedChanges = untypedEvent.untypedChanges else {
                return nil
            }
            
            self.outputType = untypedEvent.outputType
            self.revId = revId
            self.timestampString = timestampString
            self.user = user
            self.userId = userId
            self.userGroups = untypedEvent.userGroups
            self.userEditCount = untypedEvent.userEditCount
            
            var changes: [Change] = []
            
            for untypedChange in untypedChanges {
                switch untypedChange.outputType {
                case .addedText:
                    if let change = AddedTextChange(untypedChange: untypedChange) {
                        changes.append(.addedText(change))
                    }
                case .deletedText:
                    if let change = DeletedTextChange(untypedChange: untypedChange) {
                        changes.append(.deletedText(change))
                    }
                case .newTemplate:
                    if let change = NewTemplatesChange(untypedChange: untypedChange) {
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
    
    public struct SmallChange {
        let outputType: TimelineEventOutputType
        public let count: UInt
        
        init?(untypedEvent: UntypedTimelineEvent) {
            guard let count = untypedEvent.count else {
                return nil
            }
            
            self.outputType = untypedEvent.outputType
            self.count = count
        }
    }
    
    public struct VandalismRevert {
        let outputType: TimelineEventOutputType
        public let revId: UInt
        public let timestampString: String
        public let user: String
        public let userId: UInt
        public let sections: [String]
        public let userGroups: [String]?
        public let userEditCount: UInt?
        
        init?(untypedEvent: UntypedTimelineEvent) {
            guard let revId = untypedEvent.revId,
                  let timestampString = untypedEvent.timestampString,
                  let user = untypedEvent.user,
                  let userId = untypedEvent.userId,
                  let sections = untypedEvent.sections else {
                return nil
            }
            
            self.outputType = untypedEvent.outputType
            self.revId = revId
            self.timestampString = timestampString
            self.user = user
            self.userId = userId
            self.sections = sections
            self.userGroups = untypedEvent.userGroups
            self.userEditCount = untypedEvent.userEditCount
        }
    }
    
    public struct NewTalkPageTopic {
        let outputType: TimelineEventOutputType
        let revId: UInt
        public let timestampString: String
        public let user: String
        public let userId: UInt
        public let section: String
        public let snippet: String
        public let userGroups: [String]?
        public let userEditCount: UInt?
        
        init?(untypedEvent: UntypedTimelineEvent) {
            guard let revId = untypedEvent.revId,
                  let timestampString = untypedEvent.timestampString,
                  let user = untypedEvent.user,
                  let userId = untypedEvent.userId,
                  let section = untypedEvent.section,
                  let snippet = untypedEvent.snippet else {
                return nil
            }
            
            self.outputType = untypedEvent.outputType
            self.revId = revId
            self.timestampString = timestampString
            self.user = user
            self.userId = userId
            self.section = section
            self.snippet = snippet
            self.userGroups = untypedEvent.userGroups
            self.userEditCount = untypedEvent.userEditCount
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nextRvStartId = try? container.decode(UInt.self, forKey: .nextRvStartId)
        sha = try? container.decode(String.self, forKey: .sha)
        summary = try container.decode(Summary.self, forKey: .summary)
        untypedEvents = try container.decode([UntypedTimelineEvent].self, forKey: .untypedTimeline)
        
        var typedEvents: [TimelineEvent] = []
        
        for untypedEvent in untypedEvents {
            switch untypedEvent.outputType {
            case .smallChange:
                if let change = SmallChange(untypedEvent: untypedEvent) {
                    typedEvents.append(.smallChange(change))
                }
            case .largeChange:
                if let change = LargeChange(untypedEvent: untypedEvent) {
                    typedEvents.append(.largeChange(change))
                }
            case .vandalismRevert:
                if let change = VandalismRevert(untypedEvent: untypedEvent) {
                    typedEvents.append(.vandalismRevert(change))
                }
            case .newTalkPageTopic:
                if let change = NewTalkPageTopic(untypedEvent: untypedEvent) {
                    typedEvents.append(.newTalkPageTopic(change))
                }
            }
        }

        guard typedEvents.count == untypedEvents.count else {
            throw SignificantEventsDecodeError.unableToParseIntoTimelineEvents
        }
        
        self.typedEvents = typedEvents
    }
    
    enum GenericTimelineCodingKeys: String, CodingKey {
        case outputType
    }
    
    enum CodingKeys: String, CodingKey {
            case nextRvStartId
            case sha
            case untypedTimeline = "timeline"
            case typedTimeline
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
    
    //https://en.wikipedia.org/wiki/Template:Cite_book/TemplateData
    public struct BookCitation {
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
            
            self.isbn = dict.nonEmptyValueForKey(key: "isbn") ??
                        dict.nonEmptyValueForKey(key: "ISBN13") ??
                        dict.nonEmptyValueForKey(key: "isbn13") ??
                        dict.nonEmptyValueForKey(key: "ISBN")
        }
    }
    
    public struct ArticleDescription {
        public let text: String
        
        init?(dict: [String: String]) {
            guard let text = dict.nonEmptyValueForKey(key: "1") else {
                return nil
            }
            
            self.text = text
        }
    }
    
    //https://en.wikipedia.org/wiki/Template:Cite_journal#TemplateData
    public struct JournalCitation {
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
            self.urlString = dict.nonEmptyValueForKey(key: "url")
            self.volumeNumber = dict.nonEmptyValueForKey(key: "volume")
            self.pages = dict.nonEmptyValueForKey(key: "pages")
            self.database = dict.nonEmptyValueForKey(key: "via")
        }
    }
    
    //https://en.wikipedia.org/wiki/Template:Cite_news#TemplateData
    public struct NewsCitation {
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
            
            self.urlString = dict.nonEmptyValueForKey(key: "url")
            self.accessDateString = dict.nonEmptyValueForKey(key: "access-date") ?? dict.nonEmptyValueForKey(key: "accessdate")
        }
    }
    
    //https://en.wikipedia.org/wiki/Template:Cite_web#TemplateData
    public struct WebsiteCitation {
        
        public let urlString: String
        public let title: String
        public let publisher: String?
        public let accessDateString: String?
        public let archiveDateString: String?
        public let archiveDotOrgUrlString: String?
        
        init?(dict: [String: String]) {
            guard let title = dict.nonEmptyValueForKey(key: "title"),
                  let urlString = dict.nonEmptyValueForKey(key: "url") else {
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

private extension Dictionary where Key == String, Value == String {
    func nonEmptyValueForKey(key: String) -> String? {
        if let value = self[key], !value.isEmpty {
            return value
        }
        
        return nil
    }
}
