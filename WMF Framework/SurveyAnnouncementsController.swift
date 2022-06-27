import Foundation

@objc(WMFSurveyAnnouncementsController)
public final class SurveyAnnouncementsController: NSObject {
    
    @objc public static let shared = SurveyAnnouncementsController()
    
    private let queue = DispatchQueue(label: "SurveyAnnouncementsQueue")
    
    // ex: 'en.wikipedia.org'
    typealias AnnouncementsHost = String
    private var announcementsByHost: [AnnouncementsHost: [WMFAnnouncement]] = [:]
    
    public struct SurveyAnnouncementResult {

        public let campaignIdentifier: String
        public let announcement: WMFAnnouncement
        public let actionURLString: String
        public let displayDelay: TimeInterval
    }
    
    public private(set) var failureDeterminingABTestBucket = false
    
    @objc public func setAnnouncements(_ announcements: [WMFAnnouncement], forSiteURL siteURL: URL, dataStore: MWKDataStore) {
        
        guard let components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false),
            let host = components.host else {
                return
        }
        
        let surveyAnnouncements = announcements.filter { $0.announcementType == .survey }
        
        queue.sync {
            announcementsByHost[host] = surveyAnnouncements
        }
        
        // assign and persist ab test bucket &  percentage
        // this works for now since we only have one experiment for this release but will likely need to change as we expand
        if let articleAsLivingDocAnnouncement = surveyAnnouncements.first(where: { ($0.identifier?.hasPrefix("IOSAAALDSURVEY")) ?? false }),
           let percentage = articleAsLivingDocAnnouncement.percentReceivingExperiment {
            
            do {
                if dataStore.abTestsController.percentageForExperiment(.articleAsLivingDoc) == nil {
                    try dataStore.abTestsController.setPercentage(percentage, forExperiment: .articleAsLivingDoc)
                }
                
                try dataStore.abTestsController.determineBucketForExperiment(.articleAsLivingDoc, withPercentage: percentage)
                failureDeterminingABTestBucket = false
            } catch {
                failureDeterminingABTestBucket = true
            }
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
    
    // Use for determining whether to show user a survey prompt or not.
    // Considers domain, campaign start/end dates, and whether articleURL is within allowlist of article titles in campaign
    public func activeSurveyAnnouncementResultForArticleURL(_ articleURL: URL) -> SurveyAnnouncementResult? {
        
        guard let articleTitle = articleURL.wmf_title?.denormalizedPageTitle, let siteURL = articleURL.wmf_site else {
            return nil
        }

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
                let actionURLString = announcement.actionURLString else {
                    continue
            }
    
            let now = Date()
            
            if now > startTime && now < endTime && host == domain, articleTitles.contains(normalizedArticleTitle) {
                return SurveyAnnouncementResult(campaignIdentifier: identifier, announcement: announcement, actionURLString: actionURLString, displayDelay: displayDelay.doubleValue)
            }
        }
        
        return nil
    }
    
    public func userHasSeenSurveyPrompt(forCampaignIdentifier identifier: String) -> Bool {
        // Note any value indicates survey was seen.
        // true = they tapped through to the Google survey, false = they dismissed the survey prompt.
        guard UserDefaults.standard.object(forKey: identifier) == nil else {
            return true
        }
        
        return false
    }
    
    public func markSurveyAnnouncementAnswer(_ answer: Bool, campaignIdentifier: String) {
        UserDefaults.standard.setValue(answer, forKey: campaignIdentifier)
    }
}
