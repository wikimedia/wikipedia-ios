import WMF
import WMFData
import CocoaLumberjackSwift

extension ArticleViewController {
    
    /// Persists CDPageView values in WMFData database. This will allow us to detect repeat article views, so we can display their most-viewed article in Year in Review
    /// Also begins tracking a viewed date. This is so that we can later save the number of viewed seconds when the user leaves the article view or backgrounds
    func persistPageViewsForWikipediaInReview() {
        if let title = self.articleURL.wmf_title,
           title != "Main Page",
           let namespace = self.articleURL.namespace,
           let siteURL = self.articleURL.wmf_site,
           let project = WikimediaProject(siteURL: siteURL),
           let wmfProject = project.wmfProject {
            Task {
                do {
                    let pageViewsDataController = try WMFPageViewsDataController()
                    let objectID = try await pageViewsDataController.addPageView(title: title, namespaceID: Int16(namespace.rawValue), project: wmfProject, previousPageViewObjectID: previousPageViewObjectID)
                    self.pageViewObjectID = objectID
                    self.trackBeganViewingDate()
                } catch let error {
                    DDLogError("Error saving viewed page: \(error)")
                }
            }
        }
    }
    
    /// Persists number of seconds viewed in CDPageView in WMFData database. This will allow us to display the total time spent reading a particular article in Year in Review. Called when the user leaves the article view or backgrounds.
    func persistPageViewedSecondsForWikipediaInReview() {
        
        guard articleURL.wmf_title != "Main Page" else {
            return
        }
        
        guard let pageViewObjectID,
              let beganViewingDate else {
            return
        }
        
        let numberOfSeconds = Date().timeIntervalSince(beganViewingDate)
        
        Task {
            do {
                let pageViewsDataController = try WMFPageViewsDataController()
                try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: pageViewObjectID, numberOfSeconds: numberOfSeconds)
                
                self.beganViewingDate = nil
            } catch let error {
                DDLogError("Error appending viewed seconds: \(error)")
            }
        }
    }
    
    /// Begins tracking a viewed date. This is so that we can later save the number of viewed seconds when the user leaves the article view or backgrounds
    func trackBeganViewingDate() {
        
        guard articleURL.wmf_title != "Main Page" else {
            return
        }
        
        guard pageViewObjectID != nil,
              beganViewingDate == nil else {
            return
        }
        
        self.beganViewingDate = Date()
    }
}
