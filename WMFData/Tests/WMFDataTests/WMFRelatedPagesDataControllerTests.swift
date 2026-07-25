import Foundation
import Testing
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
struct WMFRelatedPagesDataControllerTests {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func makeController() -> WMFRelatedPagesDataController {
        let mockService = WMFMockBasicService(jsonResourceName: "related-pages-get")
        return WMFRelatedPagesDataController(basicService: mockService)
    }

    @Test
    func fetchRelatedPagesReturnsCorrectCount() async throws {
        let controller = makeController()
        let pages = try await controller.fetchRelatedPages(title: "Cat", project: project)
        #expect(pages.count == 3)
    }

    @Test
    func fetchRelatedPagesDeserializesFirstPage() async throws {
        let controller = makeController()
        let pages = try await controller.fetchRelatedPages(title: "Cat", project: project)

        let first = try #require(pages.first)
        #expect(first.pageid == 586558)
        #expect(first.title == "Trap–neuter–return")
        #expect(first.description == "Strategy for controlling feral animal populations")
        #expect(first.thumbnailURL == URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/02/Feral_cat%2C_sterilized_through_a_Trap-Neuter-Return_program.jpg/250px-Feral_cat%2C_sterilized_through_a_Trap-Neuter-Return_program.jpg"))
        #expect(first.extract?.hasPrefix("Trap–neuter–return (TNR)") == true)
    }

    @Test
    func fetchRelatedPagesDeserializesPageWithoutThumbnail() async throws {
        let controller = makeController()
        let pages = try await controller.fetchRelatedPages(title: "Cat", project: project)

        // Purr has no thumbnail in the response
        let purr = try #require(pages.first(where: { $0.pageid == 629216 }))
        #expect(purr.title == "Purr")
        #expect(purr.description == "Fluttering vocalization")
        #expect(purr.thumbnailURL == nil)
    }

    @Test
    func fetchRelatedPagesDeserializesAllTitles() async throws {
        let controller = makeController()
        let pages = try await controller.fetchRelatedPages(title: "Cat", project: project)

        #expect(pages.map(\.title) == ["Trap–neuter–return", "Purr", "Feral cat"])
    }
}
