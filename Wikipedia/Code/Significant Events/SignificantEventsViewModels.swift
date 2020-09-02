
import Foundation
import WMF
import UIKit

struct SignificantEventsViewModel {
    let nextRvStartId: UInt?
    let sha: String?
    let events: [TimelineEventViewModel]
    let summaryText: String?
    
    init?(significantEvents: SignificantEvents) {
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
                summaryText = String.localizedStringWithFormat(WMFLocalizedString(
                    "significant-events-summary-title",
                    value:"{{PLURAL:%1$d|0=0 changes|%1$d change|%1$d changes}} by {{PLURAL:%2$d|0=0 editors|%2$d editor|%2$d editors}} in {{PLURAL:%3$d|0=0 days|%3$d day|%3$d days}}",
                    comment:"Describes how many small changes are batched together in the significant events timeline view. %1$d is replaced by the number of accumulated changes editors made and %2$d is replaced with relative timeframe date that the edit counting started (e.g. 10 days ago)."),
                                                                       significantEvents.summary.numChanges,
                                                                       significantEvents.summary.numUsers,
                                                                       numberOfDays)
            }
        }
        self.summaryText = summaryText
        
        //initialize events
        var eventViewModels: [TimelineEventViewModel] = []
        for originalEvent in significantEvents.typedEvents {
            if let smallEventViewModel = SmallEventViewModel(timelineEvent: originalEvent) {
                eventViewModels.append(.smallEvent(smallEventViewModel))
            } else if let largeEventViewModel = LargeEventViewModel(timelineEvent: originalEvent) {
                eventViewModels.append(.largeEvent(largeEventViewModel))
            }
        }
        
        self.events = eventViewModels
    }
}

enum TimelineEventViewModel {
    case smallEvent(SmallEventViewModel)
    case largeEvent(LargeEventViewModel)
}

class SmallEventViewModel {
    
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
    
    func eventDescriptionForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
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
            WMFLocalizedString(
                "significant-events-small-change-description",
                value:"{{PLURAL:%1$d|0=No small changes|%1$d small change|%1$d small changes}} made",
                comment:"Describes how many small changes are batched together in the significant events timeline view. %1$d is replaced with the number of small changes."
            ),
            smallChange.count)
        
        let eventDescription = NSAttributedString(string: localizedString, attributes: attributes)
        
        self.lastTraitCollection = traitCollection
        self.eventDescription = eventDescription
        return eventDescription
    }
}

class LargeEventViewModel {
    
    enum ChangeDetail {
        case snippet(Snippet) //use for a basic horizontally scrolling snippet cell (will contain talk page topic snippets, added text snippets, article description updated snippets)
        case reference(Reference)
    }
    
    struct Snippet {
        let displayText: NSAttributedString
    }
    
    struct Reference {
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
    
    func eventDescriptionForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
        
        if let lastTraitCollection = lastTraitCollection,
           let eventDescription = eventDescription {
            if lastTraitCollection == traitCollection {
                return eventDescription
            }
        }
        
        let font = UIFont.wmf_font(.italicBody, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor: theme.colors.primaryText]
        
        let eventDescription: NSAttributedString
        switch timelineEvent {
        case .newTalkPageTopic:
            let localizedString = WMFLocalizedString("significant-events-new-talk-topic-description", value: "New discussion about this article", comment: "Title displayed in a significant events timeline cell explaining that a new article talk page topic has been posted.")
            eventDescription = NSAttributedString(string: localizedString, attributes: attributes)
        case .vandalismRevert(let vandalismRevert):
            
            let event = WMFLocalizedString("significant-events-vandalism-revert-description", value: "Suspected Vandalism reverted", comment: "Title displayed in a significant events timeline cell explaining that a vandalism revision was reverted.")
            
            let mutableAttributedString = NSMutableAttributedString(string: event, attributes: attributes)
            
            if let localizedSectionAttributedString = self.localizedSectionAttributedString(sectionsSet: Set(vandalismRevert.sections), traitCollection: traitCollection, theme: theme) {
                mutableAttributedString.append(localizedSectionAttributedString)
            }
            
            if let attributedString = mutableAttributedString.copy() as? NSAttributedString {
                eventDescription = attributedString
            } else {
                assertionFailure("This should not happen")
                eventDescription = NSAttributedString(string: "")
            }
        
        case .largeChange(let largeChange):
            
            let individualDescriptions = self.individualDescriptionsForTypedChanges(largeChange.typedChanges)
            let sortedDescriptions = individualDescriptions.sorted { $0.priority < $1.priority }
            
            switch sortedDescriptions.count {
            case 0:
                assertionFailure("This should not happen")
                eventDescription = NSAttributedString(string: "")
            case 1:
                let description = individualDescriptions[0].text
                eventDescription = NSAttributedString(string: description, attributes: attributes)
            case 2:
                let firstDescription = sortedDescriptions[0].text
                let secondDescription = sortedDescriptions[1].text
                let mergedDescription = String.localizedStringWithFormat(WMFLocalizedString("significant-events-two-descriptions-format", value: "%1$@ and %2$@", comment: "Format for two change types to insert into a revision's event description in a significant events timeline cell. %1$@ is replaced by the first change type and %2$@ is replaced by the second change type, e.g. '612 characters added and 323 characters removed'"), firstDescription, secondDescription)
                eventDescription = NSAttributedString(string: mergedDescription, attributes: attributes)
            default:
                //Note: This will not work properly in translations but for now this is works for an English-only feature
                let finalDelimiter = WMFLocalizedString("significant-events-multiple-descriptions-last-delimiter", value: "and", comment: "Text to show as the last delimiter in a list of multiple event changes. These changes are shown in the description area of a significant events timeline cell. e.g. '3 references added, 612 characters added and 100 characters removed'")
                let midDelimiter =
                    WMFLocalizedString("significant-events-multiple-descriptions-delimiter", value: ",", comment: "Text to show as the delimiters in a list of multiple event changes. These changes are shown in the description area of a significant events timeline cell. e.g. '3 references added, 612 characters added and 100 characters removed'")
                var finalDescription: String = ""
                for (index, description) in sortedDescriptions.enumerated() {
                    
                    let delimiter = index == sortedDescriptions.count - 2 ? finalDelimiter : midDelimiter
                    finalDescription += description.text
                    if index < sortedDescriptions.count - 1 {
                        finalDescription += delimiter
                    }
                }
                
                eventDescription = NSAttributedString(string: finalDescription, attributes: attributes)
            }
           
        case .smallChange:
            assertionFailure("Unexpected timeline event type")
            eventDescription = NSAttributedString(string: "")
        }
        
        self.lastTraitCollection = traitCollection
        self.eventDescription = eventDescription
        return eventDescription
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
                let description = String.localizedStringWithFormat(WMFLocalizedString("significant-events-added-text-description", value:"{{PLURAL:%1$d|0=0 characters|%1$d character|%1$d characters}} added",
                                                                                      comment:"Title displayed in a significant events timeline cell explaining that a revision has a certain number of characters added. %1$d is replaced by the number of characters added."), addedText.characterCount)
                descriptions.append(IndividualDescription(priority: 1, text: description))
            case .deletedText(let deletedText):
                let description = String.localizedStringWithFormat(WMFLocalizedString("significant-events-deleted-text-description", value:"{{PLURAL:%1$d|0=0 characters|%1$d character|%1$d characters}} deleted",
                                                                                      comment:"Title displayed in a significant events timeline cell explaining that a revision has a certain number of characters deleted. %1$d is replaced by the number of characters deleted."), deletedText.characterCount)
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
                    let description = WMFLocalizedString("significant-events-article-description-updated-description", value:"Article title description updated",
                                                         comment:"Title displayed in a significant events timeline cell explaining that an article's title description was updated in a revision.")
                    descriptions.append(IndividualDescription(priority: 3, text: description))
                }
            }
        }
        
        if descriptions.count == 0 {
            switch numReferences {
            case 0:
                break
            case 1:
                let description = WMFLocalizedString("significant-events-single-reference-added-description", value:"Reference added",
                                                     comment:"Title displayed in a significant events timeline cell when a reference was added (and no other changes) to a revision.")
                descriptions.append(IndividualDescription(priority: 0, text: description))
            default:
                let description = WMFLocalizedString("significant-events-multiple-references-added-description", value:"Multiple references added",
                                                     comment:"Title displayed in a significant events timeline cell when multiple references were added (and no other changes) to a revision.")
                descriptions.append(IndividualDescription(priority: 0, text: description))
            }
        } else {
            let description = String.localizedStringWithFormat(WMFLocalizedString("significant-events-numerical-multiple-references-added-description", value:"{{PLURAL:%1$d|0=0 references|%1$d reference|%1$d references}} added",
                                                                                  comment:"Title displayed in a significant events timeline cell explaining that multiple references were added to a revision. This string is use alongside other changes types like added characters. %1$d is replaced with the number of references."), numReferences)
            descriptions.append(IndividualDescription(priority: 0, text: description))
        }
        
        return descriptions
    }
    
    private func localizedSectionAttributedString(sectionsSet: Set<String>, traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString? {
        let sections = Array(sectionsSet)
        let localizedString: String
        switch sections.count {
        case 0:
            assertionFailure("This should not happen.")
            return nil
        case 1:
            let firstSection = sections[0]
            localizedString = String.localizedStringWithFormat(WMFLocalizedString("significant-events-one-section-description", value: "in the %1$@ section", comment: "Text explaining what section a significant event change occured in, if occured in only one section. %1$@ is replaced with the section name."), firstSection)
        case 2:
            let firstSection = sections[0]
            let secondSection = sections[1]
            localizedString = String.localizedStringWithFormat(WMFLocalizedString("significant-events-two-sections-description", value: "in the %1$@ and %2$@ sections", comment: "Text explaining what sections a significant event change occured in, if occured in two sections. %1$@ is replaced with the first section name, %2$@ with the second."), firstSection, secondSection)
        default:
            localizedString = String.localizedStringWithFormat(WMFLocalizedString("significant-events-many-sections-description", value: "in %1$d sections", comment: "Text explaining what sections a significant event change occured in, if occured in 3+ sections. %1$d is replaced with the number of sections."), sections.count)
        }
        
        let font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        let italicFont = UIFont.wmf_font(.italicSubheadline, compatibleWithTraitCollection: traitCollection)
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
        
        if let attributedString = mutableAttributedString.copy() as? NSAttributedString {
            return attributedString
        } else {
            assertionFailure("This shouldn't happen")
            return NSAttributedString(string: localizedString, attributes: attributes)
        }
    }
    
    func changeDetailsForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> [ChangeDetail] {
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
        case .vandalismRevert,
             .smallChange:
            assertionFailure("This should not happen")
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
            typeString = WMFLocalizedString("significant-events-new-book-reference-title",
                                                    value:"Book", comment: "Header text for a new book reference type that was added in a significant events revision cell.")
        case .journalCitation:
            typeString = WMFLocalizedString("significant-events-new-journal-reference-title",
                                                    value:"Journal", comment: "Header text for a new journal reference type that was added in a significant events revision cell.")
        case .newsCitation:
            typeString = WMFLocalizedString("significant-events-new-news-reference-title",
                                                    value:"News", comment: "Header text for a new news reference type that was added in a significant events revision cell.")
        case .websiteCitation:
            typeString = WMFLocalizedString("significant-events-new-website-reference-title",
                                                    value:"Website", comment: "Header text for a new website reference type that was added in a significant events revision cell.")
            
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
            volumeString = String.localizedStringWithFormat(WMFLocalizedString("significant-events-new-journal-reference-volume",
                                value:"Volume %1$@: ", comment: "Volume text for a new journal reference type that was added in a significant events revision cell. %1$@ is replaced by the journal volume number of the reference."), volumeNumber)
        }
        let volumeAttributedString = NSAttributedString(string: volumeString, attributes: boldAttributes)
        
        var descriptionEnd = ""
        if let database = journalCitation.database {
            let viaDatabaseString = String.localizedStringWithFormat(WMFLocalizedString("significant-events-new-journal-reference-database",
                                                       value:"via %1$@ ", comment: "Database text for a new journal reference type that was added in a significant events revision cell. %1$@ is replaced by the database volume number of the reference."), database)
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
            let archiveLinkText = WMFLocalizedString("significant-events-new-website-reference-archive-url-text",
                                                     value:"Archive.org URL", comment: "Archive.org url text for a new website reference type that was added in a significant events revision cell. This will be turned into a link that goes to the reference's archive.org url.")
            let range = NSRange(location: 0, length: archiveLinkText.count)
            let archiveLinkMutableAttributedString = NSMutableAttributedString(string: titleString)
            archiveLinkMutableAttributedString.addAttributes([NSAttributedString.Key.link : archiveUrl,
                                         NSAttributedString.Key.foregroundColor: theme.colors.link], range: range)
            
            if let archiveLinkAttributedString = archiveLinkMutableAttributedString.copy() as? NSAttributedString {
                
                let lastText =  String.localizedStringWithFormat(WMFLocalizedString("significant-events-new-website-reference-archive-date-text",
                                                            value:"from the original on %1$@", comment: "Text in a new website reference in a significant events timeline cell that describes when the reference was retrieved for Archive.org. %1$@ is replaced with the reference's archive date."), archiveDateString)
                
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
            retrievedString = String.localizedStringWithFormat(WMFLocalizedString("significant-events-new-news-reference-retrieved-date",
                                                       value:"Retrieved %1$@", comment: "Retrieved date text for a new news reference type that was added in a significant events revision cell. %1$@ is replaced by the reference's retrieved date."), accessDate)
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
            let isbnURL = Configuration.current.articleURLForHost("en.wikipedia.org", appending: [isbnTitle, isbn]).url
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
    
    func timestampForDisplay() -> String {
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
            return ""
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
    
    func userInfoForTraitCollection(_ traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
        if let lastTraitCollection = lastTraitCollection,
           let userInfo = userInfo {
            if lastTraitCollection == traitCollection {
                return userInfo
            }
        }
        
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
            assertionFailure("Shouldn't reach this point")
            return NSAttributedString(string: "")
        }
        
        var attributedString: NSAttributedString
        if userType != .anonymous {
            let userInfo = String.localizedStringWithFormat( WMFLocalizedString(
                "significant-events-revision-userInfo",
                value:"Edit by %1$@ ({{PLURAL:%2$d|0=0 edits|%2$d edit|%2$d edits}})", comment: "Text describing details about the user that made a significant revision in the significant events view. %1$@ is replaced by the editor name and %2$d is replaced by the number of edits they have made."), userName, editCount)
            
            let font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
            let attributes = [NSAttributedString.Key.font: font,
                              NSAttributedString.Key.foregroundColor: theme.colors.secondaryText]
            let rangeOfUserName = (userInfo as NSString).range(of: userName)
            let rangeValid = rangeOfUserName.location != NSNotFound && rangeOfUserName.location + rangeOfUserName.length <= userInfo.count
            let title = "User:\(userName)"
            let userNameURL = Configuration.current.articleURLForHost("en.wikipedia.org", appending: [title]).url
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
            let anonymousUserInfo = String.localizedStringWithFormat(WMFLocalizedString("significant-events-revision-userInfo-anonymous",
                                                       value:"Edit by %1$@", comment: "Text describing details about the anonyous user that made a significant revision in the significant events view. %1$@ is replaced by the editor's anonymous name."), userName)
            
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
