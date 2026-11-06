import Foundation

/// The main pages that Year in Review slides leave out of the reading history.
enum YearInReviewMainPageTitles {

    /// The app does not record the English main page, but older data can contain it.
    static let englishMainPageTitle = "Main Page"

    /// The main page title of each wiki with page views inside the window, by `WMFProject.id`, for
    /// `WMFPageViewsDataController.fetchArticlePageViewLinks(startDate:endDate:excludedTitles:)`.
    /// The English main page is left out on every wiki. The title of each wiki is fetched once.
    /// Each request can go to the main actor.
    static func excludedTitles(startDate: Date, endDate: Date, pageViewsDataController: WMFPageViewsDataController, mainPageIdentifier: WMFMainPageIdentifying?) async throws -> [String?: [String]] {
        var excludedTitles: [String?: [String]] = [nil: [englishMainPageTitle]]
        for projectID in try await pageViewsDataController.fetchPageViewProjectIDs(startDate: startDate, endDate: endDate) {
            if let project = WMFProject(id: projectID),
               let title = await mainPageIdentifier?.mainPageTitle(for: project) {
                excludedTitles[projectID] = [title]
            }
        }
        return excludedTitles
    }
}
