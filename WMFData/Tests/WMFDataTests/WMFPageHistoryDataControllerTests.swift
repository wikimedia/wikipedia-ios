import XCTest

@testable import WMFData
@testable import WMFDataMocks

final class WMFPageHistoryDataControllerTests: XCTestCase {

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func controller(fixture: String) -> WMFPageHistoryDataController {
        WMFPageHistoryDataController(basicService: WMFMockBasicService(jsonResourceName: fixture))
    }

    // MARK: - Decoding

    func testFetchRevisionsDecodesPage() async throws {
        let page = try await controller(fixture: "page-revisions-cat-get").fetchRevisions(project: enProject, title: "Cat")

        XCTAssertEqual(page.title, "Cat")
        XCTAssertEqual(page.revisions.count, 7)
        XCTAssertEqual(page.continueToken, "||")
        XCTAssertEqual(page.rvContinueToken, "20260820090000|1370800002")
        XCTAssertFalse(page.batchComplete)
    }

    func testFetchRevisionsDecodesFields() async throws {
        let page = try await controller(fixture: "page-revisions-cat-get").fetchRevisions(project: enProject, title: "Cat")
        let second = page.revisions[1]

        XCTAssertEqual(second.revisionID, 1372337812)
        XCTAssertEqual(second.parentID, 1371757525)
        XCTAssertEqual(second.user, "OAbot")
        XCTAssertTrue(second.isMinor)
        XCTAssertFalse(second.isAnon)
        XCTAssertFalse(second.isTemp)
        XCTAssertEqual(second.articleSizeAtRevision, 171776)
        XCTAssertEqual(second.parsedComment?.contains("Open access bot"), true)

        let expectedDate = DateFormatter.mediaWikiAPIDateFormatter.date(from: "2026-08-31T09:08:02Z")
        XCTAssertEqual(second.revisionDate, expectedDate)
    }

    func testFetchRevisionsDecodesUserFlags() async throws {
        let page = try await controller(fixture: "page-revisions-cat-get").fetchRevisions(project: enProject, title: "Cat")

        let anonymous = page.revisions[5]
        XCTAssertTrue(anonymous.isAnon)
        XCTAssertFalse(anonymous.isTemp)

        let temporary = page.revisions[6]
        XCTAssertTrue(temporary.isTemp)
        XCTAssertFalse(temporary.isAnon)
    }

    // MARK: - Size differences

    func testFetchRevisionsSetsSizeDifferences() async throws {
        let page = try await controller(fixture: "page-revisions-cat-get").fetchRevisions(project: enProject, title: "Cat")

        XCTAssertEqual(page.revisions[0].revisionSize, 0)      // 171776 - 171776
        XCTAssertEqual(page.revisions[1].revisionSize, 102)    // 171776 - 171674
        XCTAssertEqual(page.revisions[2].revisionSize, -1)     // 171674 - 171675
        XCTAssertEqual(page.revisions[5].revisionSize, 100)    // 171600 - 171500
        XCTAssertEqual(page.revisions[6].revisionSize, 0, "The last revision has no parent size in this page")
    }

    func testSetRevisionSizesGivesFullSizeToFirstRevision() {
        var revisions = [
            WMFPageRevision(revisionID: 2, parentID: 1, user: nil, revisionDate: nil, parsedComment: nil, isAnon: false, isMinor: false, isTemp: false, articleSizeAtRevision: 30),
            WMFPageRevision(revisionID: 1, parentID: 0, user: nil, revisionDate: nil, parsedComment: nil, isAnon: false, isMinor: false, isTemp: false, articleSizeAtRevision: 20)
        ]
        WMFPageHistoryDataController.setRevisionSizes(&revisions)

        XCTAssertEqual(revisions[0].revisionSize, 10)
        XCTAssertEqual(revisions[1].revisionSize, 20)
    }

    func testSetRevisionSizesAcceptsEmptyArray() {
        var revisions: [WMFPageRevision] = []
        WMFPageHistoryDataController.setRevisionSizes(&revisions)
        XCTAssertTrue(revisions.isEmpty)
    }

    // MARK: - Convenience fetches

    func testFetchFirstRevision() async throws {
        let revision = try await controller(fixture: "page-revisions-first-get").fetchFirstRevision(project: enProject, title: "Cat")

        XCTAssertEqual(revision.revisionID, 233192)
        XCTAssertEqual(revision.parentID, 0)
        XCTAssertEqual(revision.revisionSize, 2412, "The first revision has its full size as the size difference")
    }

    func testFetchAdjacentRevisionSkipsSourceRevision() async throws {
        let revision = try await controller(fixture: "page-revisions-cat-get").fetchAdjacentRevision(project: enProject, title: "Cat", revisionID: 1372757331, direction: .older)

        XCTAssertEqual(revision.revisionID, 1372337812)
    }

    func testFetchLatestRevisionID() async throws {
        let revisionID = try await controller(fixture: "page-revisions-cat-get").fetchLatestRevisionID(project: enProject, title: "Cat")

        XCTAssertEqual(revisionID, 1372757331)
    }

    func testFetchWithoutServiceThrows() async {
        let controller = WMFPageHistoryDataController(basicService: nil)
        do {
            _ = try await controller.fetchFirstRevision(project: enProject, title: "Cat")
            XCTFail("Expected an error")
        } catch {
            guard case WMFDataControllerError.basicServiceUnavailable = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    // MARK: - Dates

    func testDaysFromToday() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let revision = WMFPageRevision(revisionID: 1, parentID: 0, user: nil, revisionDate: threeDaysAgo, parsedComment: nil, isAnon: false, isMinor: false, isTemp: false, articleSizeAtRevision: 0)

        XCTAssertEqual(revision.daysFromToday(now: now), 3)
    }

    func testCodableRoundTrip() throws {
        let date = DateFormatter.mediaWikiAPIDateFormatter.date(from: "2026-08-31T09:08:02Z")
        let revision = WMFPageRevision(revisionID: 5, parentID: 4, user: "Someone", revisionDate: date, parsedComment: "fix", isAnon: false, isMinor: true, isTemp: false, articleSizeAtRevision: 10, revisionSize: 3)

        let data = try JSONEncoder().encode(revision)
        var decoded = try JSONDecoder().decode(WMFPageRevision.self, from: data)
        decoded.revisionSize = 3

        XCTAssertEqual(decoded, revision)
    }
}
