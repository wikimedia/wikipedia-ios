import Foundation

public extension WMFContentGroup {
    func getAnalyticsLabel() -> EventLabelMEP? {
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
        case .continueReading:
            return .continueReading
        case .locationPlaceholder:
            fallthrough
        case .location:
            return .location
        case .mainPage:
            return .mainPage
        case .pictureOfTheDay:
            return .pictureOfTheDay
        case .announcement:
            guard let announcement = contentPreview as? WMFAnnouncement else {
                return .announcement
            }
            return announcement.placement == "article" ? .articleAnnouncement : .announcement
        default:
            return nil
        }
    }
}
