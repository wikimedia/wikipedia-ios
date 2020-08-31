
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

struct SmallEventViewModel {
    
    private var attributedText: NSAttributedString?
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
    
    mutating func attributedTextForTraitCollection(_ traitCollection: UITraitCollection) -> NSAttributedString {
        if let lastTraitCollection = lastTraitCollection,
           let attributedText = attributedText {
            if lastTraitCollection == traitCollection {
                return attributedText
            }
        }
        
        let font = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font]
        
        let localizedString = String.localizedStringWithFormat(
            WMFLocalizedString(
                "significant-events-small-change-title",
                value:"{{PLURAL:%1$d|0=No small changes|%1$d small change|%1$d small changes}} made",
                comment:"Describes how many small changes are batched together in the significant events timeline view."
            ),
            smallChange.count)
        
        let attributedText = NSAttributedString(string: localizedString, attributes: attributes)
        
        self.lastTraitCollection = traitCollection
        self.attributedText = attributedText
        return attributedText
    }
}

struct LargeEventViewModel {
    private let largeChange: SignificantEvents.LargeChange
    
    init?(timelineEvent: SignificantEvents.TimelineEvent) {
        return nil
    }
}
