import Foundation
import Testing
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
struct WMFOnThisDayDataControllerTests {

    private func makeController(mockJSONResource: String) -> WMFOnThisDayDataController {
        let mockService = WMFMockBasicService(jsonResourceName: mockJSONResource)
        return WMFOnThisDayDataController(basicService: mockService)
    }

    @Test
    func fetchOnThisDayParsesEventsCount() async throws {
        let controller = makeController(mockJSONResource: "onthisday-events-02-21-get")

        let response = try await controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en", languageVariantCode: nil)), month: 2, day: 21)
        #expect(response.events.count == 3)
        #expect(response.events[0].text == "Wikipedia, a free wiki content encyclopedia, goes online.")
        #expect(response.events[0].year == 2001)
        #expect(response.events[0].pages.first?.title == "Wikipedia")
        #expect(response.events[0].pages.first?.description == "Free online encyclopedia that anyone can edit")
        let expectedURL = URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/8/80/Wikipedia-logo-v2.svg/320px-Wikipedia-logo-v2.svg.png")
        #expect(response.events[0].pages.first?.thumbnail?.source == expectedURL)
        let thumbnail = response.events[0].pages.first?.thumbnail
        #expect(thumbnail?.width == 320)
        #expect(thumbnail?.height == 320)
        let expectedURL2 = URL(string: "https://en.wikipedia.org/wiki/Wikipedia")
        #expect(response.events[0].pages.first?.contentUrls?.desktop?.page == expectedURL2)
        let expectedURL3 = URL(string: "https://en.m.wikipedia.org/wiki/Wikipedia")
        #expect(response.events[0].pages.first?.contentUrls?.mobile?.page == expectedURL3)
        #expect(response.events[2].pages.first?.thumbnail == nil)
        let secondEvent = response.events[1]
        #expect(secondEvent.year == 1844)
        #expect(secondEvent.text == "The Dominican Republic gains independence from Haiti.")
        #expect(secondEvent.pages.first?.title == "Dominican Republic")
    }

    @Test
    func fetchOnThisDayThrowsForWikidata() async throws {
        let controller = makeController(mockJSONResource: "onthisday-events-02-21-get")

        await #expect(throws: WMFDataControllerError.unsupportedProject) {
            _ = try await controller.fetchOnThisDay(project: .wikidata, month: 2, day: 21)
        }
    }

    @Test
    func fetchOnThisDayThrowsForCommons() async throws {
        let controller = makeController(mockJSONResource: "onthisday-events-02-21-get")

        await #expect(throws: WMFDataControllerError.unsupportedProject) {
            _ = try await controller.fetchOnThisDay(project: .commons, month: 2, day: 21)
        }
    }
}
