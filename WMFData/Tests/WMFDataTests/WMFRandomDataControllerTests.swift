import Foundation
import Testing
@testable import WMFData
@testable import WMFDataMocks

@Suite
struct WMFRandomDataControllerTests {

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func makeController(mockJSONResource: String) -> WMFRandomDataController {
        let mockService = WMFMockBasicService(jsonResourceName: mockJSONResource)
        return WMFRandomDataController(basicService: mockService)
    }

    // MARK: - fetchRandomArticleSummary

    @Test
    func fetchRandomArticleSummaryParsesFields() async throws {
        let controller = makeController(mockJSONResource: "random-article-summary-get")
        let summary = try await controller.fetchRandomArticleSummary(project: enProject)
        #expect(summary.displayTitle == "<span lang=\"en\" dir=\"ltr\"><span class=\"mw-page-title-main\">17th Battalion (Australia)</span></span>")
        #expect(summary.description == "Australian Army infantry battalion")
        #expect(summary.extract?.isEmpty == false)
        let expectedThumbnailURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Australian_17_Bn_entraining_near_the_Suez_Canal_in_1915_%28A00581%29.jpg/330px-Australian_17_Bn_entraining_near_the_Suez_Canal_in_1915_%28A00581%29.jpg")
        #expect(summary.thumbnailURL == expectedThumbnailURL)
    }

    @Test
    func fetchRandomArticleSummaryThrowsForUnsupportedProject() async throws {
        let controller = makeController(mockJSONResource: "random-article-summary-get")
        await #expect(throws: WMFDataControllerError.unsupportedProject) {
            _ = try await controller.fetchRandomArticleSummary(project: .wikidata)
        }
    }

    // MARK: - fetchRandomArticles

    @Test
    func fetchRandomArticlesParsesCount() async throws {
        let controller = makeController(mockJSONResource: "random-articles-get")
        let articles = try await controller.fetchRandomArticles(project: enProject)
        #expect(articles.count == 40)
    }

    @Test
    func fetchRandomArticlesParsesFirstArticleFields() async throws {
        let controller = makeController(mockJSONResource: "random-articles-get")
        let articles = try await controller.fetchRandomArticles(project: enProject)
        let first = try #require(articles.first)
        #expect(first.pageid == 470500)
        #expect(first.title == "Armavir Province")
        #expect(first.description == "Province of Armenia")
        #expect(first.extract?.isEmpty == false)
        #expect(first.variantTitles?.en == "Armavir Province")
        let expectedThumbnailURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Bagaran_village%2C_Armenian-Turkey_border.jpg/330px-Bagaran_village%2C_Armenian-Turkey_border.jpg")
        #expect(first.thumbnail?.url == expectedThumbnailURL)
        #expect(first.thumbnail?.width == 330)
        #expect(first.thumbnail?.height == 186)
    }

    @Test
    func fetchRandomArticlesArticleWithNoThumbnail() async throws {
        let controller = makeController(mockJSONResource: "random-articles-get")
        let articles = try await controller.fetchRandomArticles(project: enProject)
        // Vatera (index 1) has no description or extract in the live response
        let vatera = try #require(articles.first(where: { $0.title == "Vatera" }))
        #expect(vatera.description == nil)
    }

    @Test
    func fetchRandomArticlesThrowsForUnsupportedProject() async throws {
        let controller = makeController(mockJSONResource: "random-articles-get")
        await #expect(throws: WMFDataControllerError.unsupportedProject) {
            _ = try await controller.fetchRandomArticles(project: .commons)
        }
    }
}
