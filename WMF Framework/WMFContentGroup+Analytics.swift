import Foundation

extension WMFContentGroup: AnalyticsContentTypeProviding {
    public var analyticsContentType: String {
        switch contentGroupKind {
        case .continueReading:
            return "Continue Reading"
        case .mainPage:
            return "Main Page"
        case .relatedPages:
            return "Recommended"
        case .location:
            return "Nearby"
        case .locationPlaceholder:
            return "Nearby Placeholder"
        case .pictureOfTheDay:
            return "Picture of the Day"
        case .random:
            return "Random"
        case .featuredArticle:
            return "Featured"
        case .topRead:
            return "Most Read"
        case .news:
            return "In The News"
        case .onThisDay:
            return "On This Day"
        case .notification:
            return "Notifications"
        case .theme:
            return "Themes"
        case .announcement:
            return "Announcement"
        default:
            return "Unknown Content Type"
        }
    }
}

extension WMFContentGroup: AnalyticsValueProviding {
    public var analyticsValue: NSNumber? {
        switch contentGroupKind {
        case .announcement:
            let nonNumericCharacterSet = CharacterSet.decimalDigits.inverted
            guard let announcement = contentPreview as? WMFAnnouncement else {
                fallthrough
            }
            guard let numberString = announcement.identifier?.trimmingCharacters(in: nonNumericCharacterSet) else {
                fallthrough
            }
            guard let integer = Int(numberString) else {
                fallthrough
            }
            return NSNumber(value: integer)
        default:
            return nil
        }
    }
}
