
import Foundation
enum SignificantEventsDecodeError: Error {
    case unableToParseIntoTimelineEvents
}

public struct SignificantEvents: Decodable {
    let nextRvStartId: UInt?
    let sha: String?
    private let untypedTimeline: [UntypedTimelineItem]
    let typedTimeline: [TimelineEvent]
    let summary: Summary
    
    enum SnippetType: Int, Decodable {
        case addedLine = 1
        case addedAndDeletedInLine = 3
        case addedAndDeletedInMovedLine = 5
    }
    
    struct UntypedSignificantChangeItem: Decodable {
        let outputType: InnerOutputType
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
    
    struct UntypedTimelineItem: Decodable {
        let outputType: OutputType
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
        let untypedSignificantChanges: [UntypedSignificantChangeItem]?
        
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
                case untypedSignificantChanges = "significantChanges"
            }
    }
    
    enum OutputType: String, Decodable {
        case largeChange = "large-change"
        case smallChange = "small-change"
        case newTalkPageTopic = "new-talk-page-topic"
        case vandalismRevert = "vandalism-revert"
    }
    
    enum InnerOutputType: String, Decodable {
        case addedText = "added-text"
        case deletedText = "deleted-text"
        case newTemplate = "new-template"
    }
    
    enum TimelineEvent {
        case largeChange(LargeChange)
        case smallChange(SmallChange)
        case vandalismRevert(VandalismRevert)
        case newTalkPageTopic(NewTalkPageTopic)
    }
    
    enum SignificantChange {
        case addedText(AddedText)
        case deletedText(DeletedText)
        case newTemplate(NewTemplate)
    }
    
    enum Template {
        case bookCitation(BookCitation)
        case articleDescription(ArticleDescription)
        case journalCitation(JournalCitation)
        case newsCitation(NewsCitation)
        case websiteCitation(WebsiteCitation)
    }
    
    struct AddedText {
        let outputType: InnerOutputType
        let sections: [String]
        let snippet: String
        let snippetType: SnippetType
        let characterCount: UInt
        
        init?(significantChangeItem: UntypedSignificantChangeItem) {
            guard let snippet = significantChangeItem.snippet,
                  let snippetType = significantChangeItem.snippetType,
                  let characterCount = significantChangeItem.characterCount else {
                return nil
            }
            
            self.outputType = significantChangeItem.outputType
            self.sections = significantChangeItem.sections
            self.snippet = snippet
            self.snippetType = snippetType
            self.characterCount = characterCount
        }
    }
    
    struct DeletedText {
        let outputType: InnerOutputType
        let sections: [String]
        let characterCount: UInt
        
        init?(significantChangeItem: UntypedSignificantChangeItem) {
            guard let characterCount = significantChangeItem.characterCount else {
                return nil
            }
            
            self.outputType = significantChangeItem.outputType
            self.sections = significantChangeItem.sections
            self.characterCount = characterCount
        }
    }
    
    struct NewTemplate {
        let outputType: InnerOutputType
        let sections: [String]
        private let untypedTemplates: [[String: String]]
        let typedTemplates: [Template]
        
        init?(significantChangeItem: UntypedSignificantChangeItem) {
            guard let untypedTemplates = significantChangeItem.untypedTemplates else {
                return nil
            }
            
            var typedTemplates: [Template] = []
            self.outputType = significantChangeItem.outputType
            self.sections = significantChangeItem.sections
            self.untypedTemplates = untypedTemplates
            
            for untypedTemplate in untypedTemplates {
                guard let name = untypedTemplate["name"] else {
                    continue
                }
                
                if name.contains("cite") {
                    if name.contains("book") {
                        if let bookCitation = BookCitation(dict: untypedTemplate) {
                            typedTemplates.append(.bookCitation(bookCitation))
                        }
                    } else if name.contains("journal") {
                        if let journalCitation = JournalCitation(dict: untypedTemplate) {
                            typedTemplates.append(.journalCitation(journalCitation))
                        }
                    } else if name.contains("web") {
                        if let webCitation = WebsiteCitation(dict: untypedTemplate) {
                            typedTemplates.append(.websiteCitation(webCitation))
                        }
                    } else if name.contains("news") {
                        if let newsCitation = NewsCitation(dict: untypedTemplate) {
                            typedTemplates.append(.newsCitation(newsCitation))
                        }
                    }
                } else if name.contains("short description") {
                    if let articleDescription = ArticleDescription(dict: untypedTemplate) {
                        typedTemplates.append(.articleDescription(articleDescription))
                    }
                }
            }
            
            self.typedTemplates = typedTemplates
        }
    }
    
    struct LargeChange {
        let outputType: OutputType
        let revId: UInt
        let timestampString: String
        let user: String
        let userId: UInt
        let userGroups: [String]
        let userEditCount: UInt
        let typedSignificantChanges: [SignificantChange]
        
        init?(timelineItem: UntypedTimelineItem) {
            guard let revId = timelineItem.revId,
                  let timestampString = timelineItem.timestampString,
                  let user = timelineItem.user,
                  let userId = timelineItem.userId,
                  let userGroups = timelineItem.userGroups,
                  let userEditCount = timelineItem.userEditCount,
                  let untypedSignificantChanges = timelineItem.untypedSignificantChanges else {
                return nil
            }
            
            self.outputType = timelineItem.outputType
            self.revId = revId
            self.timestampString = timestampString
            self.user = user
            self.userId = userId
            self.userGroups = userGroups
            self.userEditCount = userEditCount
            
            var significantChanges: [SignificantChange] = []
            
            for untypedSignificantChange in untypedSignificantChanges {
                switch untypedSignificantChange.outputType {
                case .addedText:
                    if let change = AddedText(significantChangeItem: untypedSignificantChange) {
                        significantChanges.append(.addedText(change))
                    }
                case .deletedText:
                    if let change = DeletedText(significantChangeItem: untypedSignificantChange) {
                        significantChanges.append(.deletedText(change))
                    }
                case .newTemplate:
                    if let change = NewTemplate(significantChangeItem: untypedSignificantChange) {
                        significantChanges.append(.newTemplate(change))
                    }
                }
            }
            
            guard significantChanges.count == untypedSignificantChanges.count else {
                return nil
            }
            
            self.typedSignificantChanges = significantChanges
        }
    }
    
    struct SmallChange {
        let outputType: OutputType
        let count: UInt
        
        init?(timelineItem: UntypedTimelineItem) {
            guard let count = timelineItem.count else {
                return nil
            }
            
            self.outputType = timelineItem.outputType
            self.count = count
        }
    }
    
    struct VandalismRevert {
        let outputType: OutputType
        let revId: UInt
        let timestampString: String
        let user: String
        let userId: UInt
        let sections: [String]
        let userGroups: [String]
        let userEditCount: UInt
        
        init?(timelineItem: UntypedTimelineItem) {
            guard let revId = timelineItem.revId,
                  let timestampString = timelineItem.timestampString,
                  let user = timelineItem.user,
                  let userId = timelineItem.userId,
                  let sections = timelineItem.sections,
                  let userGroups = timelineItem.userGroups,
                  let userEditCount = timelineItem.userEditCount else {
                return nil
            }
            
            self.outputType = timelineItem.outputType
            self.revId = revId
            self.timestampString = timestampString
            self.user = user
            self.userId = userId
            self.sections = sections
            self.userGroups = userGroups
            self.userEditCount = userEditCount
        }
    }
    
    struct NewTalkPageTopic {
        let outputType: OutputType
        let revId: UInt
        let timestampString: String
        let user: String
        let userId: UInt
        let section: String
        let snippet: String
        let userGroups: [String]
        let userEditCount: UInt
        
        init?(timelineItem: UntypedTimelineItem) {
            guard let revId = timelineItem.revId,
                  let timestampString = timelineItem.timestampString,
                  let user = timelineItem.user,
                  let userId = timelineItem.userId,
                  let section = timelineItem.section,
                  let snippet = timelineItem.snippet,
                  let userGroups = timelineItem.userGroups,
                  let userEditCount = timelineItem.userEditCount else {
                return nil
            }
            
            self.outputType = timelineItem.outputType
            self.revId = revId
            self.timestampString = timestampString
            self.user = user
            self.userId = userId
            self.section = section
            self.snippet = snippet
            self.userGroups = userGroups
            self.userEditCount = userEditCount
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nextRvStartId = try? container.decode(UInt.self, forKey: .nextRvStartId)
        sha = try? container.decode(String.self, forKey: .sha)
        summary = try container.decode(Summary.self, forKey: .summary)
        untypedTimeline = try container.decode([UntypedTimelineItem].self, forKey: .untypedTimeline)
        
        var timelineEvents: [TimelineEvent] = []
        
        for timelineItem in untypedTimeline {
            switch timelineItem.outputType {
            case .smallChange:
                if let change = SmallChange(timelineItem: timelineItem) {
                    timelineEvents.append(.smallChange(change))
                }
            case .largeChange:
                if let change = LargeChange(timelineItem: timelineItem) {
                    timelineEvents.append(.largeChange(change))
                }
            case .vandalismRevert:
                if let change = VandalismRevert(timelineItem: timelineItem) {
                    timelineEvents.append(.vandalismRevert(change))
                }
            case .newTalkPageTopic:
                if let change = NewTalkPageTopic(timelineItem: timelineItem) {
                    timelineEvents.append(.newTalkPageTopic(change))
                }
            }
        }

        guard timelineEvents.count == untypedTimeline.count else {
            throw SignificantEventsDecodeError.unableToParseIntoTimelineEvents
        }
        
        self.typedTimeline = timelineEvents
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
    
    struct Summary: Decodable {
        let earliestTimestampString: String
        let numChanges: UInt
        let numUsers: UInt
        
        enum CodingKeys: String, CodingKey {
                case earliestTimestampString = "earliestTimestamp"
                case numChanges
                case numUsers
            }
    }
    
    //https://en.wikipedia.org/wiki/Template:Cite_book/TemplateData
    struct BookCitation {
        let title: String
        let lastName: String?
        let firstName: String?
        let yearPublished: String?
        let locationPublished: String?
        let publisher: String?
        let pagesCited: String?
        let isbn: String?
        
        init?(dict: [String: String]) {
            guard let title = dict["title"] else {
                return nil
            }
            
            self.title = title
            
            let batch1 = dict["last"] ??
                dict["last1"] ??
                dict["author"] ??
                dict["author1"] ??
                dict["author1-last"]
            let batch2 = dict["author-last"] ??
                dict["surname1"] ??
                dict["author-last1"] ??
                dict["subject1"] ??
                dict["surname"]
            let batch3 = dict["author-last"] ??
                dict["subject"]
            
            self.lastName = batch1 ?? batch2 ?? batch3
            
            self.firstName = dict["first"] ??
                            dict["given"] ??
                            dict["author-first"] ??
                            dict["first1"] ??
                            dict["given1"] ??
                            dict["author-first1"] ??
                            dict["author1-first"]
            
            self.yearPublished = dict["year"]
            self.locationPublished = dict["location"] ??
                                        dict["place"]
            
            self.publisher = dict["publisher"] ??
                            dict["distributor"] ??
                            dict["institution"] ??
                            dict["newsgroup"]
            
            self.pagesCited = dict["pages"] ??
                dict["pp"]
            
            self.isbn = dict["isbn"] ??
                        dict["ISBN13"] ??
                        dict["isbn13"] ??
                        dict["ISBN"]
        }
    }
    
    struct ArticleDescription {
        let description: String
        
        init?(dict: [String: String]) {
            guard let description = dict["1"] else {
                return nil
            }
            
            self.description = description
        }
    }
    
    //https://en.wikipedia.org/wiki/Template:Cite_journal#TemplateData
    struct JournalCitation {
        let lastName: String?
        let firstName: String?
        let sourceDateString: String?
        let title: String
        let journal: String
        let urlString: String?
        let volumeNumber: String?
        let pages: String?
        let database: String?
        
        init?(dict: [String: String]) {
            guard let title = dict["title"],
            let journal = dict["journal"] else {
                return nil
            }
            
            self.title = title
            self.journal = journal
            
            self.lastName = dict["last"] ??
            dict["author"] ??
            dict["author1"] ??
            dict["authors"] ??
            dict["last1"]
            
            self.firstName = dict["first"] ??
            dict["first1"]
            
            self.sourceDateString = dict["date"]
            self.urlString = dict["url"]
            self.volumeNumber = dict["volume"]
            self.pages = dict["pages"]
            self.database = dict["via"]
        }
    }
    
    //https://en.wikipedia.org/wiki/Template:Cite_news#TemplateData
    struct NewsCitation {
        let lastName: String?
        let firstName: String?
        let sourceDateString: String?
        let title: String
        let urlString: String?
        let publication: String?
        let accessDateString: String?
        
        init?(dict: [String: String]) {
            guard let title = dict["title"] else {
                return nil
            }
            
            self.title = title
            self.lastName = dict["last"] ??
                            dict["last1"] ??
                            dict["author"] ??
                            dict["author1"] ??
                            dict["authors"]
            
            self.firstName = dict["first"] ??
                            dict["first1"]
            
            self.sourceDateString = dict["date"]
            self.publication = dict["work"] ??
                                dict["journal"] ??
                                dict["magazine"] ??
                                dict["periodical"] ??
                                dict["newspaper"] ??
                                dict["website"]
            
            self.urlString = dict["url"]
            self.accessDateString = dict["access-date"] ?? dict["accessdate"]
        }
    }
    
    //https://en.wikipedia.org/wiki/Template:Cite_web#TemplateData
    struct WebsiteCitation {
        
        let urlString: String
        let title: String
        let publisher: String?
        let accessDateString: String?
        let archiveDateString: String?
        let archiveDotOrgUrlString: String?
        
        init?(dict: [String: String]) {
            guard let title = dict["title"],
                  let urlString = dict["url"] else {
                return nil
            }
            
            self.title = title
            self.urlString = urlString
            
            self.publisher = dict["publisher"] ??
                            dict["website"] ??
                            dict["work"]
            
            self.accessDateString = dict["access-date"] ?? dict["accessdate"]
            self.archiveDateString = dict["archive-date"] ?? dict["archivedate"]
            self.archiveDotOrgUrlString = dict["archive-url"] ?? dict["archiveurl"]
        }
    }
}
