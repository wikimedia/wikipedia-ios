import Testing
import Foundation
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

/// Covers the rule that an article the user saw does not come back into the feed for some days.
@MainActor
@Suite
struct WMFHomeSeenArticlesTests {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let otherProject = WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil))

    private func makeController() -> WMFHomeDataController {
        WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())
    }

    private func date(daysAgo days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }

    @Test
    func anArticleThatWasNotSeenIsNotSuppressed() {
        let controller = makeController()

        #expect(controller.seenArticleTitles(project: project).isEmpty)
    }

    @Test
    func aSeenArticleIsSuppressed() {
        let controller = makeController()

        controller.recordSeenArticle(title: "Octopus", project: project)

        #expect(controller.seenArticleTitles(project: project).contains("Octopus"))
    }

    /// The stored title uses spaces, so a title that arrives with underscores matches the same article.
    @Test
    func titlesWithUnderscoresMatchTitlesWithSpaces() {
        let controller = makeController()

        controller.recordSeenArticle(title: "Giant_squid", project: project)

        #expect(controller.seenArticleTitles(project: project).contains("Giant squid"))
    }

    @Test
    func anArticleSeenInOneProjectDoesNotAffectAnotherProject() {
        let controller = makeController()

        controller.recordSeenArticle(title: "Octopus", project: project)

        #expect(controller.seenArticleTitles(project: project).contains("Octopus"))
        #expect(!controller.seenArticleTitles(project: otherProject).contains("Octopus"))
    }

    /// One day inside the period keeps the article away, and one day outside it lets the article come back.
    @Test(arguments: [
        (WMFHomeDataController.seenArticleSuppressionDays - 1, true),
        (WMFHomeDataController.seenArticleSuppressionDays + 1, false)
    ])
    func anArticleIsSuppressedOnlyInsideTheSuppressionPeriod(daysAgo: Int, isSuppressed: Bool) {
        let controller = makeController()

        controller.recordSeenArticle(title: "Octopus", project: project, date: date(daysAgo: daysAgo))

        #expect(controller.seenArticleTitles(project: project).contains("Octopus") == isSuppressed)
    }
}
