import XCTest
@testable import WMFData

final class ImageUtilsTests: XCTestCase {

    func testNamedWidthAccessorsReturnExpectedValues() {
        XCTAssertEqual(ImageUtils.listThumbnailWidth(), 120)
        XCTAssertEqual(ImageUtils.nearbyThumbnailWidth(), 250)
        XCTAssertEqual(ImageUtils.leadImageWidth(), 1280)
        XCTAssertEqual(ImageUtils.potdImageWidth(), 500)
        XCTAssertEqual(ImageUtils.galleryImageWidth(), 1280)
        XCTAssertEqual(ImageUtils.articleImageWidth(), 500)
    }

    func testImageWidthRawValues() {
        XCTAssertEqual(ImageUtils.ImageWidth.w20.rawValue, 20)
        XCTAssertEqual(ImageUtils.ImageWidth.w120.rawValue, 120)
        XCTAssertEqual(ImageUtils.ImageWidth.w500.rawValue, 500)
        XCTAssertEqual(ImageUtils.ImageWidth.w3840.rawValue, 3840)
    }

    func testStandardizeWidthExactMatchesAreUnchanged() {
        for width in [20, 40, 60, 120, 250, 330, 500, 960, 1280, 1920, 3840] {
            XCTAssertEqual(ImageUtils.standardizeWidthToMediaWiki(width), width, "Exact standard width \(width) should be returned unchanged")
        }
    }

    func testStandardizeWidthRoundsUpToNextStandard() {
        XCTAssertEqual(ImageUtils.standardizeWidthToMediaWiki(1), 20)
        XCTAssertEqual(ImageUtils.standardizeWidthToMediaWiki(10), 20)
        XCTAssertEqual(ImageUtils.standardizeWidthToMediaWiki(21), 40)
        XCTAssertEqual(ImageUtils.standardizeWidthToMediaWiki(100), 120)
        XCTAssertEqual(ImageUtils.standardizeWidthToMediaWiki(121), 250)
        XCTAssertEqual(ImageUtils.standardizeWidthToMediaWiki(501), 960)
    }

    func testStandardizeWidthAboveMaximumClampsToLargest() {
        XCTAssertEqual(ImageUtils.standardizeWidthToMediaWiki(3841), 3840)
        XCTAssertEqual(ImageUtils.standardizeWidthToMediaWiki(10000), 3840)
    }

    func testStandardizeWidthZeroAndNegativeClampToSmallest() {
        XCTAssertEqual(ImageUtils.standardizeWidthToMediaWiki(0), 20)
        XCTAssertEqual(ImageUtils.standardizeWidthToMediaWiki(-100), 20)
    }
}
