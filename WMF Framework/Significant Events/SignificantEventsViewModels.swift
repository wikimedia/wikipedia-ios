
import Foundation

public struct SignificantEventsViewModel {
    public let nextRvStartId: UInt?
    public let sha: String?
    public let events: [TimelineEventViewModel]
    public let articleInsertHtmlSnippets: [String]
    public let summaryText: String?
    
    public init(nextRvStartId: UInt?, sha: String?, events: [TimelineEventViewModel], summaryText: String?, articleInsertHtmlSnippets: [String]) {
        self.nextRvStartId = nextRvStartId
        self.sha = sha
        self.events = events
        self.summaryText = summaryText
        self.articleInsertHtmlSnippets = articleInsertHtmlSnippets
    }
    
    public init?(significantEvents: SignificantEvents, lastTimestamp: Date? = nil) {
        
        let isFirstPage = lastTimestamp == nil
        
        self.nextRvStartId = significantEvents.nextRvStartId
        self.sha = significantEvents.sha
        
        //initialize summary text
        var summaryText: String? = nil
        if let dateFormatter = DateFormatter.wmf_iso8601(),
           let earliestDate = dateFormatter.date(from: significantEvents.summary.earliestTimestampString) {
            
            let currentDate = Date()
            let calendar = NSCalendar.current
            let unitFlags:Set<Calendar.Component> = [.day]
            let components = calendar.dateComponents(unitFlags, from: earliestDate, to: currentDate)
            if let numberOfDays = components.day {
                summaryText = String.localizedStringWithFormat(CommonStrings.significantEventsSummaryTitle,
                                                                       significantEvents.summary.numChanges,
                                                                       significantEvents.summary.numUsers,
                                                                       numberOfDays)
            }
        }
        self.summaryText = summaryText
        
        //initialize events and articleHTMLSnippets
        var eventViewModels: [TimelineEventViewModel] = []
        var previousTimestamp = lastTimestamp
        var articleInsertHtmlSnippets: [String] = []
        
        let htmlSnippetCountMax = 3
        for originalEvent in significantEvents.typedEvents {
            
            //first determine if we need to inject a section header cell
            //(we are bypassing using actual sections for simplicity)
            if let isoDateFormatter = DateFormatter.wmf_iso8601() {
                var currentTimestamp: Date?
                
                switch originalEvent {
                case .largeChange(let largeChange):
                    currentTimestamp = isoDateFormatter.date(from: largeChange.timestampString)
                case .newTalkPageTopic(let newTalkPageTopic):
                    currentTimestamp = isoDateFormatter.date(from: newTalkPageTopic.timestampString)
                case .vandalismRevert(let vandalismRevert):
                    currentTimestamp = isoDateFormatter.date(from: vandalismRevert.timestampString)
                default:
                    break
                }
                
                if let currentTimestamp = currentTimestamp {
                    if let sectionHeader = SectionHeaderViewModel(timestamp: currentTimestamp, previousTimestamp: previousTimestamp) {
                        //eventViewModels.append(.sectionHeader(sectionHeader))
                    }
                    
                    previousTimestamp = currentTimestamp
                }
            }
            
            
            if let smallEventViewModel = SmallEventViewModel(timelineEvent: originalEvent) {
                //eventViewModels.append(.smallEvent(smallEventViewModel))
            } else if let largeEventViewModel = LargeEventViewModel(timelineEvent: originalEvent) {
                if let htmlSnippet = largeEventViewModel.articleInsertHtmlSnippet(isFirst: articleInsertHtmlSnippets.count == 0),
                   articleInsertHtmlSnippets.count < htmlSnippetCountMax,
                   isFirstPage {
                    articleInsertHtmlSnippets.append(htmlSnippet)
                    
                }
                
                eventViewModels.append(.largeEvent(largeEventViewModel))
                
            }
        }
        
        self.events = eventViewModels
        self.articleInsertHtmlSnippets = articleInsertHtmlSnippets
    }
}

public enum TimelineEventViewModel {
    case smallEvent(SmallEventViewModel)
    case largeEvent(LargeEventViewModel)
    case sectionHeader(SectionHeaderViewModel)
}

public class SectionHeaderViewModel {
    public let title: String
    public let subtitle: String
    init?(timestamp: Date, previousTimestamp: Date?) {
        
        //do not instantiate if on same day as previous timestamp
        if let previousTimestamp = previousTimestamp {
            let calendar = NSCalendar.current
            let unitFlags:Set<Calendar.Component> = [.day]
            let components = calendar.dateComponents(unitFlags, from: previousTimestamp, to: timestamp)
            if let numberOfDays = components.day {
                if numberOfDays == 0 {
                    return nil
                }
            }
        }
        
        if let dayMonthNumberYearDateFormatter = DateFormatter.wmf_monthNameDayOfMonthNumberYear() {
            
            self.title = (timestamp as NSDate).wmf_localizedRelativeDateStringFromLocalDate(toLocalDate: Date())
            self.subtitle = dayMonthNumberYearDateFormatter.string(from: timestamp)
        } else {
            return nil
        }
    }
}

public class SmallEventViewModel {
    
    private(set) var eventDescription: NSAttributedString?
    private var lastTraitCollection: UITraitCollection?
    private let smallChange: SignificantEvents.SmallChange
    
    init?(timelineEvent: SignificantEvents.TimelineEvent) {
        
        switch timelineEvent {
        case .smallChange(let smallChange):
            self.smallChange = smallChange
        default:
            return nil
        }
    }
    
    public func eventDescriptionForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
        if let lastTraitCollection = lastTraitCollection,
           let eventDescription = eventDescription {
            if lastTraitCollection == traitCollection {
                return eventDescription
            }
        }
        
        let font = UIFont.wmf_font(.italicSubheadline, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor: theme.colors.primaryText]
        
        let localizedString = String.localizedStringWithFormat(
            CommonStrings.smallChangeDescription,
            smallChange.count)
        
        let eventDescription = NSAttributedString(string: localizedString, attributes: attributes)
        
        self.lastTraitCollection = traitCollection
        self.eventDescription = eventDescription
        return eventDescription
    }
}

public class LargeEventViewModel {
    
    public enum ChangeDetail {
        case snippet(Snippet) //use for a basic horizontally scrolling snippet cell (will contain talk page topic snippets, added text snippets, article description updated snippets)
        case reference(Reference)
    }
    
    public struct Snippet {
        public let displayText: NSAttributedString
    }
    
    public struct Reference {
        let type: String
        let description: NSAttributedString
        let accessDateYearDisplay: String?
    }
    
    enum UserType {
        case standard
        case anonymous
        case bot
    }
    
    enum ButtonsToDisplay {
        case thankAndViewChanges(userId: UInt, revisionId: UInt)
        case viewDiscussion(sectionName: String)
    }
    
    private let timelineEvent: SignificantEvents.TimelineEvent
    private(set) var eventDescription: NSAttributedString?
    private(set) var changeDetails: [ChangeDetail]?
    private(set) var displayTimestamp: String?
    private(set) var userInfo: NSAttributedString?
    let userId: UInt
    let userType: UserType
    let buttonsToDisplay: ButtonsToDisplay?
    private var lastTraitCollection: UITraitCollection?
    
    init?(timelineEvent: SignificantEvents.TimelineEvent) {
        
        let userGroups: [String]
        switch timelineEvent {
        case .newTalkPageTopic(let newTalkPageTopic):
            self.userId = newTalkPageTopic.userId
            userGroups = newTalkPageTopic.userGroups
            self.buttonsToDisplay = .viewDiscussion(sectionName: newTalkPageTopic.section)
        case .largeChange(let largeChange):
            self.userId = largeChange.userId
            userGroups = largeChange.userGroups
            self.buttonsToDisplay = .thankAndViewChanges(userId: largeChange.userId, revisionId: largeChange.revId)
        case .vandalismRevert(let vandalismRevert):
            self.userId = vandalismRevert.userId
            userGroups = vandalismRevert.userGroups
            self.buttonsToDisplay = .thankAndViewChanges(userId: vandalismRevert.userId, revisionId: vandalismRevert.revId)
        case .smallChange:
            return nil
        }
        
        if userGroups.contains("bot") {
            userType = .bot
        } else if self.userId == 0 {
            userType = .anonymous
        } else {
            userType = .standard
        }
        
        self.timelineEvent = timelineEvent
    }
    
    public convenience init?(forPrototypeText prototypeText: String) {
        let originalUntypedEvent = SignificantEvents.UntypedTimelineEvent(forPrototypeText: prototypeText)
        guard let originalLargeChange = SignificantEvents.LargeChange(untypedEvent: originalUntypedEvent) else {
            return nil
        }
        let originalTimelineEvent = SignificantEvents.TimelineEvent.largeChange(originalLargeChange)
        self.init(timelineEvent: originalTimelineEvent)
    }
    
    public func firstSnippetFromPrototypeModel(traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString? {
        let changeDetails = changeDetailsForTraitCollection(traitCollection, theme: theme)
        if changeDetails.count > 0 {
            let firstChangeDetail = changeDetails[0]
            switch firstChangeDetail {
            case .snippet(let snippet):
                return snippet.displayText
            default:
                return nil
            }
        }
        
        return nil
    }
    
    public func articleInsertHtmlSnippet(isFirst: Bool = false) -> String? {
        guard let timestampForDisplay = self.timestampForDisplay(),
              let eventDescription = eventDescriptionHtmlSnippet(),
              let userInfo = userInfoHtmlSnippet() else {
            return nil
        }
        
        let liElementIdName = isFirst ? "significant-changes-first-list" : "significant-changes-list"
        
        return "<li id='\(liElementIdName)'><p class='significant-changes-timestamp'>\(timestampForDisplay)</p><p class='significant-changes-description'>\(eventDescription)</p><p class='significant-changes-userInfo'>\(userInfo)</p></li>"
    }
    
    private func eventDescriptionHtmlSnippet() -> String? {
        
        let sections = sectionsSet()
        let sectionsHtml = localizedSectionHtmlSnippet(sectionsSet: sections)
        
        let eventDescription: String
        switch timelineEvent {
        case .newTalkPageTopic:
            eventDescription = CommonStrings.newTalkTopicDescription
        case .vandalismRevert:
            let event = CommonStrings.vandalismRevertDescription
            if let sectionsHtml = sectionsHtml {
                eventDescription = event + sectionsHtml
            } else {
                eventDescription = event
            }
        case .largeChange(let largeChange):
            
            guard let mergedDescription = mergedDescriptionForTypedChanges(largeChange.typedChanges) else {
                assertionFailure("This should not happen")
                return nil
            }
            
            if let sectionsHtml = sectionsHtml {
                eventDescription = mergedDescription + sectionsHtml
            } else {
                eventDescription = mergedDescription
            }
            
        case .smallChange:
            assertionFailure("This should not happen")
            return nil
        }
        
        return eventDescription
    }
    
    private func mergedDescriptionForTypedChanges(_ changes: [SignificantEvents.Change]) -> String? {
        let individualDescriptions = self.individualDescriptionsForTypedChanges(changes)
        let sortedDescriptions = individualDescriptions.sorted { $0.priority < $1.priority }
        
        switch sortedDescriptions.count {
        case 0:
            assertionFailure("This should not happen")
            return nil
        case 1:
            let description = sortedDescriptions[0].text
            return description
        case 2:
            let firstDescription = sortedDescriptions[0].text
            let secondDescription = sortedDescriptions[1].text
            let mergedDescription = String.localizedStringWithFormat(CommonStrings.twoDescriptionsFormat, firstDescription, secondDescription)
            return mergedDescription
        default:
            //Note: This will not work properly in translations but for now this is works for an English-only feature
            let finalDelimiter = CommonStrings.finalDelimiter
            let midDelimiter = CommonStrings.midDelimiter
                
            var finalDescription: String = ""
            for (index, description) in sortedDescriptions.enumerated() {
                
                let delimiter = index == sortedDescriptions.count - 2 ? finalDelimiter : midDelimiter
                finalDescription += description.text
                if index < sortedDescriptions.count - 1 {
                    finalDescription += delimiter
                }
            }
            
            return finalDescription
        }
    }
    
    public func eventDescriptionForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
        
        let sections = sectionsSet()
        let sectionsAttributedString = localizedSectionAttributedString(sectionsSet: sections, traitCollection: traitCollection, theme: theme)
        
        if let lastTraitCollection = lastTraitCollection,
           let eventDescription = eventDescription {
            if lastTraitCollection == traitCollection {
                return eventDescription
            }
        }
        
        let font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor: theme.colors.primaryText]
        
        let eventDescriptionMutableAttributedString: NSMutableAttributedString = NSMutableAttributedString(string: "")
        switch timelineEvent {
        case .newTalkPageTopic:
            let localizedString = CommonStrings.newTalkTopicDescription
            let eventAttributedString = NSAttributedString(string: localizedString, attributes: attributes)
            eventDescriptionMutableAttributedString.append(eventAttributedString)
            
        case .vandalismRevert:
            
            let event = CommonStrings.vandalismRevertDescription
            
            let eventAttributedString = NSAttributedString(string: event, attributes: attributes)
            eventDescriptionMutableAttributedString.append(eventAttributedString)
        
        case .largeChange(let largeChange):
            
            guard let mergedDescription = mergedDescriptionForTypedChanges(largeChange.typedChanges) else {
                assertionFailure("This should not happen")
                break
            }
            
            let mergedDescriptionAttributedString = NSAttributedString(string: mergedDescription, attributes: attributes)
            eventDescriptionMutableAttributedString.append(mergedDescriptionAttributedString)
            
        case .smallChange:
            assertionFailure("Unexpected timeline event type")
            break
        }
        
        if let sectionsAttributedString = sectionsAttributedString {
            eventDescriptionMutableAttributedString.append(sectionsAttributedString)
        }
        
        guard let finalEventAttributedString = eventDescriptionMutableAttributedString.copy() as? NSAttributedString else {
            assertionFailure("This should not happen")
            let empty = NSAttributedString(string: "")
            eventDescription = empty
            self.lastTraitCollection = traitCollection
            return empty
        }
        
        eventDescription = finalEventAttributedString
        self.lastTraitCollection = traitCollection
        return finalEventAttributedString
    }
    
    struct IndividualDescription {
        let priority: Int //used for sorting
        let text: String
    }
    
    private func individualDescriptionsForTypedChanges(_ typedChanges: [SignificantEvents.Change]) -> [IndividualDescription] {
        
        var descriptions: [IndividualDescription] = []
        var numReferences = 0
        for typedChange in typedChanges {
            switch typedChange {
            case .addedText(let addedText):
                let description = String.localizedStringWithFormat(CommonStrings.addedTextDescription, addedText.characterCount)
                descriptions.append(IndividualDescription(priority: 1, text: description))
            case .deletedText(let deletedText):
                let description = String.localizedStringWithFormat(CommonStrings.deletedTextDescription, deletedText.characterCount)
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
        switch timelineEvent {
        case .newTalkPageTopic:
            set = Set<String>()
        case .vandalismRevert(let vandalismRevert):
            set = Set(vandalismRevert.sections)
        case .largeChange(let largeChange):
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
        case .smallChange:
            assertionFailure("This shouldn't happen")
            set = Set<String>()
        }
        
        return set
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

        for range in ranges {
            let italicStart = "<i>"
            let italicEnd = "</i>"
            mutableLocalizedString.insert(italicStart, at: range.location)
            mutableLocalizedString.insert(italicEnd, at: range.location + italicStart.count + range.length)
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
    
    public func changeDetailsForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> [ChangeDetail] {
        if let lastTraitCollection = lastTraitCollection,
           let changeDetails = changeDetails {
            if lastTraitCollection == traitCollection {
                return changeDetails
            }
        }
        
        var changeDetails: [ChangeDetail] = []
        
        switch timelineEvent {
        case .newTalkPageTopic(let newTalkPageTopic):
            let attributedString = newTalkPageTopic.snippet.byAttributingHTML(with: .subheadline, boldWeight: .regular, matching: traitCollection, color: theme.colors.primaryText, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true)
            let changeDetail = ChangeDetail.snippet(Snippet(displayText: attributedString))
            changeDetails.append(changeDetail)
        case .largeChange(let largeChange):
            for typedChange in largeChange.typedChanges {
                switch typedChange {
                case .addedText(let addedText):
                    //TODO: Add highlighting here. For snippetType 1, add a highlighting attribute across the whole string. Otherwise, seek out highlight-add span ranges and add those attributes
                    let attributedString = addedText.snippet.byAttributingHTML(with: .subheadline, boldWeight: .regular, matching: traitCollection, color: theme.colors.primaryText, handlingLinks: true, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true)
                    let changeDetail = ChangeDetail.snippet(Snippet(displayText: attributedString))
                    changeDetails.append(changeDetail)
                case .deletedText:
                    continue;
                case .newTemplate(let newTemplate):
                    for template in newTemplate.typedTemplates {
                        let typeText = referenceTypeForTemplate(template, traitCollection: traitCollection, theme: theme)
                        let accessYear = accessDateYearForTemplate(template, traitCollection: traitCollection, theme: theme)
                        switch template {
                        case .articleDescription(let articleDescription):
                            let font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
                            let attributes = [NSAttributedString.Key.font: font,
                                              NSAttributedString.Key.foregroundColor:
                                                theme.colors.primaryText]
                            let attributedString = NSAttributedString(string: articleDescription.text, attributes: attributes)
                            let changeDetail = ChangeDetail.snippet(Snippet(displayText: attributedString))
                            changeDetails.append(changeDetail)
                        case .bookCitation(let bookCitation):
                            
                            let bookCitationDescription = descriptionForBookCitation(bookCitation, traitCollection: traitCollection, theme: theme)
                            let reference = Reference(type: typeText, description: bookCitationDescription, accessDateYearDisplay: accessYear)
                            let changeDetail = ChangeDetail.reference(reference)
                            changeDetails.append(changeDetail)
                        case .journalCitation(let journalCitation):
                            let citationDescription = descriptionForJournalCitation(journalCitation, traitCollection: traitCollection, theme: theme)
                            let reference = Reference(type: typeText, description: citationDescription, accessDateYearDisplay: accessYear)
                            let changeDetail = ChangeDetail.reference(reference)
                            changeDetails.append(changeDetail)
                        case .newsCitation(let newsCitation):
                            let citationDescription = descriptionForNewsCitation(newsCitation, traitCollection: traitCollection, theme: theme)
                            let reference = Reference(type: typeText, description: citationDescription, accessDateYearDisplay: accessYear)
                            let changeDetail = ChangeDetail.reference(reference)
                            changeDetails.append(changeDetail)
                        case .websiteCitation(let websiteCitation):
                            let citationDescription = descriptionForWebsiteCitation(websiteCitation, traitCollection: traitCollection, theme: theme)
                            let reference = Reference(type: typeText, description: citationDescription, accessDateYearDisplay: accessYear)
                            let changeDetail = ChangeDetail.reference(reference)
                            changeDetails.append(changeDetail)
                        }
                    }
                }
            }
        case .vandalismRevert:
            return []
        case .smallChange:
            assertionFailure("This should not happen")
            return []
        }
        
        self.lastTraitCollection = traitCollection
        self.changeDetails = changeDetails
        return changeDetails
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
    
    private func descriptionForJournalCitation(_ journalCitation: SignificantEvents.JournalCitation, traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
        
        let font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        let boldFont = UIFont.wmf_font(.boldFootnote, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        let boldAttributes = [NSAttributedString.Key.font: boldFont,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        
        let titleAttributedString: NSAttributedString
        let titleString = "\"\(journalCitation.title)\""
        let range = NSRange(location: 0, length: titleString.count)
        let mutableAttributedString = NSMutableAttributedString(string: titleString)
        if let urlString = journalCitation.urlString,
           let url = URL(string: urlString) {
            
                mutableAttributedString.addAttributes([NSAttributedString.Key.link : url,
                                             NSAttributedString.Key.foregroundColor: theme.colors.link], range: range)
        } else {
            mutableAttributedString.addAttributes(attributes, range: range)
        }
        
        titleAttributedString = mutableAttributedString.copy() as? NSAttributedString ?? NSAttributedString(string: "")
        
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
            descriptionStart += "(\(sourceDate)). "
        } else {
            descriptionStart += ". "
        }
        
        let descriptionStartAttributedString = NSAttributedString(string: descriptionStart, attributes: attributes)
        
        var volumeString = ""
        if let volumeNumber = journalCitation.volumeNumber {
            volumeString = String.localizedStringWithFormat(CommonStrings.newJournalReferenceVolume, volumeNumber)
        }
        let volumeAttributedString = NSAttributedString(string: volumeString, attributes: boldAttributes)
        
        var descriptionEnd = ""
        if let database = journalCitation.database {
            let viaDatabaseString = String.localizedStringWithFormat(CommonStrings.newJournalReferenceDatabase, database)
            if let pages = journalCitation.pages {
                descriptionEnd += "\(pages) - \(viaDatabaseString). "
            } else {
                descriptionEnd += "\(viaDatabaseString). "
            }
        } else {
            if let pages = journalCitation.pages {
                descriptionEnd += "\(pages)."
            }
        }
        
        let descriptionEndAttributedString = NSAttributedString(string: descriptionEnd, attributes: attributes)

        
        let finalMutableAttributedString = NSMutableAttributedString(string: "")
        finalMutableAttributedString.append(descriptionStartAttributedString)
        finalMutableAttributedString.append(titleAttributedString)
        finalMutableAttributedString.append(volumeAttributedString)
        finalMutableAttributedString.append(descriptionEndAttributedString)
        
        return finalMutableAttributedString.copy() as? NSAttributedString ?? NSAttributedString(string: "")
        
    }
    
    private func descriptionForWebsiteCitation(_ websiteCitation:SignificantEvents.WebsiteCitation, traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
        let font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        let italicFont = UIFont.wmf_font(.italicFootnote, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        let italicAttributes = [NSAttributedString.Key.font: italicFont,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        
        let titleAttributedString: NSAttributedString
        let titleString = "\"\(websiteCitation.title)\""
        let range = NSRange(location: 0, length: titleString.count)
        let mutableAttributedString = NSMutableAttributedString(string: titleString)
        let urlString = websiteCitation.urlString
        if let url = URL(string: urlString) {
            
                mutableAttributedString.addAttributes([NSAttributedString.Key.link : url,
                                             NSAttributedString.Key.foregroundColor: theme.colors.link], range: range)
        } else {
            mutableAttributedString.addAttributes(attributes, range: range)
        }
        
        titleAttributedString = mutableAttributedString.copy() as? NSAttributedString ?? NSAttributedString(string: "")
        
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
        finalMutableAttributedString.append(titleAttributedString)
        finalMutableAttributedString.append(publisherAttributedString)
        finalMutableAttributedString.append(accessDateAttributedString)
        
        if let archiveDateString = websiteCitation.archiveDateString,
           let archiveUrlString = websiteCitation.archiveDotOrgUrlString,
           let archiveUrl = URL(string: archiveUrlString) {
            let archiveLinkText = CommonStrings.newWebsiteReferenceArchiveUrlText
            let range = NSRange(location: 0, length: archiveLinkText.count)
            let archiveLinkMutableAttributedString = NSMutableAttributedString(string: titleString)
            archiveLinkMutableAttributedString.addAttributes([NSAttributedString.Key.link : archiveUrl,
                                         NSAttributedString.Key.foregroundColor: theme.colors.link], range: range)
            
            if let archiveLinkAttributedString = archiveLinkMutableAttributedString.copy() as? NSAttributedString {
                
                let lastText =  String.localizedStringWithFormat(CommonStrings.newWebsiteReferenceArchiveDateText, archiveDateString)
                
                let lastAttributedString = NSAttributedString(string: lastText, attributes: attributes)
                
                finalMutableAttributedString.append(archiveLinkAttributedString)
                finalMutableAttributedString.append(lastAttributedString)
                
            }
            
        }
        
        return finalMutableAttributedString.copy() as? NSAttributedString ?? NSAttributedString(string: "")
    }
    
    private func descriptionForNewsCitation(_ newsCitation: SignificantEvents.NewsCitation, traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
        
        let font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        let italicFont = UIFont.wmf_font(.italicFootnote, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        let italicAttributes = [NSAttributedString.Key.font: italicFont,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        
        let titleAttributedString: NSAttributedString
        let titleString = "\"\(newsCitation.title)\""
        let range = NSRange(location: 0, length: titleString.count)
        let mutableAttributedString = NSMutableAttributedString(string: titleString)
        if let urlString = newsCitation.urlString,
           let url = URL(string: urlString) {
            
                mutableAttributedString.addAttributes([NSAttributedString.Key.link : url,
                                             NSAttributedString.Key.foregroundColor: theme.colors.link], range: range)
        } else {
            mutableAttributedString.addAttributes(attributes, range: range)
        }
        
        titleAttributedString = mutableAttributedString.copy() as? NSAttributedString ?? NSAttributedString(string: "")
        
        var descriptionStart = ""
        if let firstName = newsCitation.firstName {
            if let lastName = newsCitation.lastName {
                descriptionStart += "\(lastName), \(firstName)"
            }
        } else {
            if let lastName = newsCitation.lastName {
                descriptionStart += "\(lastName)"
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
        
        let retrievedDateAttributedString = NSAttributedString(string: retrievedString, attributes: attributes)
        
        let finalMutableAttributedString = NSMutableAttributedString(string: "")
        finalMutableAttributedString.append(descriptionStartAttributedString)
        finalMutableAttributedString.append(titleAttributedString)
        finalMutableAttributedString.append(publicationAttributedString)
        finalMutableAttributedString.append(retrievedDateAttributedString)
        
        return finalMutableAttributedString.copy() as? NSAttributedString ?? NSAttributedString(string: "")
        
    }
    
    private func descriptionForBookCitation(_ bookCitation: SignificantEvents.BookCitation, traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
        
        let font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        let italicFont = UIFont.wmf_font(.italicFootnote, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        let italicAttributes = [NSAttributedString.Key.font: italicFont,
                          NSAttributedString.Key.foregroundColor:
                            theme.colors.primaryText]
        
        let titleAttributedString = NSAttributedString(string: bookCitation.title, attributes: italicAttributes)
        
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
            descriptionStart += "(\(yearOfPub)). "
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
            descriptionMiddle += "pp. \(pagesCited)"
        }
        
        let descriptionMiddleAttributedString = NSAttributedString(string: descriptionMiddle, attributes: attributes)
        
        let isbnAttributedString: NSAttributedString
        if let isbn = bookCitation.isbn {
            let mutableAttributedString = NSMutableAttributedString(string: isbn)
            let isbnTitle = "Special:BookSources"
            let isbnURL = Configuration.current.articleURLForHost(Configuration.Domain.englishWikipedia, appending: [isbnTitle, isbn]).url
            let range = NSRange(location: 0, length: isbn.count)
            if let isbnURL = isbnURL {
                mutableAttributedString.addAttributes([NSAttributedString.Key.link : isbnURL,
                                             NSAttributedString.Key.foregroundColor: theme.colors.link], range: range)
            } else {
                mutableAttributedString.addAttributes(attributes, range: range)
            }
            
            isbnAttributedString = mutableAttributedString.copy() as? NSAttributedString ?? NSAttributedString(string: "")
        } else {
            isbnAttributedString = NSAttributedString(string: "")
        }
        
        let finalMutableAttributedString = NSMutableAttributedString(string: "")
        finalMutableAttributedString.append(descriptionStartAttributedString)
        finalMutableAttributedString.append(titleAttributedString)
        finalMutableAttributedString.append(descriptionMiddleAttributedString)
        finalMutableAttributedString.append(isbnAttributedString)
        
        return finalMutableAttributedString.copy() as? NSAttributedString ?? NSAttributedString(string: "")
        
    }
    
    public func timestampForDisplay() -> String? {
        if let displayTimestamp = displayTimestamp {
            return displayTimestamp
        }
        
        let timestampString: String
        switch timelineEvent {
        case .newTalkPageTopic(let newTalkPageTopic):
            timestampString = newTalkPageTopic.timestampString
        case .largeChange(let largeChange):
            timestampString = largeChange.timestampString
        case .vandalismRevert(let vandalismRevert):
            timestampString = vandalismRevert.timestampString
        case .smallChange:
            assertionFailure("Shouldn't reach this point")
            return nil
        }
        
        var displayTimestamp = timestampString
        if let isoDateFormatter = DateFormatter.wmf_iso8601(),
           let timeDateFormatter = DateFormatter.wmf_24hshortTimeWithUTCTimeZone(),
           let date = isoDateFormatter.date(from: timestampString) {
            let calendar = NSCalendar.current
            let unitFlags:Set<Calendar.Component> = [.day]
            let components = calendar.dateComponents(unitFlags, from: date, to: Date())
            if let numberOfDays = components.day {
                switch numberOfDays {
                case 0:
                    let relativeTime = (date as NSDate).wmf_fullyLocalizedRelativeDateStringFromLocalDateToNow()
                    displayTimestamp = relativeTime
                default:
                    let shortTime = timeDateFormatter.string(from: date)
                    displayTimestamp = shortTime
                }
            }
        }
        
        self.displayTimestamp = displayTimestamp
        return displayTimestamp
    }
    
    private func userNameAndEditCount() -> (userName: String, editCount: UInt)? {
        let userName: String
        let editCount: UInt
        switch timelineEvent {
        case .newTalkPageTopic(let newTalkPageTopic):
            userName = newTalkPageTopic.user
            editCount = newTalkPageTopic.userEditCount
        case .largeChange(let largeChange):
            userName = largeChange.user
            editCount = largeChange.userEditCount
        case .vandalismRevert(let vandalismRevert):
            userName = vandalismRevert.user
            editCount = vandalismRevert.userEditCount
        case .smallChange:
            return nil
        }
        
        return (userName: userName, editCount: editCount)
    }
    
    private func userInfoHtmlSnippet() -> String? {
        guard let userNameAndEditCount = self.userNameAndEditCount() else {
            assertionFailure("Shouldn't reach this point")
            return nil
        }
        let userName = userNameAndEditCount.userName
        let editCount = userNameAndEditCount.editCount
        
        if userType != .anonymous {
            let userInfo = String.localizedStringWithFormat( CommonStrings.revisionUserInfo, userName, String(editCount))
            
            let rangeOfUserName = (userInfo as NSString).range(of: userName)
            let rangeValid = rangeOfUserName.location != NSNotFound && rangeOfUserName.location + rangeOfUserName.length <= userInfo.count
            let userNameHrefString = "./User:\(userName)"
            if rangeValid {
                
                let mutableUserInfo = NSMutableString(string: userInfo)
                
                let linkStartInsert = "<a href='\(userNameHrefString)'>"
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
            let anonymousUserInfo = String.localizedStringWithFormat(CommonStrings.revisionUserInfoAnonymous, userName)
            return anonymousUserInfo
        }
        
        return nil
    }
    
    public func userInfoForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
        if let lastTraitCollection = lastTraitCollection,
           let userInfo = userInfo {
            if lastTraitCollection == traitCollection {
                return userInfo
            }
        }
        
        guard let userNameAndEditCount = self.userNameAndEditCount() else {
            assertionFailure("Shouldn't reach this point")
            return NSAttributedString(string: "")
        }
        let userName = userNameAndEditCount.userName
        let editCount = userNameAndEditCount.editCount
        
        var attributedString: NSAttributedString
        if userType != .anonymous {
            let userInfo = String.localizedStringWithFormat( CommonStrings.revisionUserInfo, userName, String(editCount))
            
            let font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
            let attributes = [NSAttributedString.Key.font: font,
                              NSAttributedString.Key.foregroundColor: theme.colors.secondaryText]
            let rangeOfUserName = (userInfo as NSString).range(of: userName)
            let rangeValid = rangeOfUserName.location != NSNotFound && rangeOfUserName.location + rangeOfUserName.length <= userInfo.count
            let title = "User:\(userName)"
            let userNameURL = Configuration.current.articleURLForHost(Configuration.Domain.englishWikipedia, appending: [title]).url
            if let userNameURL = userNameURL,
               rangeValid {
                let mutableAttributedString = NSMutableAttributedString(string: userInfo, attributes: attributes)
                mutableAttributedString.addAttribute(NSAttributedString.Key.link, value: userNameURL as NSURL, range: rangeOfUserName)
                mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: theme.colors.link, range: rangeOfUserName)
                
                if let attributedString = mutableAttributedString.copy() as? NSAttributedString {
                    return attributedString
                } else {
                    assertionFailure("This shouldn't happen")
                    attributedString = NSAttributedString(string: "")
                }
            }
            
            attributedString = NSAttributedString(string: userInfo, attributes: attributes)
        } else {
            let anonymousUserInfo = String.localizedStringWithFormat(CommonStrings.revisionUserInfoAnonymous, userName)
            
            let font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
            let attributes = [NSAttributedString.Key.font: font,
                              NSAttributedString.Key.foregroundColor: theme.colors.secondaryText]
            attributedString = NSAttributedString(string: anonymousUserInfo, attributes: attributes)
        }
        
        self.userInfo = attributedString
        self.lastTraitCollection = traitCollection
        return attributedString
    }
}
