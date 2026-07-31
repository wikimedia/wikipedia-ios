import WMF
import WMFData
import CocoaLumberjackSwift
import WidgetKit

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
                    let timestamp = Date()
                    let pageViewsDataController = try WMFPageViewsDataController()
                    let objectID = try await pageViewsDataController.addPageView(title: title, namespaceID: Int16(namespace.rawValue), project: wmfProject, previousPageViewObjectID: previousPageViewObjectID, timestamp: timestamp)
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

        // Close out the interval before the async write, not inside it. Otherwise a second call arriving before the write finishes (for example leaving the article and immediately backgrounding the app) still sees a begin date and persists the same interval twice.
        self.beganViewingDate = nil

        let elapsed = Date().timeIntervalSince(beganViewingDate)

        guard elapsed > 0 else {
            return
        }

        // An interval longer than the ceiling is almost certainly one we failed to close — e.g. an iPad window that stayed "active" while the user worked in another app — rather than real reading.
        let numberOfSeconds = min(elapsed, WMFPageViewsDataController.maximumReadingIntervalSeconds)

        Task {
            do {
                let pageViewsDataController = try WMFPageViewsDataController()
                try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: pageViewObjectID, numberOfSeconds: numberOfSeconds)
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

        // Only the article the user is actually looking at should accumulate reading time. Every live ArticleViewController observes UIApplication.didBecomeActiveNotification, so without this the off-screen ones (earlier entries in the navigation stack, other tab bar stacks, other article tabs) each record the full foreground session too, multiplying the reported total by the number of articles held in memory.
        guard isArticleOnScreen else {
            return
        }

        guard pageViewObjectID != nil,
              beganViewingDate == nil else {
            return
        }

        self.beganViewingDate = Date()
    }
}
