// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSFeed

@objc public final class FeedFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    @objc public static let shared = FeedFunnel()
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSFeed", version: 18225687)
    }
    
    private enum Action: String {
        case impression
        case openCard = "open_card"
        case dismiss
        case retain
        case refresh
        case preview
        case readStart = "read_start"
        case shareTap = "share_tap"
        case closeCard = "close_card"
    }
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action, measureAge: Double? = nil, measurePosition: Double? = nil, measureTime: Double? = nil, measureMaxViewed: Double? = nil) -> Dictionary<String, Any> {
        let category = category.rawValue
        let action = action.rawValue
        
        var event: [String: Any] = ["category": category, "action": action, "primary_language": primaryLanguage(), "is_anon": isAnon]
        if let label = label?.rawValue {
            event["label"] = label
        }
        if let measureAge = measureAge {
            event["measure_age"] = Int(round(measureAge))
        }
        if let measurePosition = measurePosition {
            event["measure_position"] = Int(round(measurePosition))
        }
        if let measureTime = measureTime {
            event["measure_time"] = Int(round(measureTime))
        }
        if let measureMaxViewed = measureMaxViewed {
            event["measure_max_viewed"] = Int(round(measureMaxViewed))
        }
        return event
    }
    
    override public func preprocessData(_ eventData: [AnyHashable: Any]) -> [AnyHashable: Any] {
        return wholeEvent(with: eventData)
    }
    
    // MARK: - Feed

    /*
    @objc public func logFeedImpression(for label: EventLoggingLabel) {
        log(event(category: .feed, label: label, action: .impression))
    }

    @objc public func logFeedDetailImpression(for label: EventLoggingLabel) {
        log(event(category: .feedDetail, label: label, action: .impression))
    }
    */

    @objc public func logFeedCardOpened(for label: EventLoggingLabel?) {
        log(event(category: .feedDetail, label: label, action: .openCard))
    }

    @objc public func logFeedCardDismissed(for label: EventLoggingLabel?) {
        log(event(category: .feed, label: label, action: .dismiss))
    }

    @objc public func logFeedCardRetained(for label: EventLoggingLabel?) {
        log(event(category: .feed, label: label, action: .retain))
    }

    @objc public func logFeedCardPreviewed(for label: EventLoggingLabel?) {
        log(event(category: .feed, label: label, action: .preview))
    }

    @objc public func logFeedCardReadingStarted(for label: EventLoggingLabel?) {
        log(event(category: .feed, label: label, action: .readStart))
    }

    @objc public func logFeedRefreshed() {
        log(event(category: .feed, label: nil, action: .refresh))
    }
}
/*
 Q: what constitutes an impression? (on feed is it first time user sees it, or each time it scrolls into view?)
 A: FOR NOW: (per Chelsy) log impression if card onscreen for more than 1 second (doesn't matter if moving - may tweak later if needed)
      do same for feed education card (1 second min onscreen before logging)

 Labels:
 EventLoggingLabel const EventLoggingLabelFeaturedArticle = @"featured_article";
 EventLoggingLabel const EventLoggingLabelTopRead = @"top_read";
 EventLoggingLabel const EventLoggingLabelOnThisDay = @"on_this_day";
 EventLoggingLabel const EventLoggingLabelNews = @"news";
 EventLoggingLabel const EventLoggingLabelRelatedPages = @"related_pages";
 EventLoggingLabel const EventLoggingLabelContinueReading = @"continue_reading";
 EventLoggingLabel const EventLoggingLabelMainPage = @"main_page";
 EventLoggingLabel const EventLoggingLabelLocation = @"location";  (ok use "location" instead of "places"? ask chelsy - yes - 5.8.2 uses it when you save compass cell from feed via peek menu save)
 EventLoggingLabel const EventLoggingLabelRandom = @"random";
 EventLoggingLabel const EventLoggingLabelPictureOfTheDay = @"picture_of_the_day";
*/
