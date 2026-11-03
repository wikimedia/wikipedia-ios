import Foundation
import Testing
@testable import WMFData

@Suite
struct WMFShareReadingListDataControllerTests {

    private let englishProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let spanishProject = WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil))

    // MARK: - Link

    @Test
    func encodedListIsBase64OfTheListJSON() throws {
        let encodedList = try #require(WMFShareReadingListDataController.encodedList(pageIDsByLanguageCode: ["en": [736, 15580374]]))
        let base64 = try #require(encodedList.removingPercentEncoding)
        let data = try #require(Data(base64Encoded: base64))

        #expect(String(bytes: data, encoding: .utf8) == #"{"list":{"en":[736,15580374]}}"#)
    }

    @Test
    func encodedListDecodesWithTheImportFormat() throws {
        let pageIDsByLanguageCode = ["en": [1, 2], "es": [3]]
        let encodedList = try #require(WMFShareReadingListDataController.encodedList(pageIDsByLanguageCode: pageIDsByLanguageCode))
        let base64 = try #require(encodedList.removingPercentEncoding)
        let data = try #require(Data(base64Encoded: base64))
        let decoded = try JSONDecoder().decode(WMFShareReadingListDataController.ExportedReadingList.self, from: data)

        #expect(decoded.list == pageIDsByLanguageCode)
    }

    @Test
    func encodedListHasOnlyQuerySafeCharacters() throws {
        // This list gives "==" at the end of the base64 text.
        let encodedList = try #require(WMFShareReadingListDataController.encodedList(pageIDsByLanguageCode: ["en": [1]]))

        #expect(encodedList == "eyJsaXN0Ijp7ImVuIjpbMV19fQ%3D%3D")
    }

    @Test
    func shareURLOpensSpecialReadingListsWithImportAndProvenance() throws {
        let url = try #require(WMFShareReadingListDataController.shareURL(siteURL: englishProject.siteURL, pageIDsByLanguageCode: ["en": [736]]))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try #require(components.queryItems)

        #expect(components.host == "en.wikipedia.org")
        #expect(components.path == "/wiki/Special:ReadingLists")
        #expect(queryItems.first?.name == "limport")
        #expect(queryItems.first?.value == WMFShareReadingListDataController.encodedList(pageIDsByLanguageCode: ["en": [736]])?.removingPercentEncoding)
        #expect(queryItems.last == URLQueryItem(name: "wprov", value: "rlsi1"))
    }

    // MARK: - Page IDs

    @Test
    func chunksSplitTitlesInGroupsOfFifty() {
        let titles = (1...120).map { "Title \($0)" }
        let chunks = WMFShareReadingListDataController.chunks(of: titles, size: WMFShareReadingListDataController.maximumTitlesPerRequest)

        #expect(chunks.map(\.count) == [50, 50, 20])
        #expect(chunks.flatMap { $0 } == titles)
    }

    @Test
    func fetchSendsAtMostFiftyTitlesInEachRequest() async throws {
        let service = PageIDsMockService()
        let controller = WMFShareReadingListDataController(basicService: service)
        let pages = (1...51).map { WMFShareReadingListDataController.Page(title: "Title \($0)", project: englishProject) }

        let pageIDsByLanguageCode = try await controller.fetchPageIDsByLanguageCode(for: pages)

        #expect(service.requestedTitles.map(\.count) == [50, 1])
        #expect(pageIDsByLanguageCode["en"]?.count == 51)
    }

    @Test
    func fetchGroupsPageIDsByLanguageCode() async throws {
        let service = PageIDsMockService()
        let controller = WMFShareReadingListDataController(basicService: service)
        let pages = [
            WMFShareReadingListDataController.Page(title: "Title 1", project: englishProject),
            WMFShareReadingListDataController.Page(title: "Title 2", project: spanishProject),
            WMFShareReadingListDataController.Page(title: "Title 3", project: englishProject)
        ]

        let pageIDsByLanguageCode = try await controller.fetchPageIDsByLanguageCode(for: pages)

        #expect(pageIDsByLanguageCode == ["en": [1, 3], "es": [2]])
        #expect(service.requestedHosts == ["en.wikipedia.org", "es.wikipedia.org"])
    }

    @Test
    func fetchSkipsPagesThatAreNotOnAWikipedia() async throws {
        let service = PageIDsMockService()
        let controller = WMFShareReadingListDataController(basicService: service)
        let pages = [
            WMFShareReadingListDataController.Page(title: "Title 1", project: .commons),
            WMFShareReadingListDataController.Page(title: "Title 2", project: englishProject)
        ]

        let pageIDsByLanguageCode = try await controller.fetchPageIDsByLanguageCode(for: pages)

        #expect(pageIDsByLanguageCode == ["en": [2]])
    }

    @Test
    func fetchShareURLThrowsWhenTheAPIFindsNoPages() async throws {
        let service = PageIDsMockService()
        let controller = WMFShareReadingListDataController(basicService: service)
        let pages = [WMFShareReadingListDataController.Page(title: "Missing", project: englishProject)]

        await #expect(throws: WMFShareReadingListDataController.ShareError.self) {
            _ = try await controller.fetchShareURL(for: pages, linkProject: englishProject)
        }
    }
}

/// Answers each title "Title <number>" with the page ID <number>. Other titles are missing pages.
private final class PageIDsMockService: WMFService, @unchecked Sendable {

    private let lock = NSLock()
    private var requests: [WMFBasicServiceRequest] = []

    var requestedTitles: [[String]] {
        lock.withLock { requests }.compactMap { ($0.parameters?["titles"] as? String)?.components(separatedBy: "|") }
    }

    var requestedHosts: [String] {
        lock.withLock { requests }.compactMap { $0.url?.host }
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<Data, Error>) -> Void) {
        completion(.failure(WMFServiceError.missingData))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<[String: Any]?, Error>) -> Void) {
        completion(.failure(WMFServiceError.missingData))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        guard let request = request as? WMFBasicServiceRequest,
              let titles = (request.parameters?["titles"] as? String)?.components(separatedBy: "|") else {
            completion(.failure(WMFServiceError.invalidRequest))
            return
        }
        lock.withLock { requests.append(request) }

        let pages: [[String: Any]] = titles.map { title in
            if let pageID = Int(title.replacingOccurrences(of: "Title ", with: "")) {
                return ["pageid": pageID, "ns": 0, "title": title]
            }
            return ["ns": 0, "title": title, "missing": true]
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: ["batchcomplete": true, "query": ["pages": pages]])
            completion(.success(try JSONDecoder().decode(T.self, from: data)))
        } catch {
            completion(.failure(error))
        }
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        completion(.failure(WMFServiceError.missingData))
    }

    func clearCachedData() {}
}
