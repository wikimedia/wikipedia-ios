@objc public extension WMFContentGroup {
    public var eventLoggingLabel: EventLoggingLabel? {
        switch contentGroupKind {
        case .featuredArticle:
            return .featuredArticle
        case .topRead:
            return .topRead
        case .onThisDay:
            return .onThisDay
        case .random:
            return .random
        case .news:
            return .news
        case .relatedPages:
            return .relatedPages
        case .locationPlaceholder:
            fallthrough
        case .location:
            return .location
        case .mainPage:
            return .mainPage
        default:
            return nil
        }
    }

    public var eventLoggingMeasureAge: NSNumber? {
        if appearsOncePerDay {
            return nil
        } else {
            guard let date = midnightUTCDate else {
                return nil
            }
            let now = NSDate().wmf_midnightUTCDateFromLocal
            return NSNumber(integerLiteral: NSCalendar.wmf_gregorian().wmf_days(from: date, to: now))
        }
    }

    public var appearsOncePerDay: Bool {
        switch contentGroupKind {
        case .continueReading:
            fallthrough
        case .relatedPages:
            return false
        default:
            return true
        }
    }
}

