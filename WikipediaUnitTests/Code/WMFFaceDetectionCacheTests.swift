import XCTest
@testable import WMF

@MainActor
final class WMFFaceDetectionCacheTests: XCTestCase {

    private struct StubError: Error {}

    private let smallVariantURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Example.jpg/320px-Example.jpg")!
    private let largeVariantURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Example.jpg/640px-Example.jpg")!

    private func detectFaceBounds(using cache: WMFFaceDetectionCache, url: URL?) async -> Result<NSValue?, Error> {
        await withCheckedContinuation { continuation in
            cache.detectFaceBounds(in: UIImage(), url: url, failure: { error in
                continuation.resume(returning: .failure(error))
            }, success: { value in
                continuation.resume(returning: .success(value))
            })
        }
    }

    func testVisionBoundingBoxIsFlippedIntoUIKitCoordinates() {
        // The Vision box is normalized and its origin is the bottom-left corner. This face is in the top-left quarter of the image.
        let visionBox = CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5)
        let uiKitRect = WMFFaceDetectionCache.unitRectInUIKitCoordinates(fromVisionBoundingBox: visionBox)
        XCTAssertEqual(uiKitRect, CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
    }

    func testVisionBoundingBoxNearBottomMapsToLargeUIKitY() {
        let visionBox = CGRect(x: 0.25, y: 0.1, width: 0.2, height: 0.3)
        let uiKitRect = WMFFaceDetectionCache.unitRectInUIKitCoordinates(fromVisionBoundingBox: visionBox)
        XCTAssertEqual(uiKitRect.minX, 0.25, accuracy: 0.0001)
        XCTAssertEqual(uiKitRect.minY, 0.6, accuracy: 0.0001)
        XCTAssertEqual(uiKitRect.width, 0.2, accuracy: 0.0001)
        XCTAssertEqual(uiKitRect.height, 0.3, accuracy: 0.0001)
    }

    func testMissingURLReportsFailure() async {
        let cache = WMFFaceDetectionCache(detect: { _ in [] })
        let result = await detectFaceBounds(using: cache, url: nil)
        guard case .failure(let error) = result else {
            return XCTFail("Detection without a URL must fail")
        }
        XCTAssertEqual(error as? WMFFaceDetectionError, .missingURL)
    }

    func testDetectedFaceIsReturnedAndCachedAcrossSizeVariants() async {
        let face = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.3)
        let detectionCount = Counter()
        let cache = WMFFaceDetectionCache(detect: { _ in
            await detectionCount.increment()
            return [face]
        })

        XCTAssertTrue(cache.imageAtURLRequiresFaceDetection(smallVariantURL))

        let result = await detectFaceBounds(using: cache, url: smallVariantURL)
        XCTAssertEqual(try result.get()?.cgRectValue, face)

        XCTAssertFalse(cache.imageAtURLRequiresFaceDetection(smallVariantURL))
        XCTAssertFalse(cache.imageAtURLRequiresFaceDetection(largeVariantURL), "All size variants must share one cache entry")
        XCTAssertEqual(cache.faceBounds(for: largeVariantURL)?.cgRectValue, face)

        // The cache answers the second request for a size variant. It does not run detection again.
        let cachedResult = await detectFaceBounds(using: cache, url: largeVariantURL)
        XCTAssertEqual(try cachedResult.get()?.cgRectValue, face)
        let count = await detectionCount.value
        XCTAssertEqual(count, 1)
    }

    func testImageWithoutFacesCachesEmptyResult() async {
        let cache = WMFFaceDetectionCache(detect: { _ in [] })

        let result = await detectFaceBounds(using: cache, url: smallVariantURL)
        XCTAssertNil(try result.get())
        XCTAssertFalse(cache.imageAtURLRequiresFaceDetection(smallVariantURL))
        XCTAssertNil(cache.faceBounds(for: smallVariantURL))
    }

    func testDetectionFailureFallsBackToNoFaceWithoutCaching() async {
        let cache = WMFFaceDetectionCache(detect: { _ in throw StubError() })

        let result = await detectFaceBounds(using: cache, url: smallVariantURL)
        XCTAssertNil(try result.get(), "After a Vision failure, the caller must show the image without a face crop")
        XCTAssertTrue(cache.imageAtURLRequiresFaceDetection(smallVariantURL), "The cache must not store failures")
    }

    func testCancelledDetectionDoesNotCallBack() async {
        let cache = WMFFaceDetectionCache(detect: { _ in
            try await Task.sleep(nanoseconds: 100_000_000)
            return [CGRect(x: 0, y: 0, width: 0.5, height: 0.5)]
        })

        let callbackExpectation = expectation(description: "The cache calls no callbacks after cancellation")
        callbackExpectation.isInverted = true
        cache.detectFaceBounds(in: UIImage(), url: smallVariantURL, failure: { _ in
            callbackExpectation.fulfill()
        }, success: { _ in
            callbackExpectation.fulfill()
        })
        cache.cancelFaceDetection(for: smallVariantURL)

        await fulfillment(of: [callbackExpectation], timeout: 0.5)
        XCTAssertTrue(cache.imageAtURLRequiresFaceDetection(smallVariantURL))
    }
}

private actor Counter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}
