import Foundation

/// The main page of each wiki. Year in Review leaves main pages out of the reading history.
///
/// The slide factory looks the titles up once for each report build and gives the same value to
/// every slide, so each wiki is looked up once, not once per slide. Titles compare like the app-side
/// main page lookup: case does not matter, and spaces and underscores are the same.
struct YearInReviewMainPageTitles: Sendable {

    enum LookupError: Error {
        /// The main pages could not be looked up for this report build.
        case unavailable
    }

    /// The app does not record the English main page, but older data can contain it. It is left out
    /// on every wiki.
    static let englishMainPageTitle = "Main Page"

    private static let canonicalEnglishMainPageTitle = WMFMainPageTitle.canonicalized(englishMainPageTitle)

    /// Only the English main page is left out.
    static let englishOnly = YearInReviewMainPageTitles(canonicalTitlesByProjectID: [:])

    /// The canonicalized main page title, by `WMFProject.id`.
    private let canonicalTitlesByProjectID: [String: String]

    private init(canonicalTitlesByProjectID: [String: String]) {
        self.canonicalTitlesByProjectID = canonicalTitlesByProjectID
    }

    /// Looks up the main page of each wiki in `projectIDs`. Each lookup can go to the main actor.
    static func lookUp(projectIDs: some Sequence<String>, mainPageIdentifier: WMFMainPageIdentifying?) async -> YearInReviewMainPageTitles {
        guard let mainPageIdentifier else {
            return .englishOnly
        }
        var titles: [String: String] = [:]
        for projectID in Set(projectIDs) {
            if let project = WMFProject(id: projectID),
               let title = await mainPageIdentifier.mainPageTitle(for: project) {
                titles[projectID] = WMFMainPageTitle.canonicalized(title)
            }
        }
        return YearInReviewMainPageTitles(canonicalTitlesByProjectID: titles)
    }

    /// Looks up the main page of each wiki with page views from `startDate` to `endDate`.
    static func lookUp(startDate: Date, endDate: Date, pageViewsDataController: WMFPageViewsDataController, mainPageIdentifier: WMFMainPageIdentifying?) async throws -> YearInReviewMainPageTitles {
        guard mainPageIdentifier != nil else {
            return .englishOnly
        }
        let projectIDs = try await pageViewsDataController.fetchPageViewProjectIDs(startDate: startDate, endDate: endDate)
        return await lookUp(projectIDs: projectIDs, mainPageIdentifier: mainPageIdentifier)
    }

    func isMainPage(_ page: WMFPage) -> Bool {
        isMainPage(title: page.title, projectID: page.projectID)
    }

    /// - Parameter title: With spaces or underscores.
    func isMainPage(title: String, projectID: String) -> Bool {
        let title = WMFMainPageTitle.canonicalized(title)
        return title == Self.canonicalEnglishMainPageTitle || title == canonicalTitlesByProjectID[projectID]
    }

    /// The titles to leave out, for
    /// `WMFPageViewsDataController.fetchArticlePageViewLinks(startDate:endDate:excludedTitles:)`.
    /// The `nil` key is left out on every wiki. That fetch ignores case.
    var excludedTitles: [String?: [String]] {
        var excludedTitles: [String?: [String]] = [nil: [Self.englishMainPageTitle]]
        for (projectID, title) in canonicalTitlesByProjectID {
            excludedTitles[projectID] = [title]
        }
        return excludedTitles
    }
}
