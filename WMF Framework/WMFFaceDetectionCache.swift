import UIKit
import Vision
import CocoaLumberjackSwift

/// The errors that `WMFFaceDetectionCache` reports.
@objc public enum WMFFaceDetectionError: Int, Error {
    case missingURL = 0
}

/// Finds faces in article images with the Vision framework. `UIImageView` uses the result to center the crop on the largest face.
///
/// Each face rect is a unit rect (0...1) in UIKit coordinates. The origin is the top-left corner.
/// All size variants of one image share the same result. The cache keeps the results in memory only.
@objc @MainActor public final class WMFFaceDetectionCache: NSObject {

    @objc public static let sharedCache = WMFFaceDetectionCache()

    private struct InFlightDetection {
        let token: UUID
        let task: Task<Void, Never>
    }

    /// Returns the unit rects of the faces in an image in UIKit coordinates. The largest face is first.
    typealias Detection = @Sendable (UIImage) async throws -> [CGRect]

    private let boundsCache = NSCache<NSURL, NSArray>()
    private var inFlightDetectionsKeyedByURL: [URL: InFlightDetection] = [:]
    private let detect: Detection

    /// Creates a cache that uses `VNDetectFaceRectanglesRequest`. The requests run one at a time, off the main actor.
    public override convenience init() {
        let detector = WMFFaceDetector()
        self.init(detect: { image in try await detector.unitFaceBounds(in: image) })
    }

    /// Creates a cache with a custom detection function. Use this initializer in tests to replace the Vision framework.
    init(detect: @escaping Detection) {
        self.detect = detect
        super.init()
    }

    // MARK: - Public

    /// Returns `true` if the cache has no result for `url`. An empty result also counts as a result.
    @objc(imageAtURLRequiresFaceDetection:)
    public func imageAtURLRequiresFaceDetection(_ url: URL?) -> Bool {
        return cachedFaceBounds(for: url) == nil
    }

    /// Returns the cached unit rect of the largest face for `url`. Returns `nil` if the cache has no result or the image has no face.
    @objc(faceBoundsForURL:)
    public func faceBounds(for url: URL?) -> NSValue? {
        return cachedFaceBounds(for: url)?.first
    }

    /// Finds the faces in `image` and stores the result for `url`.
    ///
    /// The `success` callback receives the unit rect of the largest face. It receives `nil` if the image has no face.
    /// If the Vision framework fails, for example because of memory pressure, the callback also receives `nil`. This lets the caller show the image.
    /// The cache calls the callbacks on the main actor.
    @objc(detectFaceBoundsInImage:URL:failure:success:)
    public func detectFaceBounds(in image: UIImage, url: URL?, failure: @escaping (Error) -> Void, success: @escaping (NSValue?) -> Void) {
        guard let url else {
            failure(WMFFaceDetectionError.missingURL)
            return
        }

        if let cachedBounds = cachedFaceBounds(for: url) {
            success(cachedBounds.first)
            return
        }

        let token = UUID()
        let detect = self.detect
        let task = Task { [weak self] in
            var faceBounds: [CGRect] = []
            var didSucceed = true
            do {
                faceBounds = try await detect(image)
            } catch {
                didSucceed = false
                DDLogWarn("Face detection failed for \(url): \(error)")
            }

            guard let self, !Task.isCancelled else {
                return
            }

            if self.inFlightDetectionsKeyedByURL[url]?.token == token {
                self.inFlightDetectionsKeyedByURL[url] = nil
            }

            if didSucceed {
                self.cacheFaceBounds(faceBounds, for: url)
            }

            success(faceBounds.first.map { NSValue(cgRect: $0) })
        }

        inFlightDetectionsKeyedByURL[url] = InFlightDetection(token: token, task: task)
    }

    /// Cancels the most recent active detection for `url`. The cache does not call its callbacks.
    @objc(cancelFaceDetectionForURL:)
    public func cancelFaceDetection(for url: URL?) {
        guard let url, let inFlight = inFlightDetectionsKeyedByURL.removeValue(forKey: url) else {
            return
        }
        inFlight.task.cancel()
    }

    @objc public func clearCache() {
        boundsCache.removeAllObjects()
    }

    // MARK: - Coordinate conversion

    /// Converts a Vision bounding box to a unit rect in UIKit coordinates.
    /// The Vision box is normalized and its origin is the bottom-left corner. The UIKit origin is the top-left corner.
    nonisolated public static func unitRectInUIKitCoordinates(fromVisionBoundingBox boundingBox: CGRect) -> CGRect {
        return CGRect(x: boundingBox.minX, y: 1 - boundingBox.maxY, width: boundingBox.width, height: boundingBox.height)
    }

    // MARK: - Cache

    private func cacheFaceBounds(_ bounds: [CGRect], for url: URL) {
        let values = bounds.map { NSValue(cgRect: $0) }
        boundsCache.setObject(values as NSArray, forKey: sizeInvariantCacheKey(for: url))
    }

    private func cachedFaceBounds(for url: URL?) -> [NSValue]? {
        guard let url else {
            return nil
        }
        return boundsCache.object(forKey: sizeInvariantCacheKey(for: url)) as? [NSValue]
    }

    /// Returns the cache key for `url`. Face rects are unit rects, so all size variants of one image share one cache entry.
    /// The key is not a valid image URL. The key only has to be unique for each host and image name.
    private func sizeInvariantCacheKey(for url: URL) -> NSURL {
        guard let imageName = WMFParseImageNameFromSourceURL(url.absoluteString),
              let host = url.host,
              let key = URL(string: "\(host)/\(imageName)") else {
            return url as NSURL
        }
        return key as NSURL
    }
}

/// Runs Vision face detection off the main actor. The actor runs one request at a time.
private actor WMFFaceDetector {

    func unitFaceBounds(in image: UIImage) throws -> [CGRect] {
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let handler: VNImageRequestHandler
        if let cgImage = image.cgImage {
            handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        } else if let ciImage = image.ciImage {
            handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation, options: [:])
        } else {
            return []
        }

        let request = VNDetectFaceRectanglesRequest()
        try handler.perform([request])

        let observations = request.results ?? []
        return observations
            .map { WMFFaceDetectionCache.unitRectInUIKitCoordinates(fromVisionBoundingBox: $0.boundingBox) }
            .sorted { $0.width * $0.height > $1.width * $1.height }
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
