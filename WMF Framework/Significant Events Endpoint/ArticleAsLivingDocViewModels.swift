
import Foundation

//tonitodo: It makes more sense for this to live in the app. Can we move out of WMF?

public struct ArticleAsLivingDocViewModel {
    
    public let nextRvStartId: UInt?
    public let sha: String?
    public let sections: [SectionHeader]
    public let articleInsertHtmlSnippets: [String]
    public let lastUpdatedTimestamp: String?
    public let summaryText: String?

    private let isoDateFormatter = ISO8601DateFormatter()

    public init(nextRvStartId: UInt?, sha: String?, sections: [SectionHeader], summaryText: String?, articleInsertHtmlSnippets: [String], lastUpdatedTimestamp: String?) {
        self.nextRvStartId = nextRvStartId
        self.sha = sha
        self.sections = sections
        self.summaryText = summaryText
        self.articleInsertHtmlSnippets = articleInsertHtmlSnippets
        self.lastUpdatedTimestamp = lastUpdatedTimestamp
    }

    public init?(significantEvents: SignificantEvents, traitCollection: UITraitCollection, theme: Theme) {
        guard let dayMonthNumberYearDateFormatter = DateFormatter.wmf_monthNameDayOfMonthNumberYear() else {
            assertionFailure("Unable to generate date formatters for Significant Events View Models")
            return nil
        }
        
        self.nextRvStartId = significantEvents.nextRvStartId
        self.sha = significantEvents.sha
        
        //initialize summary text
        var summaryText: String? = nil
        if let earliestDate = isoDateFormatter.date(from: significantEvents.summary.earliestTimestampString) {
            
            let currentDate = Date()
            let calendar = NSCalendar.current
            let unitFlags:Set<Calendar.Component> = [.day]
            let components = calendar.dateComponents(unitFlags, from: earliestDate, to: currentDate)
            if let numberOfDays = components.day {
                summaryText = String.localizedStringWithFormat(CommonStrings.articleAsLivingDocSummaryTitle,
                                                                       significantEvents.summary.numChanges,
                                                                       significantEvents.summary.numUsers,
                                                                       numberOfDays)
            }
        }
        self.summaryText = summaryText
        
        // loop through typed events, turn into view models and segment off into sections
        var currentSectionEvents: [TypedEvent] = []
        var sections: [SectionHeader] = []
        
        var maybeCurrentTimestamp: Date?
        var maybePreviousTimestamp: Date?
        
        for originalEvent in significantEvents.typedEvents {
            
            var maybeEvent: TypedEvent? = nil
            if let smallEventViewModel = Event.Small(typedEvents: [originalEvent]) {
                maybeEvent = .small(smallEventViewModel)
            } else if let largeEventViewModel = Event.Large(typedEvent: originalEvent) {
                
                //this is just an optimization to have collection view height calculations sooner so it doesn't happen while the user is scrolling
                largeEventViewModel.calculateSideScrollingCollectionViewHeightForTraitCollection(traitCollection, theme: theme)
                maybeEvent = .large(largeEventViewModel)
            }
            
            guard let event = maybeEvent else {
                assertionFailure("Unable to instantiate event view model, skipping event")
                continue
            }
                
            switch originalEvent {
            case .large(let largeChange):
                maybeCurrentTimestamp = isoDateFormatter.date(from: largeChange.timestampString)
            case .newTalkPageTopic(let newTalkPageTopic):
                maybeCurrentTimestamp = isoDateFormatter.date(from: newTalkPageTopic.timestampString)
            case .vandalismRevert(let vandalismRevert):
                maybeCurrentTimestamp = isoDateFormatter.date(from: vandalismRevert.timestampString)
            case .small(let smallChange):
                maybeCurrentTimestamp = isoDateFormatter.date(from: smallChange.timestampString)
            }
        
            guard let currentTimestamp = maybeCurrentTimestamp else {
                assertionFailure("Significant Events - Unable to determine event timestamp, skipping event.")
                continue
            }
            
            if let previousTimestamp = maybePreviousTimestamp {
                let calendar = NSCalendar.current
                if !calendar.isDate(previousTimestamp, inSameDayAs: currentTimestamp) {
                    //multiple days have passed since last event, package up current sections into new section
                    let section = SectionHeader(timestamp: previousTimestamp, typedEvents: currentSectionEvents, subtitleDateFormatter: dayMonthNumberYearDateFormatter)
                    sections.append(section)
                    currentSectionEvents.removeAll()
                    currentSectionEvents.append(event)
                    maybePreviousTimestamp = currentTimestamp
                } else {
                    currentSectionEvents.append(event)
                    maybePreviousTimestamp = currentTimestamp
                }
            } else {
                currentSectionEvents.append(event)
                maybePreviousTimestamp = currentTimestamp
            }
        }
    
        //capture any final currentSectionEvents into new section
        if let currentTimestamp = maybeCurrentTimestamp {
            let section = SectionHeader(timestamp: currentTimestamp, typedEvents: currentSectionEvents, subtitleDateFormatter: dayMonthNumberYearDateFormatter)
            sections.append(section)
            currentSectionEvents.removeAll()
        }
        
        //collapse sibling small event view models
        var finalSections: [SectionHeader] = []
        for section in sections {
            var collapsedEventViewModels: [TypedEvent] = []
            var currentSmallChanges: [SignificantEvents.Event.Small] = []
            for event in section.typedEvents {
                switch event {
                case .small(let smallEventViewModel):
                    currentSmallChanges.append(contentsOf: smallEventViewModel.smallChanges)
                default:
                    if currentSmallChanges.count > 0 {
                        
                        collapsedEventViewModels.append(.small(Event.Small(smallChanges: currentSmallChanges)))
                        currentSmallChanges.removeAll()
                    }
                    collapsedEventViewModels.append(event)
                    continue
                }
            }
            
            //add any final small changes
            if currentSmallChanges.count > 0 {
                collapsedEventViewModels.append(.small(Event.Small(smallChanges: currentSmallChanges)))
                currentSmallChanges.removeAll()
            }

            let collapsedSection = SectionHeader(timestamp: section.timestamp, typedEvents: collapsedEventViewModels, subtitleDateFormatter: dayMonthNumberYearDateFormatter)
            finalSections.append(collapsedSection)
        }

        finalSections = ArticleAsLivingDocViewModel.collapseSmallEvents(from: finalSections)
        self.sections = finalSections

        //grab first 3 large event html snippets
        var articleInsertHtmlSnippets: [String] = []
        var lastUpdatedTimestamp: String?
        let htmlSnippetCountMax = 3
        
        outerLoop: for (sectionIndex, section) in finalSections.enumerated() {
            for (itemIndex, event) in section.typedEvents.enumerated() {
                switch event {
                case .small(let smallEvent):
                    if lastUpdatedTimestamp == nil {
                        lastUpdatedTimestamp = smallEvent.timestampForDisplay()
                    }
                case .large(let largeEvent):
                    if lastUpdatedTimestamp == nil {
                        lastUpdatedTimestamp = largeEvent.fullyRelativeTimestampForDisplay()
                    }
                    let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                    if let htmlSnippet = largeEvent.articleInsertHtmlSnippet(isFirst: articleInsertHtmlSnippets.count == 0, isLast: articleInsertHtmlSnippets.count == htmlSnippetCountMax - 1, indexPath: indexPath) {
                        if articleInsertHtmlSnippets.count < htmlSnippetCountMax {
                            articleInsertHtmlSnippets.append(htmlSnippet)
                        } else {
                            if lastUpdatedTimestamp != nil {
                                break outerLoop
                            }
                        }
                    }
                }
            }
        }
        
        self.articleInsertHtmlSnippets = articleInsertHtmlSnippets
        self.lastUpdatedTimestamp = lastUpdatedTimestamp
    }

    /// Collapses sequential sections that contain only small events into one section, including a date range that represents the collected events
    static func collapseSmallEvents(from sections: [SectionHeader]) -> [SectionHeader] {
        guard let dayMonthNumberYearDateFormatter = DateFormatter.wmf_monthNameDayOfMonthNumberYear(), let isoDateFormatter = DateFormatter.wmf_iso8601() else {
            return sections
        }

        let enumeratedSections = sections.enumerated()
        var mutatedSections: [SectionHeader] = []
        var rangesToCollapse: [ClosedRange<Int>] = []

        for (outerIndex, outerSection) in enumeratedSections {
            let startIndex = outerIndex
            var endIndex = outerIndex

            if outerSection.containsOnlySmallEvents {
                for (innerIndex, innerSection) in enumeratedSections {
                    guard innerIndex >= startIndex + 1, !rangesToCollapse.contains(where: {$0.contains(innerIndex) }) else {
                        continue
                    }

                    if innerSection.containsOnlySmallEvents {
                        endIndex = innerIndex
                    } else {
                        break
                    }
                }
            }

            if startIndex != endIndex {
                // This range is eligible to be collapsed
                rangesToCollapse.append(startIndex...endIndex)
            }
        }

        var typedEvents: [TypedEvent] = []

        typealias CollapsedSection = (section: SectionHeader, sectionHashes: [Int])

        var collapsedSections: [CollapsedSection] = []
        var collapsedSectionHashes: [Int] = []

        // Create new sections for each collapsed range
        for range in rangesToCollapse {
            for sectionElement in sections[range] {
                typedEvents.append(contentsOf: sectionElement.typedEvents)
            }

            collapsedSectionHashes.append(contentsOf: sections[range].compactMap { $0.hashValue })

            if let startIndex = range.first {
                let smallChanges = typedEvents.flatMap { $0.smallChanges }
                let collapsedSmallEvent = Event.Small(smallChanges: smallChanges)
                let smallTypedEvent = TypedEvent.small(collapsedSmallEvent)

                let smallChangeDates = smallChanges.compactMap { isoDateFormatter.date(from: $0.timestampString) }
                var dateRange: DateInterval?
                if let minDate = smallChangeDates.min(), let maxDate = smallChangeDates.max() {
                    dateRange = DateInterval(start: minDate, end: maxDate)
                }

                let section = SectionHeader(timestamp: sections[startIndex].timestamp, typedEvents: [smallTypedEvent], subtitleDateFormatter: dayMonthNumberYearDateFormatter, dateRange: dateRange)
                collapsedSections.append((section, collapsedSectionHashes))
            }

            typedEvents = []
            collapsedSectionHashes = []
        }

        var newlyCollapsedSectionHashes: [Int] = []

        // Returns the small event collapsed section that represents the `sectionHash`, if one exists
        func firstCollapsedSectionContaining(sectionHash: Int) -> CollapsedSection? {
            return collapsedSections
                .first { collapsedSection in collapsedSection.sectionHashes.contains(sectionHash) }
        }

        // Reconstruct sections with newly eligible small event sections collapsed in proper order
        for section in sections {
            if let collapsedSection = firstCollapsedSectionContaining(sectionHash: section.hashValue), !newlyCollapsedSectionHashes.contains(section.hashValue) {
                mutatedSections.append(collapsedSection.section)
                newlyCollapsedSectionHashes.append(contentsOf: collapsedSection.sectionHashes)
            }

            if !newlyCollapsedSectionHashes.contains(section.hashValue) {
                mutatedSections.append(section)
            }
        }

        return mutatedSections
    }

    static func eventDisplayTimestamp(timestampString: String) -> String? {
        let isoDateFormatter = ISO8601DateFormatter()

        guard
            let shortFormatter = DateFormatter.wmf_24hshortTimeWithUTCTimeZone(),
            let date = isoDateFormatter.date(from: timestampString) else {
                return nil
        }

        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date, to: Date())

        if let hours = components.hour, let minutes = components.minute {
            switch hours {
            case ..<1:
                return String.localizedStringWithFormat(WMFLocalizedDateFormatStrings.minutesAgo(), minutes)
            case ..<24:
                return String.localizedStringWithFormat(WMFLocalizedDateFormatStrings.hoursAgo(), hours)
            default:
                break
            }
        }

        return shortFormatter.string(from: date)
    }
    
    static func displayTimestamp(timestampString: String, fullyRelative: Bool) -> String? {
        if let isoDateFormatter = DateFormatter.wmf_iso8601(),
           let timeDateFormatter = DateFormatter.wmf_24hshortTimeWithUTCTimeZone(),
           let date = isoDateFormatter.date(from: timestampString) {
            if fullyRelative {
                let relativeTime = (date as NSDate).wmf_fullyLocalizedRelativeDateStringFromLocalDateToNow()
                return relativeTime
            } else {
                let calendar = NSCalendar.current
                let unitFlags:Set<Calendar.Component> = [.day]
                let components = calendar.dateComponents(unitFlags, from: date, to: Date())
                if let numberOfDays = components.day {
                    switch numberOfDays {
                    case 0:
                        let relativeTime = (date as NSDate).wmf_fullyLocalizedRelativeDateStringFromLocalDateToNow()
                        return relativeTime
                    default:
                        let shortTime = timeDateFormatter.string(from: date)
                        return shortTime
                    }
                }
            }
        }
        
        return nil
    }
}

//MARK: SectionHeader

public extension ArticleAsLivingDocViewModel {
    
    class SectionHeader: Hashable {
        public let title: String
        public let subtitleTimestampDisplay: String
        public let timestamp: Date
        public let dateRange: DateInterval?
        public var typedEvents: [TypedEvent]

        private let sectionTimestampIdentifier: String

        private static let calendar: Calendar = Calendar.current

        private static let relativeDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.doesRelativeDateFormatting = true
            formatter.timeStyle = .none
            formatter.dateStyle = .short
            return formatter
        }()

        private static let dayMonthYearFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMMM d, yyyy")
            return formatter
        }()

        private static let dayMonthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMMM d")
            return formatter
        }()

        public init(timestamp: Date, typedEvents: [TypedEvent], subtitleDateFormatter: DateFormatter, dateRange: DateInterval? = nil) {

            // If today or yesterday, show friendly localized relative format ("Today", "Yesterday")
            func relativelyFormat(date: Date) -> String {
                let nsTimestamp = timestamp as NSDate
                if SectionHeader.calendar.isDateInToday(date) || SectionHeader.calendar.isDateInYesterday(date) {
                    return SectionHeader.relativeDateFormatter.string(from: date)
                } else {
                    return nsTimestamp.wmf_fullyLocalizedRelativeDateStringFromLocalDateToNow()
                }
            }

            self.title = relativelyFormat(date: timestamp)

            if let dateRange = dateRange {
                var dateRangeStrings: [String] = []

                let startDate = dateRange.start
                let endDate = dateRange.end

                if SectionHeader.calendar.isDateInToday(endDate) || SectionHeader.calendar.isDateInYesterday(endDate) {
                    let endString = relativelyFormat(date: endDate)
                    let startString = SectionHeader.dayMonthYearFormatter.string(from: startDate)
                    dateRangeStrings.append(contentsOf: [endString, startString])
                } else {
                    let endString = SectionHeader.dayMonthFormatter.string(from: endDate)
                    let startString = SectionHeader.dayMonthYearFormatter.string(from: startDate)
                    dateRangeStrings.append(contentsOf: [endString, startString])
                }

                self.subtitleTimestampDisplay = dateRangeStrings.joined(separator: " - ")
            } else {
                self.subtitleTimestampDisplay = SectionHeader.dayMonthYearFormatter.string(from: timestamp)
            }

            self.dateRange = dateRange
            self.timestamp = timestamp
            self.typedEvents = typedEvents
            self.sectionTimestampIdentifier = subtitleDateFormatter.string(from: timestamp)
        }
        
        public static func == (lhs: ArticleAsLivingDocViewModel.SectionHeader, rhs: ArticleAsLivingDocViewModel.SectionHeader) -> Bool {
            return lhs.sectionTimestampIdentifier == rhs.sectionTimestampIdentifier
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(sectionTimestampIdentifier)
            hasher.combine(typedEvents)
        }

        // MARK: - Helpers

        public var containsOnlySmallEvents: Bool {
            typedEvents.count == 1 && typedEvents.allSatisfy { event in event.isSmall }
        }

    }
}

//MARK: Events

public extension ArticleAsLivingDocViewModel {
    
    enum TypedEvent: Hashable {
        case small(Event.Small)
        case large(Event.Large)
        
        public static func == (lhs: ArticleAsLivingDocViewModel.TypedEvent, rhs: ArticleAsLivingDocViewModel.TypedEvent) -> Bool {
            switch lhs {
            case .large(let leftLargeEvent):
                switch rhs {
                case .large(let rightLargeEvent):
                    return leftLargeEvent == rightLargeEvent
                default:
                    return false
                }
            case .small(let leftSmallEvent):
                switch rhs {
                case .small(let rightSmallEvent):
                    return leftSmallEvent == rightSmallEvent
                default:
                    return false
                }
            
            }
        }
        
        public func hash(into hasher: inout Hasher) {
            switch self {
            case .small(let smallEvent):
                smallEvent.smallChanges.forEach { hasher.combine($0.revId) }
            case .large(let largeEvent):
                hasher.combine(largeEvent.revId)
                hasher.combine(largeEvent.wereThanksSent)
            }
        }

        // MARK: - Helpers

        public var isSmall: Bool {
            switch self {
            case .small(_):
                return true
            default:
                return false
            }
        }

        public var smallChanges: [SignificantEvents.Event.Small] {
            switch self {
            case .small(let small):
                return small.smallChanges
            default:
                return []
            }
        }
    }
}

public extension ArticleAsLivingDocViewModel {
    
    struct Event {
        
        public class Small: Equatable {
            
            private var lastTraitCollection: UITraitCollection?
            private var lastTheme: Theme?
            public lazy var eventDescription = {
                return String.localizedStringWithFormat(
                    CommonStrings.smallChangeDescription,
                    smallChanges.count)
            }()
            public let smallChanges: [SignificantEvents.Event.Small]
            public var loggingPosition = 0
            
            public init?(typedEvents: [SignificantEvents.TypedEvent]) {                
                var smallChanges: [SignificantEvents.Event.Small] = []
                for event in typedEvents {
                    switch event {
                    case .small(let smallChange):
                        smallChanges.append(smallChange)
                    default:
                        return nil
                    }
                }
                
                guard smallChanges.count > 0 else {
                    return nil
                }
                
                self.smallChanges = smallChanges
            }
            
            public init(smallChanges: [SignificantEvents.Event.Small]) {
                self.smallChanges = smallChanges
            }
            
            public static func == (lhs: ArticleAsLivingDocViewModel.Event.Small, rhs: ArticleAsLivingDocViewModel.Event.Small) -> Bool {
                return lhs.smallChanges == rhs.smallChanges
            }
            
            //Only used in the html portion of the feature
            func timestampForDisplay() -> String? {
                
                guard let timestampString = smallChanges.first?.timestampString else {
                    return nil
                }
                
                let displayTimestamp = ArticleAsLivingDocViewModel.displayTimestamp(timestampString: timestampString, fullyRelative: true)
                
                return displayTimestamp
            }
        }
        
        public class Large: Equatable {
            
            public enum ChangeDetail {
                case snippet(Snippet) //use for a basic horizontally scrolling snippet cell (will contain talk page topic snippets, added text snippets, article description updated snippets)
                case reference(Reference)
            }
            
            public struct Snippet {
                public let description: NSAttributedString
            }
            
            public struct Reference {
                public let type: String
                public let description: NSAttributedString
                public let accessDateYearDisplay: String?
                
                init?(type: String, description: NSAttributedString?, accessDateYearDisplay: String?) {
                    guard let description = description else {
                        return nil
                    }
                    
                    self.type = type
                    self.description = description
                    self.accessDateYearDisplay = accessDateYearDisplay
                }
            }
            
            public enum UserType {
                case standard
                case anonymous
                case bot
            }
            
            public enum ButtonsToDisplay {
                case thankAndViewChanges(userId: UInt, revisionId: UInt)
                case viewDiscussion(sectionName: String?)
            }
            
            public let typedEvent: SignificantEvents.TypedEvent
            
            private var lastTraitCollection: UITraitCollection?
            private var lastTheme: Theme?
            
            private(set) var eventDescription: NSAttributedString?
            private(set) var sideScrollingCollectionViewHeight: CGFloat?
            private(set) var changeDetails: [ChangeDetail]?
            private(set) var displayTimestamp: String?
            private(set) var userInfo: NSAttributedString?
            let userId: UInt
            public let userType: UserType
            public let buttonsToDisplay: ButtonsToDisplay
            public let revId: UInt
            public let parentId: UInt
            public var wereThanksSent = false
            public var loggingPosition = 0
            
            init?(typedEvent: SignificantEvents.TypedEvent) {
                
                let userGroups: [String]?
                switch typedEvent {
                case .newTalkPageTopic(let newTalkPageTopic):
                    self.userId = newTalkPageTopic.userId
                    userGroups = newTalkPageTopic.userGroups
                    
                    if let talkPageSection = newTalkPageTopic.section {
                        self.buttonsToDisplay = .viewDiscussion(sectionName: Self.sectionTitleWithWikitextAndHtmlStripped(originalTitle: talkPageSection))
                    } else {
                        self.buttonsToDisplay = .viewDiscussion(sectionName: nil)
                    }
                    
                case .large(let largeChange):
                    self.userId = largeChange.userId
                    userGroups = largeChange.userGroups
                    self.buttonsToDisplay = .thankAndViewChanges(userId: largeChange.userId, revisionId: largeChange.revId)
                case .vandalismRevert(let vandalismRevert):
                    self.userId = vandalismRevert.userId
                    userGroups = vandalismRevert.userGroups
                    self.buttonsToDisplay = .thankAndViewChanges(userId: vandalismRevert.userId, revisionId: vandalismRevert.revId)
                case .small:
                    return nil
                }
                
                if let userGroups = userGroups,
                   userGroups.contains("bot") {
                    userType = .bot
                } else if self.userId == 0 {
                    userType = .anonymous
                } else {
                    userType = .standard
                }
                
                self.typedEvent = typedEvent
                switch typedEvent {
                case .large(let largeChange):
                    revId = largeChange.revId
                    parentId = largeChange.parentId
                case .newTalkPageTopic(let newTalkPageTopic):
                    revId = newTalkPageTopic.revId
                    parentId = newTalkPageTopic.parentId
                case .vandalismRevert(let vandalismRevert):
                    revId = vandalismRevert.revId
                    parentId = vandalismRevert.parentId
                default:
                    assertionFailure("Shouldn't happen")
                    revId = 0
                    parentId = 0
                }
            }
            
            public static func == (lhs: ArticleAsLivingDocViewModel.Event.Large, rhs: ArticleAsLivingDocViewModel.Event.Large) -> Bool {
                return lhs.revId == rhs.revId && lhs.wereThanksSent == rhs.wereThanksSent
            }
            
        }

    }
}

//MARK: Large Event Type Helper methods

public extension ArticleAsLivingDocViewModel.Event.Large {
    
    func articleInsertHtmlSnippet(isFirst: Bool = false, isLast: Bool = false, indexPath: IndexPath) -> String? {
        guard let timestampForDisplay = self.fullyRelativeTimestampForDisplay(),
              let eventDescription = eventDescriptionHtmlSnippet(indexPath: indexPath),
              let userInfo = userInfoHtmlSnippet() else {
            return nil
        }
        
        let liElementIdName = isFirst ? "significant-changes-first-list" : isLast ? "significant-changes-last-list" : "significant-changes-list"
        
        let lastUserInfoIdAdditions = isLast ? " id='significant-changes-userInfo-last'" : ""
        
        return "<li id='\(liElementIdName)'><p class='significant-changes-timestamp'>\(timestampForDisplay)</p><p class='significant-changes-description'>\(eventDescription)</p><p class='significant-changes-userInfo'\(lastUserInfoIdAdditions)>\(userInfo)</p></li>"
    }
    
    private func htmlSignificantEventsLinkOpeningTagForIndexPath(_ indexPath: IndexPath, loggingDescriptionType: ArticleAsLivingDocFunnel.ArticleContentInsertEventDescriptionType) -> String {
        return "<a href='#significant-events-\(indexPath.item)-\(indexPath.section)-\(loggingDescriptionType.rawValue)'>"
    }
    
    private var htmlSignificantEventsLinkEndingTag: String {
        return "</a>"
    }
    
    private func eventDescriptionHtmlSnippet(indexPath: IndexPath) -> String? {
        
        let sections = sectionsSet()
        let sectionsHtml = localizedSectionHtmlSnippet(sectionsSet: sections)
        
        let eventDescription: String
        switch typedEvent {
        case .newTalkPageTopic:
            let discussionText = htmlSignificantEventsLinkOpeningTagForIndexPath(indexPath, loggingDescriptionType: .discussion) + CommonStrings.newTalkTopicDiscussion + htmlSignificantEventsLinkEndingTag
            eventDescription = String.localizedStringWithFormat(CommonStrings.newTalkTopicDescriptionFormat, discussionText)
        case .vandalismRevert:
            let event = htmlSignificantEventsLinkOpeningTagForIndexPath(indexPath, loggingDescriptionType: .vandalism) + CommonStrings.vandalismRevertDescription + htmlSignificantEventsLinkEndingTag
            if let sectionsHtml = sectionsHtml {
                eventDescription = event + sectionsHtml
            } else {
                eventDescription = event
            }
        case .large(let largeChange):
            
            guard let mergedDescription = mergedDescriptionForTypedChanges(largeChange.typedChanges, htmlInsertIndexPath: indexPath) else {
                assertionFailure("This should not happen")
                return nil
            }
            
            if let sectionsHtml = sectionsHtml {
                eventDescription = mergedDescription + sectionsHtml
            } else {
                eventDescription = mergedDescription
            }
            
        case .small:
            assertionFailure("This should not happen")
            return nil
        }
        
        return eventDescription
    }
    
    private func mergedDescriptionForTypedChanges(_ changes: [SignificantEvents.TypedChange], htmlInsertIndexPath: IndexPath?) -> String? {
        
        let individualDescriptions = self.individualDescriptionsForTypedChanges(changes)
        let sortedDescriptions = individualDescriptions.sorted { $0.priority < $1.priority }
        
        // Slightly different logic when creating this for the article content html insert.
        // We need to wrap individual descriptions into links, and condense multiple changes into "Multiple changes made" link.
        
        if let htmlInsertIndexPath = htmlInsertIndexPath {
            switch sortedDescriptions.count {
            case 0:
                assertionFailure("This should not happen")
                return nil
            case 1:
                let description = sortedDescriptions[0].text
                return htmlSignificantEventsLinkOpeningTagForIndexPath(htmlInsertIndexPath, loggingDescriptionType: .single) + description + htmlSignificantEventsLinkEndingTag
            default:
                return htmlSignificantEventsLinkOpeningTagForIndexPath(htmlInsertIndexPath, loggingDescriptionType: .multiple) + CommonStrings.multipleChangesMadeDescription + htmlSignificantEventsLinkEndingTag
            }
        }
        
        let mergedDescription = ListFormatter.localizedString(byJoining: sortedDescriptions.map { $0.text })
        return mergedDescription.isEmpty ? nil : mergedDescription
    }
    
    // if trait collection or theme is different from the last time attributed strings were generated,
    // reset to nil to trigger generation again the next time it's requested
    func resetAttributedStringsIfNeededWithTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) {
        if let lastTraitCollection = lastTraitCollection,
           let lastTheme = lastTheme,
           lastTraitCollection != traitCollection || lastTheme != theme {
            eventDescription = nil
            sideScrollingCollectionViewHeight = nil
            changeDetails = nil
            userInfo = nil
            Self.heightForThreeLineSnippet = nil
            Self.heightForReferenceTitle = nil
        }
        
        lastTraitCollection = traitCollection
        lastTheme = theme
    }
    
    func eventDescriptionForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString? {
        
        if let eventDescription = eventDescription {
            return eventDescription
        }
        
        let sections = sectionsSet()
        let sectionsAttributedString = localizedSectionAttributedString(sectionsSet: sections, traitCollection: traitCollection, theme: theme)
        
        let font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor: theme.colors.primaryText]
        
        let eventDescriptionMutableAttributedString: NSMutableAttributedString = NSMutableAttributedString(string: "")
        switch typedEvent {
        case .newTalkPageTopic:
            let localizedString = String.localizedStringWithFormat(CommonStrings.newTalkTopicDescriptionFormat, CommonStrings.newTalkTopicDiscussion)
            let eventAttributedString = NSAttributedString(string: localizedString, attributes: attributes)
            eventDescriptionMutableAttributedString.append(eventAttributedString)
            
        case .vandalismRevert:
            
            let event = CommonStrings.vandalismRevertDescription
            
            let eventAttributedString = NSAttributedString(string: event, attributes: attributes)
            eventDescriptionMutableAttributedString.append(eventAttributedString)
        
        case .large(let largeChange):
            
            guard let mergedDescription = mergedDescriptionForTypedChanges(largeChange.typedChanges, htmlInsertIndexPath: nil) else {
                assertionFailure("This should not happen")
                break
            }
            
            let mergedDescriptionAttributedString = NSAttributedString(string: mergedDescription, attributes: attributes)
            eventDescriptionMutableAttributedString.append(mergedDescriptionAttributedString)
            
        case .small:
            assertionFailure("Unexpected timeline event type")
            break
        }
        
        if let sectionsAttributedString = sectionsAttributedString {
            eventDescriptionMutableAttributedString.append(sectionsAttributedString)
        }
        
        guard let finalEventAttributedString = eventDescriptionMutableAttributedString.copy() as? NSAttributedString else {
            assertionFailure("This should not happen")
            return nil
        }
        
        eventDescription = finalEventAttributedString
        return finalEventAttributedString
    }
    
    struct IndividualDescription {
        let priority: Int //used for sorting
        let text: String
    }
    
    private func individualDescriptionsForTypedChanges(_ typedChanges: [SignificantEvents.TypedChange]) -> [IndividualDescription] {
        
        var descriptions: [IndividualDescription] = []
        var numReferences = 0
        for typedChange in typedChanges {
            switch typedChange {
            case .addedText(let addedText):
                let countNumber = NSNumber(value: addedText.characterCount)
                let characterCount = "\(NumberFormatter.localizedThousandsStringFromNumber(countNumber).localizedLowercase) " + String.localizedStringWithFormat(CommonStrings.charactersTextDescription, addedText.characterCount)
                let description = String.localizedStringWithFormat(CommonStrings.addedTextDescription, characterCount)
                descriptions.append(IndividualDescription(priority: 1, text: description))
            case .deletedText(let deletedText):
                let countNumber = NSNumber(value: deletedText.characterCount)
                let characterCount = "\(NumberFormatter.localizedThousandsStringFromNumber(countNumber).localizedLowercase) " + String.localizedStringWithFormat(CommonStrings.charactersTextDescription, deletedText.characterCount)
                let description = String.localizedStringWithFormat(CommonStrings.deletedTextDescription, characterCount)
                descriptions.append(IndividualDescription(priority: 2, text: description))
            case .newTemplate(let newTemplate):
                var numArticleDescriptions = 0
                for template in newTemplate.typedTemplates {
                    switch template {
                    case .articleDescription:
                        numArticleDescriptions += 1
                    case .bookCitation,
                         .journalCitation,
                         .newsCitation,
                         .websiteCitation:
                        numReferences += 1
                    }
                }
                
                if numArticleDescriptions > 0 {
                    let description = CommonStrings.articleDescriptionUpdatedDescription
                    descriptions.append(IndividualDescription(priority: 3, text: description))
                }
            }
        }
        
        if descriptions.count == 0 {
            switch numReferences {
            case 0:
                break
            case 1:
                let description = CommonStrings.singleReferenceAddedDescription
                descriptions.append(IndividualDescription(priority: 0, text: description))
            default:
                let description = CommonStrings.multipleReferencesAddedDescription
                descriptions.append(IndividualDescription(priority: 0, text: description))
            }
        } else {
            if numReferences > 0 {
                let description = String.localizedStringWithFormat(CommonStrings.numericalMultipleReferencesAddedDescription, numReferences)
                descriptions.append(IndividualDescription(priority: 0, text: description))
            }
        }
        
        return descriptions
    }
    
    private func sectionsSet() -> Set<String> {
        let set: Set<String>
        switch typedEvent {
        case .newTalkPageTopic:
            set = Set<String>()
        case .vandalismRevert(let vandalismRevert):
            set = Set(vandalismRevert.sections)
        case .large(let largeChange):
            var sections: [String] = []
            for typedChange in largeChange.typedChanges {
                switch typedChange {
                case .addedText(let addedTextChange):
                    sections.append(contentsOf: addedTextChange.sections)
                case .deletedText(let deletedTextChange):
                    sections.append(contentsOf: deletedTextChange.sections)
                case .newTemplate(let newTemplate):
                    sections.append(contentsOf: newTemplate.sections)
                }
            }
            
            set = Set(sections)
        case .small:
            assertionFailure("This shouldn't happen")
            set = Set<String>()
        }
        
        //strip == signs from all section titles
        let finalSet = set.map { Self.sectionTitleWithWikitextAndHtmlStripped(originalTitle: $0) }

        return Set(finalSet)
    }
    
    //remove one or more equal signs and zero or more spaces on either side of the title text
    //also removing html for display and potential javascript injection issues - https://phabricator.wikimedia.org/T268201
    private static func sectionTitleWithWikitextAndHtmlStripped(originalTitle: String) -> String {
        var loopTitle = originalTitle.removingHTML
        
        let regex = "^=+\\s*|\\s*=+$"
        var maybeMatch = loopTitle.range(of: regex, options: .regularExpression)
        while let match = maybeMatch {
            loopTitle.removeSubrange(match)
            maybeMatch = loopTitle.range(of: regex, options: .regularExpression)
        }

        return loopTitle
    }
    
    private func localizedStringFromSections(sections: [String]) -> String? {
        var localizedString: String
        switch sections.count {
        case 0:
            return nil
        case 1:
            let firstSection = sections[0]
            localizedString = String.localizedStringWithFormat(CommonStrings.oneSectionDescription, firstSection)
        case 2:
            let firstSection = sections[0]
            let secondSection = sections[1]
            localizedString = String.localizedStringWithFormat(CommonStrings.twoSectionsDescription, firstSection, secondSection)
        default:
            localizedString = String.localizedStringWithFormat(CommonStrings.manySectionsDescription, sections.count)
        }

        return " " + localizedString
    }
    
    private func localizedSectionHtmlSnippet(sectionsSet: Set<String>) -> String? {
        
        let sections = Array(sectionsSet)
        guard let localizedString = localizedStringFromSections(sections: sections) else {
            return nil
        }
        
        let mutableLocalizedString = NSMutableString(string: localizedString)

        var ranges: [NSRange] = []
        for section in sections {
            let rangeOfSection = (localizedString as NSString).range(of: section)
            let rangeValid = rangeOfSection.location != NSNotFound && rangeOfSection.location + rangeOfSection.length <= localizedString.count
            if rangeValid {
                ranges.append(rangeOfSection)
            }
        }

        var offset = 0
        for range in ranges {
            let italicStart = "<i>"
            let italicEnd = "</i>"
            mutableLocalizedString.insert(italicStart, at: range.location + offset)
            offset += italicStart.count
            mutableLocalizedString.insert(italicEnd, at: range.location + range.length + offset)
            offset += italicEnd.count
        }
        
        if let returnString = mutableLocalizedString.copy() as? NSString {
            return returnString as String
        } else {
            assertionFailure("This shouldn't happen")
            return nil
        }
    }
    
    private func localizedSectionAttributedString(sectionsSet: Set<String>, traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString? {
        let sections = Array(sectionsSet)
        guard let localizedString = localizedStringFromSections(sections: sections) else {
            return nil
        }
        
        let font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        let italicFont = UIFont.wmf_font(.italicBody, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor: theme.colors.primaryText]
        
        var ranges: [NSRange] = []
        for section in sections {
            let rangeOfSection = (localizedString as NSString).range(of: section)
            let rangeValid = rangeOfSection.location != NSNotFound && rangeOfSection.location + rangeOfSection.length <= localizedString.count
            if rangeValid {
                ranges.append(rangeOfSection)
            }
        }
        
        let mutableAttributedString = NSMutableAttributedString(string: localizedString, attributes: attributes)
        
        for range in ranges {
            mutableAttributedString.addAttribute(NSAttributedString.Key.font, value: italicFont, range: range)
        }
        
        guard let attributedString = mutableAttributedString.copy() as? NSAttributedString else {
            assertionFailure("This shouldn't happen")
            return NSAttributedString(string: localizedString, attributes: attributes)
        }
        
        return attributedString
    }
    
    static let sideScrollingCellPadding = UIEdgeInsets(top: 17, left: 15, bottom: 17, right: 15)
    static let sideScrollingCellWidth: CGFloat = 250
    static var availableSideScrollingCellWidth: CGFloat = {
        return sideScrollingCellWidth - sideScrollingCellPadding.left - sideScrollingCellPadding.right
    }()

    private static let changeDetailDescriptionTextStyle = DynamicTextStyle.subheadline
    private static let changeDetailDescriptionTextStyleItalic = DynamicTextStyle.italicSubheadline
    private static let changeDetailDescriptionFontWeight = UIFont.Weight.regular

    static let changeDetailReferenceTitleStyle = DynamicTextStyle.semiboldSubheadline
    static let changeDetailReferenceTitleDescriptionSpacing: CGFloat = 13
    static let additionalPointsForShadow: CGFloat = 16
    
    @discardableResult func calculateSideScrollingCollectionViewHeightForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> CGFloat {
        
        if let sideScrollingCollectionViewHeight = sideScrollingCollectionViewHeight {
            return sideScrollingCollectionViewHeight
        }
        
        let changeDetails = changeDetailsForTraitCollection(traitCollection, theme: theme)
        
        let tallestSnippetContentHeight: CGFloat = calculateTallestSnippetContentHeightInChangeDetails(changeDetails: changeDetails)
        let tallestReferenceChangeDetailHeight: CGFloat = calculateTallestReferenceContentHeightInChangeDetails(changeDetails: changeDetails, traitCollection: traitCollection, theme: theme)

        let maxContentHeight = maxContentHeightFromTallestSnippetContentHeight(tallestSnippetContentHeight: tallestSnippetContentHeight, tallestReferenceContentHeight: tallestReferenceChangeDetailHeight, traitCollection: traitCollection, theme: theme)

        let finalHeight = maxContentHeight == 0 ? 0 : maxContentHeight + Self.sideScrollingCellPadding.top + Self.sideScrollingCellPadding.bottom + Self.additionalPointsForShadow
        self.sideScrollingCollectionViewHeight = finalHeight
        return finalHeight
    }
    
    func changeDetailsForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> [ChangeDetail] {
        if let changeDetails = changeDetails {
            return changeDetails
        }
        
        var changeDetails: [ChangeDetail] = []
        
        switch typedEvent {
        case .newTalkPageTopic(let newTalkPageTopic):
            let attributedString = newTalkPageTopic.snippet.byAttributingHTML(with: Self.changeDetailDescriptionTextStyle, boldWeight: Self.changeDetailDescriptionFontWeight, matching: traitCollection, color: theme.colors.primaryText, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true)
            let changeDetail = ChangeDetail.snippet(Snippet(description: attributedString))
            changeDetails.append(changeDetail)
        case .large(let largeChange):
            for typedChange in largeChange.typedChanges {
                switch typedChange {
                case .addedText(let addedText):
                    //TODO: Add highlighting here. For snippetType 1, add a highlighting attribute across the whole string. Otherwise, seek out highlight-add span ranges and add those attributes
                    guard let snippet = addedText.snippet else {
                        continue
                    }
                    
                    let attributedString = snippet.byAttributingHTML(with: Self.changeDetailDescriptionTextStyle, boldWeight: Self.changeDetailDescriptionFontWeight, matching: traitCollection, color: theme.colors.primaryText, handlingLinks: true, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true)
                    let changeDetail = ChangeDetail.snippet(Snippet(description: attributedString))
                    changeDetails.append(changeDetail)
                case .deletedText:
                    continue;
                case .newTemplate(let newTemplate):
                    for template in newTemplate.typedTemplates {
                        
                        switch template {
                        case .articleDescription(let articleDescription):
                            let font = UIFont.wmf_font(Self.changeDetailDescriptionTextStyle, compatibleWithTraitCollection: traitCollection)
                            let attributes = [NSAttributedString.Key.font: font,
                                              NSAttributedString.Key.foregroundColor:
                                                theme.colors.primaryText]
                            let attributedString = NSAttributedString(string: articleDescription.text, attributes: attributes)
                            let changeDetail = ChangeDetail.snippet(Snippet(description: attributedString))
                            changeDetails.append(changeDetail)
                            //tonitodo: these code blocks are all very similar. make a generic method instead?
                        case .bookCitation(let bookCitation):
                            let typeText = referenceTypeForTemplate(template, traitCollection: traitCollection, theme: theme)
                            let accessYear = accessDateYearForTemplate(template, traitCollection: traitCollection, theme: theme)
                            let bookCitationDescription = descriptionForBookCitation(bookCitation, traitCollection: traitCollection, theme: theme)
                            if let reference = Reference(type: typeText, description: bookCitationDescription, accessDateYearDisplay: accessYear) {
                                let changeDetail = ChangeDetail.reference(reference)
                                changeDetails.append(changeDetail)
                            }
                        case .journalCitation(let journalCitation):
                            let typeText = referenceTypeForTemplate(template, traitCollection: traitCollection, theme: theme)
                            let accessYear = accessDateYearForTemplate(template, traitCollection: traitCollection, theme: theme)
                            let citationDescription = descriptionForJournalCitation(journalCitation, traitCollection: traitCollection, theme: theme)
                            if let reference = Reference(type: typeText, description: citationDescription, accessDateYearDisplay: accessYear) {
                                let changeDetail = ChangeDetail.reference(reference)
                                changeDetails.append(changeDetail)
                            }
                        case .newsCitation(let newsCitation):
                            let typeText = referenceTypeForTemplate(template, traitCollection: traitCollection, theme: theme)
                            let accessYear = accessDateYearForTemplate(template, traitCollection: traitCollection, theme: theme)
                            let citationDescription = descriptionForNewsCitation(newsCitation, traitCollection: traitCollection, theme: theme)
                            if let reference = Reference(type: typeText, description: citationDescription, accessDateYearDisplay: accessYear) {
                                let changeDetail = ChangeDetail.reference(reference)
                                changeDetails.append(changeDetail)
                            }
                        case .websiteCitation(let websiteCitation):
                            let typeText = referenceTypeForTemplate(template, traitCollection: traitCollection, theme: theme)
                            let accessYear = accessDateYearForTemplate(template, traitCollection: traitCollection, theme: theme)
                            let citationDescription = descriptionForWebsiteCitation(websiteCitation, traitCollection: traitCollection, theme: theme)
                            if let reference = Reference(type: typeText, description: citationDescription, accessDateYearDisplay: accessYear) {
                                let changeDetail = ChangeDetail.reference(reference)
                                changeDetails.append(changeDetail)
                            }
                        }
                    }
                }
            }
        case .vandalismRevert:
            return []
        case .small:
            assertionFailure("This should not happen")
            return []
        }
        
        self.changeDetails = changeDetails
        return changeDetails
    }
    
    // Note: heightForThreeLineSnippet and heightForReferenceTitle methods are placeholder calculations when determining a side scrolling cell's content height.
    // When there are no reference cells, we are capping off article content snippet cells at 3 lines. If there are reference cells, snippet cells are allowed to show lines to the full height of the tallest reference cell.
    // Reference cells titles are only ever 1 line, so we are using placeholder text to calculate that rather than going up against actual view model title values, since the height will be the same regardless of the size of the title value
    // heightForThreeLine and heightForReferenceTitle only ever needs to be calculated once per traitCollection's preferredContentSize, so we are optimizing in the similar way that ArticleAsLivingDocViewModel's various NSAttributedStrings are optimized, i.e. calculate once, then reset when the traitCollection changes via resetAttributedStringsIfNeededWithTraitCollection.
    private static var heightForThreeLineSnippet: CGFloat?
    private static func heightForThreeLineSnippetForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> CGFloat {
        
        if let heightForThreeLineSnippet = heightForThreeLineSnippet {
            return heightForThreeLineSnippet
        }
        
        let snippetFont = UIFont.wmf_font(Self.changeDetailDescriptionTextStyle, compatibleWithTraitCollection: traitCollection)
        let snippetAttributes = [NSAttributedString.Key.font: snippetFont]
        let threeLineSnippetText = """
                                1
                                2
                                3
                            """
        let threeLineSnippetAttString = NSAttributedString(string: threeLineSnippetText, attributes: snippetAttributes)
        
        let finalHeight = ceil(threeLineSnippetAttString.boundingRect(with: CGSize(width: Self.availableSideScrollingCellWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
        heightForThreeLineSnippet = finalHeight
        return finalHeight
    }
    
    private static var heightForReferenceTitle: CGFloat?
    private static func heightForReferenceTitleForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> CGFloat {
        
        if let heightForReferenceTitle = heightForReferenceTitle {
            return heightForReferenceTitle
        }
        
        let referenceTitleFont = UIFont.wmf_font(Self.changeDetailReferenceTitleStyle, compatibleWithTraitCollection: traitCollection)
        let referenceTitleAttributes = [NSAttributedString.Key.font: referenceTitleFont]
        let oneLineTitleText = "1"
        let oneLineTitleAttString = NSAttributedString(string: oneLineTitleText, attributes: referenceTitleAttributes)
        let finalHeight = ceil(oneLineTitleAttString.boundingRect(with: CGSize(width: Self.availableSideScrollingCellWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
        heightForReferenceTitle = finalHeight
        return finalHeight
    }
    
    private func calculateTallestSnippetContentHeightInChangeDetails(changeDetails: [ChangeDetail]) -> CGFloat {
        var tallestSnippetChangeDetailHeight: CGFloat = 0

        changeDetails.forEach { (changeDetail) in
            switch changeDetail {
            case .snippet(let snippet):
                let snippetHeight = ceil(snippet.description.boundingRect(with: CGSize(width: Self.availableSideScrollingCellWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
                
                if tallestSnippetChangeDetailHeight < snippetHeight {
                    tallestSnippetChangeDetailHeight = snippetHeight
                }
                
            case .reference:
                break
            }
        }
        
        return tallestSnippetChangeDetailHeight
    }
    
    private func calculateTallestReferenceContentHeightInChangeDetails(changeDetails: [ChangeDetail], traitCollection: UITraitCollection, theme: Theme) -> CGFloat {
        var tallestReferenceChangeDetailHeight: CGFloat = 0
        
        changeDetails.forEach { (changeDetail) in
            switch changeDetail {
            case .snippet:
                break
            case .reference(let reference):
                let titleHeight = Self.heightForReferenceTitleForTraitCollection(traitCollection, theme: theme)
                let descriptionHeight = ceil(reference.description.boundingRect(with: CGSize(width: Self.availableSideScrollingCellWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
                let totalHeight = titleHeight + Self.changeDetailReferenceTitleDescriptionSpacing + descriptionHeight
                
                if tallestReferenceChangeDetailHeight < totalHeight {
                    tallestReferenceChangeDetailHeight = totalHeight
                }
            }
        }
        
        return tallestReferenceChangeDetailHeight
    }
    
    private func maxContentHeightFromTallestSnippetContentHeight(tallestSnippetContentHeight: CGFloat, tallestReferenceContentHeight: CGFloat, traitCollection: UITraitCollection, theme: Theme) -> CGFloat {
        
        guard tallestSnippetContentHeight > 0 else {
            return tallestReferenceContentHeight
        }
        
        let threeLineSnippetHeight = Self.heightForThreeLineSnippetForTraitCollection(traitCollection, theme: theme)
        if tallestReferenceContentHeight == 0 {
            return min(tallestSnippetContentHeight, threeLineSnippetHeight)
        } else {
            let finalSnippetHeight = min(tallestSnippetContentHeight, threeLineSnippetHeight)
            return max(tallestReferenceContentHeight, finalSnippetHeight)
        }
    }
    
    private func referenceTypeForTemplate(_ template: SignificantEvents.Template, traitCollection: UITraitCollection, theme: Theme) -> String {
        
        var typeString: String
        switch template {
        case .articleDescription:
            assertionFailure("This should not happen")
            return ""
        case .bookCitation:
            typeString = CommonStrings.newBookReferenceTitle
        case .journalCitation:
            typeString = CommonStrings.newJournalReferenceTitle
        case .newsCitation:
            typeString = CommonStrings.newNewsReferenceTitle
        case .websiteCitation:
            typeString = CommonStrings.newWebsiteReferenceTitle
            
        }
        
        return typeString
    }
    
    private func accessDateYearForTemplate(_ template: SignificantEvents.Template, traitCollection: UITraitCollection, theme: Theme) -> String? {
        
        let accessDateString: String?
        switch template {
        case .newsCitation(let newsCitation):
            accessDateString = newsCitation.accessDateString
        case .websiteCitation(let websiteCitation):
            accessDateString = websiteCitation.accessDateString
        default:
            return nil
        }
        
        if let accessDateString = accessDateString {
            let dateFormatter = DateFormatter.wmf_monthNameDayOfMonthNumberYear()
            if let date = dateFormatter?.date(from: accessDateString) {
                let yearDateFormatter = DateFormatter.wmf_year()
                let year = yearDateFormatter?.string(from: date)
                return year
            }
        }
        
        return nil
        
    }
    
    private func descriptionForJournalCitation(_ journalCitation: SignificantEvents.Citation.Journal, traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString? {
        
        let font = UIFont.wmf_font(Self.changeDetailDescriptionTextStyle, compatibleWithTraitCollection: traitCollection)
        let boldFont = UIFont.wmf_font(Self.changeDetailDescriptionTextStyleItalic, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        let boldAttributes = [NSAttributedString.Key.font: boldFont,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]

        let titleString = "\"\(journalCitation.title)\" "
        let mutableAttributedString = mutableString(from: titleString, linkedTo: journalCitation.urlString, with: attributes, linkColor: theme.colors.link)
        let titleAttributedString = mutableAttributedString.copy() as? NSAttributedString
        
        var descriptionStart = ""
        if let firstName = journalCitation.firstName {
            if let lastName = journalCitation.lastName {
                descriptionStart += "\(lastName), \(firstName)"
            }
        } else {
            if let lastName = journalCitation.lastName {
                descriptionStart += "\(lastName)"
            }
        }
         
        if let sourceDate = journalCitation.sourceDateString {
            descriptionStart += " (\(sourceDate)). "
        } else {
            descriptionStart += ". "
        }
        
        let descriptionStartAttributedString = NSAttributedString(string: descriptionStart, attributes: attributes)
        
        var volumeString = ""
        if let volumeNumber = journalCitation.volumeNumber {
            volumeString = String.localizedStringWithFormat(CommonStrings.newJournalReferenceVolume, volumeNumber)
        }
        let volumeAttributedString = NSAttributedString(string: "\(volumeString) ", attributes: boldAttributes)
        
        var descriptionEnd = ""
        if let database = journalCitation.database {
            let viaDatabaseString = String.localizedStringWithFormat(CommonStrings.newJournalReferenceDatabase, database)
            if let pages = journalCitation.pages {
                descriptionEnd += "\(pages) - \(viaDatabaseString)."
            } else {
                descriptionEnd += "\(viaDatabaseString)."
            }
        } else {
            if let pages = journalCitation.pages {
                descriptionEnd += "\(pages)."
            }
        }
        
        let descriptionEndAttributedString = NSAttributedString(string: descriptionEnd, attributes: attributes)

        let finalMutableAttributedString = NSMutableAttributedString(string: "")
        finalMutableAttributedString.append(descriptionStartAttributedString)
        if let titleAttributedString = titleAttributedString {
            finalMutableAttributedString.append(titleAttributedString)
        }
        finalMutableAttributedString.append(volumeAttributedString)
        finalMutableAttributedString.append(descriptionEndAttributedString)
        
        return finalMutableAttributedString.copy() as? NSAttributedString
        
    }
    
    private func descriptionForWebsiteCitation(_ websiteCitation: SignificantEvents.Citation.Website, traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString? {
        let font = UIFont.wmf_font(Self.changeDetailDescriptionTextStyle, compatibleWithTraitCollection: traitCollection)
        let italicFont = UIFont.wmf_font(Self.changeDetailDescriptionTextStyleItalic, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        let italicAttributes = [NSAttributedString.Key.font: italicFont,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        
        let titleString = "\"\(websiteCitation.title)\" "
        let mutableAttributedString = mutableString(from: titleString, linkedTo: websiteCitation.urlString, with: attributes, linkColor: theme.colors.link)
        let titleAttributedString = mutableAttributedString.copy() as? NSAttributedString
        
        var publisherText = ""
        if let publisher = websiteCitation.publisher {
            publisherText = "\(publisher). "
        }
        
        let publisherAttributedString = NSAttributedString(string: publisherText, attributes: italicAttributes)
        
        var accessDateString = ""
        if let accessDate = websiteCitation.accessDateString {
            accessDateString = "\(accessDate). "
        }
        
        let accessDateAttributedString = NSAttributedString(string: accessDateString, attributes: attributes)
        
        let finalMutableAttributedString = NSMutableAttributedString(string: "")
        if let titleAttributedString = titleAttributedString {
            finalMutableAttributedString.append(titleAttributedString)
        }
        finalMutableAttributedString.append(publisherAttributedString)
        finalMutableAttributedString.append(accessDateAttributedString)
        
        if let archiveDateString = websiteCitation.archiveDateString,
           let archiveUrlString = websiteCitation.archiveDotOrgUrlString,
           URL(string: archiveUrlString) != nil {
            let archiveLinkText = CommonStrings.newWebsiteReferenceArchiveUrlText
            let archiveLinkMutableAttributedString = mutableString(from: archiveLinkText, linkedTo: archiveUrlString, with: attributes, linkColor: theme.colors.link)

            if let archiveLinkAttributedString = archiveLinkMutableAttributedString.copy() as? NSAttributedString {
                let lastText = String.localizedStringWithFormat(CommonStrings.newWebsiteReferenceArchiveDateText, archiveDateString)
                let lastAttributedString = NSAttributedString(string: " \(lastText)", attributes: attributes)
                
                finalMutableAttributedString.append(archiveLinkAttributedString)
                finalMutableAttributedString.append(lastAttributedString)
                
            }
            
        }
        
        return finalMutableAttributedString.copy() as? NSAttributedString
    }
    
    private func descriptionForNewsCitation(_ newsCitation: SignificantEvents.Citation.News, traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString? {
        
        let font = UIFont.wmf_font(Self.changeDetailDescriptionTextStyle, compatibleWithTraitCollection: traitCollection)
        let italicFont = UIFont.wmf_font(Self.changeDetailDescriptionTextStyleItalic, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        let italicAttributes = [NSAttributedString.Key.font: italicFont,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        
        let titleString = "\"\(newsCitation.title)\" "
        let mutableAttributedString = mutableString(from: titleString, linkedTo: newsCitation.urlString, with: attributes, linkColor: theme.colors.link)
        let titleAttributedString = mutableAttributedString.copy() as? NSAttributedString
        
        var descriptionStart = ""
        if let firstName = newsCitation.firstName {
            if let lastName = newsCitation.lastName {
                descriptionStart += "\(lastName), \(firstName) "
            }
        } else {
            if let lastName = newsCitation.lastName {
                descriptionStart += "\(lastName) "
            }
        }
         
        if let sourceDate = newsCitation.sourceDateString {
            descriptionStart += "(\(sourceDate)). "
        } else {
            descriptionStart += ". "
        }
        
        let descriptionStartAttributedString = NSAttributedString(string: descriptionStart, attributes: attributes)
        
        var publicationText = ""
        if let publication = newsCitation.publication {
            publicationText = "\(publication). "
        }
        
        let publicationAttributedString = NSAttributedString(string: publicationText, attributes: italicAttributes)
        
        var retrievedString = ""
        if let accessDate = newsCitation.accessDateString {
            retrievedString = String.localizedStringWithFormat(CommonStrings.newNewsReferenceRetrievedDate, accessDate)
        }
        
        let retrievedDateAttributedString = NSAttributedString(string: "\(retrievedString) ", attributes: attributes)
        
        let finalMutableAttributedString = NSMutableAttributedString(string: "")
        finalMutableAttributedString.append(descriptionStartAttributedString)
        if let titleAttributedString = titleAttributedString {
            finalMutableAttributedString.append(titleAttributedString)
        }
        finalMutableAttributedString.append(publicationAttributedString)
        finalMutableAttributedString.append(retrievedDateAttributedString)
        
        return finalMutableAttributedString.copy() as? NSAttributedString
        
    }
    
    private func descriptionForBookCitation(_ bookCitation: SignificantEvents.Citation.Book, traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString? {
        
        let font = UIFont.wmf_font(Self.changeDetailDescriptionTextStyle, compatibleWithTraitCollection: traitCollection)
        let italicFont = UIFont.wmf_font(Self.changeDetailDescriptionTextStyleItalic, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        let italicAttributes = [NSAttributedString.Key.font: italicFont,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        
        let titleAttributedString = NSAttributedString(string: "\(bookCitation.title) ", attributes: italicAttributes)
        
        var descriptionStart = ""
        if let firstName = bookCitation.firstName {
            if let lastName = bookCitation.lastName {
                descriptionStart += "\(lastName), \(firstName)"
            }
        } else {
            if let lastName = bookCitation.lastName {
                descriptionStart += "\(lastName)"
            }
        }
         
        if let yearOfPub = bookCitation.yearPublished {
            descriptionStart += " (\(yearOfPub)). "
        } else {
            descriptionStart += ". "
        }
        
        let descriptionStartAttributedString = NSAttributedString(string: descriptionStart, attributes: attributes)
        
        var descriptionMiddle = ""
        if let locationPublished = bookCitation.locationPublished {
            if let publisher = bookCitation.publisher {
                descriptionMiddle += "\(locationPublished): \(publisher). "
            } else {
                descriptionMiddle += "\(locationPublished). "
            }
        } else {
            if let publisher = bookCitation.publisher {
                descriptionMiddle += "\(publisher). "
            }
        }
        
        if let pagesCited = bookCitation.pagesCited {
            descriptionMiddle += "pp. \(pagesCited) "
        }
        
        let descriptionMiddleAttributedString = NSAttributedString(string: descriptionMiddle, attributes: attributes)
        
        var isbnAttributedString: NSAttributedString?
        if let isbn = bookCitation.isbn {
            let isbnPrefix = "ISBN: "
            let mutableAttributedString = NSMutableAttributedString(string: "\(isbnPrefix + isbn)", attributes: attributes)
            let isbnTitle = "Special:BookSources"
            let isbnURL = Configuration.current.articleURLForHost(Configuration.Domain.englishWikipedia, languageVariantCode: nil, appending: [isbnTitle, isbn])
            let range = NSRange(location: 0, length: isbnPrefix.count + isbn.count)
            if let isbnURL = isbnURL {
                mutableAttributedString.addAttributes([NSAttributedString.Key.link : isbnURL,
                                             NSAttributedString.Key.foregroundColor: theme.colors.link], range: range)
            } else {
                mutableAttributedString.addAttributes(attributes, range: range)
            }
            
            isbnAttributedString = mutableAttributedString.copy() as? NSAttributedString
        }
        
        let finalMutableAttributedString = NSMutableAttributedString(string: "")
        finalMutableAttributedString.append(descriptionStartAttributedString)
        finalMutableAttributedString.append(titleAttributedString)
        finalMutableAttributedString.append(descriptionMiddleAttributedString)
        if let isbnAttributedString = isbnAttributedString {
            finalMutableAttributedString.append(isbnAttributedString)
        }
        
        return finalMutableAttributedString.copy() as? NSAttributedString
        
    }

    private func mutableString(from text: String, linkedTo urlString: String?, with textAttributes: [NSAttributedString.Key:Any], linkColor: UIColor) -> NSMutableAttributedString {
        let mutableAttributedString: NSMutableAttributedString
        if let urlString = urlString, let url = URL(string: urlString), let externalLinkIcon = UIImage(named: "mini-external") {
            mutableAttributedString = NSMutableAttributedString(string: text.trimmingCharacters(in: .whitespaces), attributes: textAttributes)
            mutableAttributedString.append(NSAttributedString(string: " "))
            let externalLinkString = NSAttributedString(attachment: NSTextAttachment(image: externalLinkIcon))
            mutableAttributedString.append(externalLinkString)
            mutableAttributedString.append(NSAttributedString(string: " "))
            let range = NSRange(location: 0, length: mutableAttributedString.length)
            mutableAttributedString.addAttributes([NSAttributedString.Key.link : url,
                                             NSAttributedString.Key.foregroundColor: linkColor], range: range)
        } else {
            mutableAttributedString = NSMutableAttributedString(string: text, attributes: textAttributes)
            let range = NSRange(location: 0, length: text.count)
            mutableAttributedString.addAttributes(textAttributes, range: range)
        }
        return mutableAttributedString
    }

    private func getTimestampString() -> String? {
        switch typedEvent {
        case .newTalkPageTopic(let newTalkPageTopic):
            return newTalkPageTopic.timestampString
        case .large(let largeChange):
            return largeChange.timestampString
        case .vandalismRevert(let vandalismRevert):
            return vandalismRevert.timestampString
        case .small:
            return nil
        }
    }
    
    //Only used in the html portion of the feature
    func fullyRelativeTimestampForDisplay() -> String? {
        
        guard let timestampString = getTimestampString() else {
            return nil
        }
        
        return ArticleAsLivingDocViewModel.displayTimestamp(timestampString: timestampString, fullyRelative: true)
    }
    
    func timestampForDisplay() -> String? {
        if let displayTimestamp = displayTimestamp {
            return displayTimestamp
        } else if let timestampString = getTimestampString() {
            self.displayTimestamp = ArticleAsLivingDocViewModel.eventDisplayTimestamp(timestampString: timestampString)
        }

        return displayTimestamp
    }
    
    private func userNameAndEditCount() -> (userName: String, editCount: UInt?)? {
        let userName: String
        let editCount: UInt?
        switch typedEvent {
        case .newTalkPageTopic(let newTalkPageTopic):
            userName = newTalkPageTopic.user
            editCount = newTalkPageTopic.userEditCount
        case .large(let largeChange):
            userName = largeChange.user
            editCount = largeChange.userEditCount
        case .vandalismRevert(let vandalismRevert):
            userName = vandalismRevert.user
            editCount = vandalismRevert.userEditCount
        case .small:
            return nil
        }
        
        return (userName: userName, editCount: editCount)
    }
    
    static var botIconName: String {
        return "article-as-living-doc-svg-bot"
    }

    static var anonymousIconName: String = "article-as-living-doc-svg-anon"
    
    private func userInfoHtmlSnippet() -> String? {
        guard let userNameAndEditCount = self.userNameAndEditCount() else {
            assertionFailure("Shouldn't reach this point")
            return nil
        }
        let userName = userNameAndEditCount.userName
        let editCount = userNameAndEditCount.editCount
        
        if let editCount = editCount,
           userType != .anonymous {
            let formattedEditCount = NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: editCount)).localizedLowercase
            let userInfo = String.localizedStringWithFormat(CommonStrings.revisionUserInfo, userName, formattedEditCount)
            
            let rangeOfUserName = (userInfo as NSString).range(of: userName)
            let rangeValid = rangeOfUserName.location != NSNotFound && rangeOfUserName.location + rangeOfUserName.length <= userInfo.count
            let userNameHrefString = "#significant-events-username-\(userName)"
            if rangeValid {
                
                let mutableUserInfo = NSMutableString(string: userInfo)
                
                let linkStartInsert: String
                if userType == .bot {
                    linkStartInsert = "<a href='\(userNameHrefString)'><img src='\(Self.botIconName)' style='margin: 0em .2em .35em .1em; width: 1em' />"
                } else {
                    linkStartInsert = "<a href='\(userNameHrefString)'>"
                }
                let linkEndInsert = "</a>"
                mutableUserInfo.insert(linkStartInsert, at: rangeOfUserName.location)
                mutableUserInfo.insert(linkEndInsert, at: rangeOfUserName.location + rangeOfUserName.length + linkStartInsert.count)
                
                if let userInfoResult = mutableUserInfo.copy() as? NSString {
                    return (userInfoResult as String)
                } else {
                    assertionFailure("This shouldn't happen")
                    return nil
                }
            }
        } else {
            return "<img src='\(Self.anonymousIconName)' style='margin: 0em .2em .35em .1em; width: 1em' />\(CommonStrings.revisionUserInfoAnonymous)"

        }
        
        return nil
    }
    
    func userInfoForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString? {
        if let userInfo = userInfo {
            return userInfo
        }
        
        guard let userNameAndEditCount = self.userNameAndEditCount() else {
            assertionFailure("Shouldn't reach this point")
            return nil
        }
        
        let userName = userNameAndEditCount.userName
        let maybeEditCount = userNameAndEditCount.editCount
        
        guard let editCount = maybeEditCount,
               userType != .anonymous else {
            let anonymousUserInfo = CommonStrings.revisionUserInfoAnonymous
            
            let font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
            let attributes = [NSAttributedString.Key.font: font,
                              NSAttributedString.Key.foregroundColor: theme.colors.secondaryText]
            let mutableAttributedString = NSMutableAttributedString(string: anonymousUserInfo, attributes: attributes)
            addIcon(to: mutableAttributedString, at: 0, for: userType)
            // Need this next line to appropriately color the icon
            mutableAttributedString.addAttributes(attributes, range: NSRange(location: 0, length: 2))
            guard let attributedString = mutableAttributedString.copy() as? NSAttributedString else {
                return nil
            }

            self.userInfo = attributedString
            return attributedString
        }

        let formattedEditCount = NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: editCount)).localizedLowercase
        let userInfo = String.localizedStringWithFormat( CommonStrings.revisionUserInfo, userName, formattedEditCount)
        
        let font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor: theme.colors.secondaryText]
        let rangeOfUserName = (userInfo as NSString).range(of: userName)
        let rangeValid = rangeOfUserName.location != NSNotFound && rangeOfUserName.location + rangeOfUserName.length <= userInfo.count
        
        guard let title = "User:\(userName)".percentEncodedPageTitleForPathComponents,
              let userNameURL = Configuration.current.articleURLForHost(Configuration.Domain.englishWikipedia, languageVariantCode: nil, appending: [title]),
              rangeValid else {
            let attributedString = NSAttributedString(string: userInfo, attributes: attributes)
            self.userInfo = attributedString
            return attributedString
        }

        let mutableAttributedString = NSMutableAttributedString(string: userInfo, attributes: attributes)
        mutableAttributedString.addAttribute(NSAttributedString.Key.link, value: userNameURL as NSURL, range: rangeOfUserName)
        mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: theme.colors.link, range: rangeOfUserName)

        addIcon(to: mutableAttributedString, at: rangeOfUserName.location, for: userType)

        guard let attributedString = mutableAttributedString.copy() as? NSAttributedString else {
            return nil
        }
        
        self.userInfo = attributedString
        return attributedString
    }

    func addIcon(to mutableAttributedString: NSMutableAttributedString, at location: Int, for userType: UserType) {
        if userType == .bot || userType == .anonymous {
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(named: (userType == .bot ? Self.botIconName : Self.anonymousIconName))
            let imageString = NSAttributedString(attachment: imageAttachment)
            mutableAttributedString.insert(imageString, at: location)
            mutableAttributedString.insert(NSAttributedString(string: " "), at: location + imageString.length)
        }
    }
    
}
