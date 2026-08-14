import XCTest
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

/// Covers the rule that an article the user saw does not come back into the feed for some days.
@MainActor
final class WMFHomeSeenArticlesTests: XCTestCase {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let otherProject = WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil))

    private func makeController() -> WMFHomeDataController {
        WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())
    }

    func testAnArticleThatWasNotSeenIsNotSuppressed() {
        let controller = makeController()

        XCTAssertTrue(controller.seenArticleTitles(project: project).isEmpty)
    }

    func testASeenArticleIsSuppressed() {
        let controller = makeController()

        controller.recordSeenArticle(title: "Octopus", project: project)

        XCTAssertTrue(controller.seenArticleTitles(project: project).contains("Octopus"))
    }

    /// The stored title uses spaces, so a title that arrives with underscores matches the same article.
    func testTitlesWithUnderscoresMatchTitlesWithSpaces() {
        let controller = makeController()

        controller.recordSeenArticle(title: "Giant_squid", project: project)

        XCTAssertTrue(controller.seenArticleTitles(project: project).contains("Giant squid"))
    }

    func testAnArticleSeenInOneProjectDoesNotAffectAnotherProject() {
        let controller = makeController()

        controller.recordSeenArticle(title: "Octopus", project: project)

        XCTAssertTrue(controller.seenArticleTitles(project: project).contains("Octopus"))
        XCTAssertFalse(controller.seenArticleTitles(project: otherProject).contains("Octopus"))
    }

    /// After the suppression period the article can come back into the feed.
    func testAnArticleComesBackAfterTheSuppressionPeriod() {
        let controller = makeController()
        let longAgo = Calendar.current.date(byAdding: .day, value: -(WMFHomeDataController.seenArticleSuppressionDays + 1), to: Date()) ?? Date()

        controller.recordSeenArticle(title: "Octopus", project: project, date: longAgo)

        XCTAssertFalse(controller.seenArticleTitles(project: project).contains("Octopus"))
    }

    func testAnArticleSeenInsideThePeriodStaysSuppressed() {
        let controller = makeController()
        let recently = Calendar.current.date(byAdding: .day, value: -(WMFHomeDataController.seenArticleSuppressionDays - 1), to: Date()) ?? Date()

        controller.recordSeenArticle(title: "Octopus", project: project, date: recently)

        XCTAssertTrue(controller.seenArticleTitles(project: project).contains("Octopus"))
    }
}
