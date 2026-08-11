import WMF
import WMFData
import CocoaLumberjackSwift
import WidgetKit

extension ArticleViewController {

    /// Persists CDPageView values in WMFData database. This will allow us to detect repeat article views, so we can display their most-viewed article in Year in Review
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
                } catch let error {
                    DDLogError("Error saving viewed page: \(error)")
                }
            }
        }
    }
    
    // MARK: - Reading time

    /// The rules for when reading time accumulates live in WMFReadingIntervalTracker, so they can be
    /// unit tested. These methods are the adapter: forward the lifecycle event, persist whatever
    /// seconds come back.

    func trackArticleDidAppear() {
        guard isTrackableArticle else { return }
        readingIntervalTracker.viewDidAppear(at: Date())
    }

    func trackArticleWillDisappear() {
        guard isTrackableArticle else { return }
        persistPageViewedSeconds(readingIntervalTracker.viewWillDisappear(at: Date()))
    }

    func trackAppDidBecomeActive() {
        guard isTrackableArticle else { return }
        readingIntervalTracker.appDidBecomeActive(at: Date())
    }

    func trackAppWillResignActive() {
        guard isTrackableArticle else { return }
        persistPageViewedSeconds(readingIntervalTracker.appWillResignActive(at: Date()))
    }

    private var isTrackableArticle: Bool {
        return articleURL.wmf_title != "Main Page"
    }

    /// Persists number of seconds viewed in CDPageView in WMFData database. This will allow us to display the total time spent reading a particular article in Year in Review.
    private func persistPageViewedSeconds(_ numberOfSeconds: TimeInterval?) {

        guard let numberOfSeconds,
              let pageViewObjectID else {
            return
        }

        Task {
            do {
                let pageViewsDataController = try WMFPageViewsDataController()
                try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: pageViewObjectID, numberOfSeconds: numberOfSeconds)
            } catch let error {
                DDLogError("Error appending viewed seconds: \(error)")
            }
        }
    }
}
