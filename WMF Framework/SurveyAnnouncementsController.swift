
import Foundation

@objc(WMFSurveyAnnouncementsController)
public final class SurveyAnnouncementsController: NSObject {
    
    @objc public static let shared = SurveyAnnouncementsController()
    
    private let queue = DispatchQueue(label: "SurveyAnnouncementsQueue")
    
    //ex: 'en.wikipedia.org'
    typealias AnnouncementsHost = String
    private var announcementsByHost: [AnnouncementsHost: [WMFAnnouncement]] = [:]
    
    public struct SurveyAnnouncementResult {
        public let campaignIdentifier: String
        public let announcement: WMFAnnouncement
        public let actionURL: URL
        public let displayDelay: TimeInterval
    }
    
    @objc public func setAnnouncements(_ announcements: [WMFAnnouncement], forSiteURL siteURL: URL) {
        
        guard let components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false),
            let host = components.host else {
                return
        }
        
        queue.sync {
            announcementsByHost[host] = announcements.filter { $0.announcementType == .survey }
        }
    }
    
    private func getAnnouncementsForSiteURL(_ siteURL: URL) -> [WMFAnnouncement]? {
        guard let components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false),
            let host = components.host else {
                return nil
        }
        
        var announcements: [WMFAnnouncement]? = []
        queue.sync {
            announcements = announcementsByHost[host]
        }
        
        return announcements
    }
    
    //Use for determining whether to show user a survey prompt or not.
    //Considers domain, campaign start/end dates, article title in campaign, and whether survey has already been acted upon or not.
    public func activeSurveyAnnouncementResultForTitle(_ articleTitle: String, siteURL: URL) -> SurveyAnnouncementResult? {

        guard let announcements = getAnnouncementsForSiteURL(siteURL) else {
            return nil
        }
        
        for announcement in announcements {
            
            guard let startTime = announcement.startTime,
                let endTime = announcement.endTime,
                let domain = announcement.domain,
                let articleTitles = announcement.articleTitles,
                let displayDelay = announcement.displayDelay,
                let components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false),
                let host = components.host,
                let identifier = announcement.identifier,
                let normalizedArticleTitle = articleTitle.normalizedPageTitle,
                let googleFormattedArticleTitle = normalizedArticleTitle.googleFormPercentEncodedPageTitle else {
                    continue
            }
            
            guard let actionURL = announcement.actionURLReplacingPlaceholder("{{articleTitle}}", withValue: googleFormattedArticleTitle) else {
                continue
            }
                
            let now = Date()
            
            //do not show if user has already seen and answered for this campaign, even if the value is an NSNumber set to false, any answer is an indication that it shouldn't be shown
            guard UserDefaults.standard.object(forKey: identifier) == nil else {
                continue
            }
            
            //ignore startTime/endTime and reduce displayDelay for easier debug testing
            #if DEBUG
                
                if host == domain, articleTitles.contains(normalizedArticleTitle) {
                    
                    return SurveyAnnouncementResult(campaignIdentifier: identifier, announcement: announcement, actionURL: actionURL, displayDelay: 10.0)
                    
                }
            
            #else
            
                if now > startTime && now < endTime && host == domain, articleTitles.contains(normalizedArticleTitle) {
                    return SurveyAnnouncementResult(campaignIdentifier: identifier, announcement: announcement, actionURL: actionURL, displayDelay: displayDelay.doubleValue)
                }
            
            #endif
        }
        
        return nil
    }
    
    public func markSurveyAnnouncementAnswer(_ answer: Bool, campaignIdentifier: String) {
        UserDefaults.standard.setValue(answer, forKey: campaignIdentifier)
    }
}
