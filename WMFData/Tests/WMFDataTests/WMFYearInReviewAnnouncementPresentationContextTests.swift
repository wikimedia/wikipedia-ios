import XCTest
@testable import WMFData

final class WMFYearInReviewAnnouncementPresentationContextTests: XCTestCase {

    typealias Context = WMFYearInReviewDataController.AnnouncementPresentationContext

    func testHomeAllowsAnnouncementWhenNotFromDeepLink() {
        XCTAssertTrue(Context.home(isFromDeepLink: false).allowsAnnouncement)
    }

    func testHomeBlocksAnnouncementWhenFromDeepLink() {
        XCTAssertFalse(Context.home(isFromDeepLink: true).allowsAnnouncement)
    }

    func testExploreAllowsAnnouncementWhenNotFromDeepLink() {
        XCTAssertTrue(Context.explore(isFromDeepLink: false).allowsAnnouncement)
    }

    func testExploreBlocksAnnouncementWhenFromDeepLink() {
        XCTAssertFalse(Context.explore(isFromDeepLink: true).allowsAnnouncement)
    }
}

