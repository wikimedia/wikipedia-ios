import Foundation
import Testing
@testable import WMFData
@testable import WMFDataMocks

@Suite
struct WMFArticleSearchDataControllerTests {

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func makeController(mockJSONResource: String = "article-prefix-search-get") -> WMFArticleSearchDataController {
        let mockService = WMFMockBasicService(jsonResourceName: mockJSONResource)
        return WMFArticleSearchDataController(basicService: mockService)
    }

    @Test
    func searchParsesResults() async throws {
        let controller = makeController()
        let results = try await controller.search(term: "einstein", project: enProject)
        #expect(results.count == 4)
    }

    @Test
    func searchSortsResultsByIndex() async throws {
        let controller = makeController()
        let results = try await controller.search(term: "einstein", project: enProject)
        #expect(results.map(\.title) == ["Albert Einstein", "Quark", "Talk:Albert Einstein", "Quasar"])
    }

    @Test
    func searchParsesResultFields() async throws {
        let controller = makeController()
        let results = try await controller.search(term: "einstein", project: enProject)
        let first = try #require(results.first)
        #expect(first.pageID == 736)
        #expect(first.namespace == 0)
        #expect(first.title == "Albert Einstein")
        #expect(first.displayTitle == "Albert Einstein")
        #expect(first.description == "German-born theoretical physicist (1879–1955)")
        let expectedThumbnailURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Einstein_1921_by_F_Schmutzer_-_restoration.jpg/93px-Einstein_1921_by_F_Schmutzer_-_restoration.jpg")
        #expect(first.thumbnailURL == expectedThumbnailURL)
    }

    @Test
    func searchIdentifiesNonMainNamespaceResults() async throws {
        let controller = makeController()
        let results = try await controller.search(term: "talk:einstein", project: enProject)
        let talkPage = try #require(results.first(where: { $0.title == "Talk:Albert Einstein" }))
        #expect(talkPage.namespace == 1)
        #expect(talkPage.isMainNamespace == false)

        let mainspaceResults = results.filter(\.isMainNamespace)
        #expect(mainspaceResults.count == 3)
    }

    @Test
    func searchHandlesResultWithoutThumbnailOrDescription() async throws {
        let controller = makeController()
        let results = try await controller.search(term: "einstein", project: enProject)
        let talkPage = try #require(results.first(where: { $0.title == "Talk:Albert Einstein" }))
        #expect(talkPage.description == nil)
        #expect(talkPage.thumbnailURL == nil)
    }

    @Test
    func searchWithEmptyTermReturnsEmptyWithoutNetworkCall() async throws {
        // A service that would fail on any request proves no request is made
        let controller = WMFArticleSearchDataController(basicService: nil)
        let results = try await controller.search(term: "   \n", project: enProject)
        #expect(results.isEmpty)
    }

    @Test
    func searchThrowsForUnsupportedProject() async throws {
        let controller = makeController()
        await #expect(throws: WMFDataControllerError.unsupportedProject) {
            _ = try await controller.search(term: "einstein", project: .commons)
        }
    }
}
