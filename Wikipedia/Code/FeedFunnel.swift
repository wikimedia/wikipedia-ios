// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSFeed

@objc public class FeedFunnelContext: NSObject {
    let label: EventLoggingLabel?
    let key: String?
    let midnightUTCDate: Date?
    let siteURLString: String?
    @objc(initWithContentGroup:)
    convenience init(_ group: WMFContentGroup?) {
        self.init(label: group?.eventLoggingLabel, key: group?.key, midnightUTCDate: group?.midnightUTCDate, siteURLString: group?.siteURLString)
    }
    init(label: EventLoggingLabel?, key: String?, midnightUTCDate: Date?, siteURLString: String?) {
        self.label = label
        self.key = key
        self.midnightUTCDate = midnightUTCDate
        self.siteURLString = siteURLString
        super.init()
    }
}

@objc public final class FeedFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    @objc public static let shared = FeedFunnel()
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSFeed", version: 18280649)
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
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action, measureAge: NSNumber? = nil, measurePosition: Int? = nil, measureTime: Double? = nil, measureMaxViewed: Double? = nil) -> Dictionary<String, Any> {
        let category = category.rawValue
        let action = action.rawValue
        
        var event: [String: Any] = ["category": category, "action": action, "primary_language": primaryLanguage(), "is_anon": isAnon]
        if let label = label?.rawValue {
            event["label"] = label
        }
        if let measureAge = measureAge {
            event["measure_age"] = measureAge.intValue
        }
        if let measurePosition = measurePosition {
            event["measure_position"] = measurePosition
        }
        if let measureTime = measureTime {
            event["measure_time"] = Int(round(measureTime))
        }
        if let measureMaxViewed = measureMaxViewed {
            event["measure_max_viewed"] = min(100, Int(floor(measureMaxViewed)))
        }
        return event
    }
    
    override public func preprocessData(_ eventData: [AnyHashable: Any]) -> [AnyHashable: Any] {
        return wholeEvent(with: eventData)
    }
    
    // MARK: - Feed

    @objc public func logFeedCardOpened(for context: FeedFunnelContext?) {
        startMeasuringTime(for: context?.label, key: context?.key)
        log(event(category: .feed, label: context?.label, action: .openCard, measureAge: measureAge(for: context?.midnightUTCDate)), language: language(from: context?.siteURLString))
    }

    @objc public func logFeedCardDismissed(for context: FeedFunnelContext?) {
        log(event(category: .feed, label: context?.label, action: .dismiss, measureAge: measureAge(for: context?.midnightUTCDate)), language: language(from: context?.siteURLString))
    }

    @objc public func logFeedCardRetained(for context: FeedFunnelContext?) {
        log(event(category: .feed, label: context?.label, action: .retain, measureAge: measureAge(for: context?.midnightUTCDate)), language: language(from: context?.siteURLString))
    }

    @objc public func logFeedCardPreviewed(for context: FeedFunnelContext?, index: Int) {
        log(event(category: .feed, label: context?.label, action: .preview, measureAge: measureAge(for: context?.midnightUTCDate), measurePosition: measurePosition(for: context?.label, index: index)), language: language(from: context?.siteURLString))
    }

    public func logFeedCardReadingStarted(for context: FeedFunnelContext?, index: Int?) {
        log(event(category: .feed, label: context?.label, action: .readStart, measureAge: measureAge(for: context?.midnightUTCDate), measurePosition: measurePosition(for: context?.label, index: index)), language: language(from: context?.siteURLString))
    }

    public func logFeedShareTapped(for context: FeedFunnelContext?, index: Int?) {
        log(event(category: .feed, label: context?.label, action: .shareTap, measureAge: measureAge(for: context?.midnightUTCDate), measurePosition: measurePosition(for: context?.label, index: index)), language: language(from: context?.siteURLString))
    }

    public func logFeedRefreshed() {
        log(event(category: .feed, label: nil, action: .refresh))
    }

    @objc public func logFeedImpression(for context: FeedFunnelContext?) {
        log(event(category: .feed, label: context?.label, action: .impression, measureAge: measureAge(for: context?.midnightUTCDate)), language: language(from: context?.siteURLString))
    }

    // MARK: Feed detail

    public func logArticleInFeedDetailPreviewed(for context: FeedFunnelContext?, index: Int?) {
        log(event(category: .feedDetail, label: context?.label, action: .preview, measureAge: measureAge(for: context?.midnightUTCDate), measurePosition: index), language: language(from: context?.siteURLString))
    }

    public func logArticleInFeedDetailReadingStarted(for context: FeedFunnelContext?, index: Int?, maxViewed: Double) {
        log(event(category: .feedDetail, label: context?.label, action: .readStart, measureAge: measureAge(for: context?.midnightUTCDate), measurePosition: index, measureTime: measureTime(key: context?.key), measureMaxViewed: maxViewed), language: language(from: context?.siteURLString))
        startMeasuringTime(for: context?.label, key: context?.key)
    }

    public func logFeedCardClosed(for context: FeedFunnelContext?, maxViewed: Double) {
        log(event(category: .feedDetail, label: context?.label, action: .closeCard, measureAge: measureAge(for: context?.midnightUTCDate), measureTime: measureTime(key: context?.key), measureMaxViewed: maxViewed), language: language(from: context?.siteURLString))
    }

    public func logFeedDetailShareTapped(for context: FeedFunnelContext?, index: Int?, midnightUTCDate: Date?) {
        log(event(category: .feedDetail, label: context?.label, action: .shareTap, measureAge: measureAge(for: context?.midnightUTCDate), measurePosition: index), language: language(from: context?.siteURLString))
    }

    public func logFeedDetailShareTapped(for context: FeedFunnelContext?, index: Int?) {
        log(event(category: .feedDetail, label: context?.label, action: .shareTap, measureAge: measureAge(for: context?.midnightUTCDate), measurePosition: index), language: language(from: context?.siteURLString))
    }

    // MARK: Utilities

    public var fetchedContentGroupsInFeedController: NSFetchedResultsController<WMFContentGroup>?

    private func measureAge(for midnightUTCDate: Date?) -> NSNumber? {
        guard let date = midnightUTCDate else {
            return nil
        }
        let now = NSDate().wmf_midnightUTCDateFromLocal
        return NSNumber(integerLiteral: NSCalendar.wmf_gregorian().wmf_days(from: date, to: now))
    }

    private func measurePosition(for label: EventLoggingLabel?, index: Int?) -> Int? {
        guard let label = label else {
            return nil
        }
        switch label {
        case .onThisDay:
            fallthrough
        case .news:
            return nil
        default:
            return index
        }
    }

    private var contentGroupKeysToStartTimes = [String: Date]()

    private func shouldMeasureTime(for label: EventLoggingLabel?) -> Bool {
        guard let label = label else {
            return false
        }
        switch label {
        case .topRead:
            fallthrough
        case .relatedPages:
            fallthrough
        case .onThisDay:
            fallthrough
        case .news:
            fallthrough
        case .location:
            return true
        default:
            return false
        }
    }

    private func startMeasuringTime(for label: EventLoggingLabel?, key: String?) {
        guard shouldMeasureTime(for: label) else {
            return
        }
        guard let key = key else {
            assertionFailure()
            return
        }
        contentGroupKeysToStartTimes[key] = Date()
    }

    private func measureTime(key: String?) -> Double? {
        guard let key = key, let startTime = contentGroupKeysToStartTimes[key] else {
            return nil
        }
        let measureTime = fabs(startTime.timeIntervalSinceNow)
        contentGroupKeysToStartTimes.removeValue(forKey: key)
        return measureTime
    }

    private func language(from siteURLString: String?) -> String? {
        guard let siteURLString = siteURLString else {
            return nil
        }
        return URL(string: siteURLString)?.wmf_language
    }
}
