import Testing
import UIKit
import Vision
@testable import WMFComponents

/// The face rects behind the image crops. The coordinate flip and the size-variant cache key are the parts that must not regress.
@MainActor
@Suite
struct WMFFaceDetectionCacheTests {

    private struct StubError: Error {}

    private let smallVariantURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Example.jpg/320px-Example.jpg")!
    private let largeVariantURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Example.jpg/640px-Example.jpg")!
    private let fullImageURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/a/ab/Example.jpg")!

    // MARK: - Request revision

    /// Revision 1 is the legacy FaceCore detector that crashed the app. The pin must stay, and the framework must still support revision 3.
    @Test
    func requestPinsTheMachineLearningRevision() {
        let request = WMFFaceDetector.makeFaceRectanglesRequest()
        #expect(request.revision == VNDetectFaceRectanglesRequestRevision3)
        #expect(VNDetectFaceRectanglesRequest.supportedRevisions.contains(VNDetectFaceRectanglesRequestRevision3))
    }

    // MARK: - Coordinate conversion

    @Test
    func visionBoundingBoxIsFlippedIntoUIKitCoordinates() {
        // The Vision box is normalized and its origin is the bottom-left corner. This face is in the top-left quarter of the image.
        let visionBox = CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5)
        let uiKitRect = WMFFaceDetectionCache.unitRectInUIKitCoordinates(fromVisionBoundingBox: visionBox)
        #expect(uiKitRect == CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
    }

    @Test
    func visionBoundingBoxNearBottomMapsToLargeUIKitY() {
        let visionBox = CGRect(x: 0.25, y: 0.1, width: 0.2, height: 0.3)
        let uiKitRect = WMFFaceDetectionCache.unitRectInUIKitCoordinates(fromVisionBoundingBox: visionBox)
        #expect(abs(uiKitRect.minX - 0.25) < 0.0001)
        #expect(abs(uiKitRect.minY - 0.6) < 0.0001)
        #expect(abs(uiKitRect.width - 0.2) < 0.0001)
        #expect(abs(uiKitRect.height - 0.3) < 0.0001)
    }

    // MARK: - Detection and cache

    @Test
    func missingURLReportsFailure() async {
        let cache = WMFFaceDetectionCache(detect: { _ in [] })
        await #expect(throws: WMFFaceDetectionError.missingURL) {
            try await cache.faceBounds(in: UIImage(), for: nil)
        }
    }

    @Test
    func detectedFaceIsReturnedAndCachedAcrossSizeVariants() async throws {
        let face = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.3)
        let detectionCount = Counter()
        let cache = WMFFaceDetectionCache(detect: { _ in
            await detectionCount.increment()
            return [face]
        })

        #expect(cache.requiresFaceDetection(for: smallVariantURL))

        let bounds = try await cache.faceBounds(in: UIImage(), for: smallVariantURL)
        #expect(bounds == face)

        #expect(!cache.requiresFaceDetection(for: smallVariantURL))
        // All size variants must share one cache entry.
        #expect(!cache.requiresFaceDetection(for: largeVariantURL))
        #expect(cache.cachedFaceBounds(for: largeVariantURL) == face)
        // The full image URL has no size prefix, and it must share the entry too.
        #expect(cache.cachedFaceBounds(for: fullImageURL) == face)

        // The cache answers the second request for a size variant. It does not run detection again.
        let cachedBounds = try await cache.faceBounds(in: UIImage(), for: largeVariantURL)
        #expect(cachedBounds == face)
        #expect(await detectionCount.value == 1)
    }

    @Test
    func largestFaceComesFirst() async throws {
        let smallFace = CGRect(x: 0.7, y: 0.1, width: 0.1, height: 0.1)
        let largeFace = CGRect(x: 0.1, y: 0.1, width: 0.4, height: 0.4)
        let cache = WMFFaceDetectionCache(detect: { _ in [largeFace, smallFace] })

        let bounds = try await cache.faceBounds(in: UIImage(), for: smallVariantURL)
        #expect(bounds == largeFace)
    }

    @Test
    func imageWithoutFacesCachesEmptyResult() async throws {
        let cache = WMFFaceDetectionCache(detect: { _ in [] })

        let bounds = try await cache.faceBounds(in: UIImage(), for: smallVariantURL)
        #expect(bounds == nil)
        #expect(!cache.requiresFaceDetection(for: smallVariantURL))
        #expect(cache.cachedFaceBounds(for: smallVariantURL) == nil)
    }

    @Test
    func detectionFailureThrowsAndCachesNothing() async {
        let cache = WMFFaceDetectionCache(detect: { _ in throw StubError() })

        await #expect(throws: StubError.self) {
            try await cache.faceBounds(in: UIImage(), for: smallVariantURL)
        }
        // The cache must not store failures.
        #expect(cache.requiresFaceDetection(for: smallVariantURL))
    }

    @Test
    func cancelledDetectionThrowsCancellationAndCachesNothing() async {
        let cache = WMFFaceDetectionCache(detect: { _ in
            try await Task.sleep(nanoseconds: 50_000_000)
            return [CGRect(x: 0, y: 0, width: 0.5, height: 0.5)]
        })

        let detection = Task { try await cache.faceBounds(in: UIImage(), for: smallVariantURL) }
        // Let the detection task start before the cancellation.
        try? await Task.sleep(nanoseconds: 10_000_000)
        cache.cancelFaceDetection(for: smallVariantURL)

        await #expect(throws: CancellationError.self) {
            try await detection.value
        }
        #expect(cache.requiresFaceDetection(for: smallVariantURL))
    }
}

private actor Counter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}
