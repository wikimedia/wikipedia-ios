import Foundation
import Testing
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
struct WMFRelatedPagesDataControllerTests {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func makeController(jsonResourceName: String = "related-pages-get") -> WMFRelatedPagesDataController {
        let mockService = WMFMockBasicService(jsonResourceName: jsonResourceName)
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

    @Test
    func fetchRelatedPagesKeepsTheCanonicalTitleAndExposesTheDisplayTitle() async throws {
        let controller = makeController(jsonResourceName: "related-pages-display-title-get")
        let pages = try await controller.fetchRelatedPages(title: "IPhone", project: project)

        let iPhone = try #require(pages.first(where: { $0.pageid == 17916616 }))
        #expect(iPhone.title == "IPhone 3G")
        #expect(iPhone.displayTitle == "iPhone 3G")
    }

    @Test
    func fetchRelatedPagesLeavesTheDisplayTitleNilWhenTheResponseHasNone() async throws {
        let controller = makeController(jsonResourceName: "related-pages-display-title-get")
        let pages = try await controller.fetchRelatedPages(title: "IPhone", project: project)

        let plain = try #require(pages.first(where: { $0.pageid == 1234 }))
        #expect(plain.title == "Plain title")
        #expect(plain.displayTitle == nil)
    }

    @Test
    func fetchRelatedPagesPrefersTheVariantTitleOfTheProjectVariant() async throws {
        let traditionalChinese = WMFProject.wikipedia(WMFLanguage(languageCode: "zh", languageVariantCode: "zh-hant"))
        let controller = makeController(jsonResourceName: "related-pages-display-title-get")
        let pages = try await controller.fetchRelatedPages(title: "软件", project: traditionalChinese)

        let software = try #require(pages.first(where: { $0.pageid == 32106 }))
        #expect(software.title == "软件")
        #expect(software.displayTitle == "軟體")
    }

    @Test
    func fetchRelatedPagesFallsBackToTheDisplayTitleWhenTheVariantIsMissing() async throws {
        let unknownVariant = WMFProject.wikipedia(WMFLanguage(languageCode: "zh", languageVariantCode: "zh-sg"))
        let controller = makeController(jsonResourceName: "related-pages-display-title-get")
        let pages = try await controller.fetchRelatedPages(title: "软件", project: unknownVariant)

        let software = try #require(pages.first(where: { $0.pageid == 32106 }))
        #expect(software.displayTitle == "软件")
    }
}
