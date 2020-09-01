
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
                    comment:"Describes how many small changes are batched together in the significant events timeline view."),
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
                comment:"Describes how many small changes are batched together in the significant events timeline view."
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
        case newTalkPageTopic(NewTalkPageTopicChange)
    }
    
    struct NewTalkPageTopicChange {
        let snippet: NSAttributedString
    }
    
    private let timelineEvent: SignificantEvents.TimelineEvent
    private(set) var eventDescription: NSAttributedString?
    private(set) var changeDetails: [ChangeDetail]?
    private var lastTraitCollection: UITraitCollection?
    
    init?(timelineEvent: SignificantEvents.TimelineEvent) {
        switch timelineEvent {
        case .newTalkPageTopic:
            break
        default:
            return nil
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
        default:
            assertionFailure("Unexpected timeline event type")
            eventDescription = NSAttributedString(string: "")
        }
        
        self.lastTraitCollection = traitCollection
        self.eventDescription = eventDescription
        return eventDescription
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
            let attributedString = newTalkPageTopic.snippet.byAttributingHTML(with: .subheadline, boldWeight: .semibold, matching: traitCollection, color: theme.colors.primaryText, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true)
            let newTopicChangeDetail = ChangeDetail.newTalkPageTopic(NewTalkPageTopicChange(snippet: attributedString))
            changeDetails.append(newTopicChangeDetail)
        default:
            break
        }
        
        self.lastTraitCollection = traitCollection
        self.changeDetails = changeDetails
        return changeDetails
    }
}
