import UIKit
import Vision

/// The errors that `WMFFaceDetectionCache` reports.
public enum WMFFaceDetectionError: Error {
    case missingURL
}

/// Finds faces in article images with the Vision framework. A caller uses the result to center an image crop on the largest face.
///
/// Each face rect is a unit rect (0...1) in UIKit coordinates. The origin is the top-left corner.
/// All size variants of one image share the same result. The cache keeps the results in memory only.
@MainActor
public final class WMFFaceDetectionCache {

    public static let shared = WMFFaceDetectionCache()

    /// Returns the unit rects of the faces in an image in UIKit coordinates. The largest face is first.
    typealias Detection = @Sendable (UIImage) async throws -> [CGRect]

    private struct ActiveDetection {
        let token: UUID
        let task: Task<[CGRect], Error>
    }

    private let boundsCache = NSCache<NSString, NSArray>()
    private var activeDetectionsKeyedByURL: [URL: ActiveDetection] = [:]
    private let detect: Detection

    /// Creates a cache that uses `VNDetectFaceRectanglesRequest`. The requests run one at a time, off the main actor.
    public convenience init() {
        let detector = WMFFaceDetector()
        self.init(detect: { image in try await detector.unitFaceBounds(in: image) })
    }

    /// Creates a cache with a custom detection function. Use this initializer in tests to replace the Vision framework.
    init(detect: @escaping Detection) {
        self.detect = detect
    }

    // Releases the stored properties away from the main actor, instead of through
    // the isolated deinit this class would implicitly get under the module's default
    // MainActor isolation. See the longer note in WMFComponentHostingController.
    nonisolated deinit {}

    // MARK: - Public

    /// Returns `true` if the cache has no result for `url`. An empty result also counts as a result.
    public func requiresFaceDetection(for url: URL?) -> Bool {
        return cachedFaceBoundsList(for: url) == nil
    }

    /// Returns the cached unit rect of the largest face for `url`. Returns `nil` if the cache has no result or the image has no face.
    public func cachedFaceBounds(for url: URL?) -> CGRect? {
        return cachedFaceBoundsList(for: url)?.first
    }

    /// Finds the faces in `image` and stores the result for `url`.
    ///
    /// Returns the unit rect of the largest face. Returns `nil` if the image has no face.
    /// Throws `WMFFaceDetectionError.missingURL` if `url` is `nil`. Throws `CancellationError` after `cancelFaceDetection(for:)`.
    /// The method also rethrows a Vision framework error. The cache stores no result for a failure.
    public func faceBounds(in image: UIImage, for url: URL?) async throws -> CGRect? {
        guard let url else {
            throw WMFFaceDetectionError.missingURL
        }

        if let cachedBounds = cachedFaceBoundsList(for: url) {
            return cachedBounds.first
        }

        let token = UUID()
        let detect = self.detect
        let task = Task { () throws -> [CGRect] in
            let faceBounds = try await detect(image)
            // The task returns the faces of a cancelled request to nobody. Stop here instead.
            try Task.checkCancellation()
            return faceBounds
        }
        activeDetectionsKeyedByURL[url] = ActiveDetection(token: token, task: task)

        defer {
            if activeDetectionsKeyedByURL[url]?.token == token {
                activeDetectionsKeyedByURL[url] = nil
            }
        }

        let faceBounds = try await task.value
        cacheFaceBounds(faceBounds, for: url)
        return faceBounds.first
    }

    /// Cancels the most recent active detection for `url`. The call to `faceBounds(in:for:)` then throws `CancellationError`.
    public func cancelFaceDetection(for url: URL?) {
        guard let url, let activeDetection = activeDetectionsKeyedByURL.removeValue(forKey: url) else {
            return
        }
        activeDetection.task.cancel()
    }

    public func clearCache() {
        boundsCache.removeAllObjects()
    }

    // MARK: - Coordinate conversion

    /// Converts a Vision bounding box to a unit rect in UIKit coordinates.
    /// The Vision box is normalized and its origin is the bottom-left corner. The UIKit origin is the top-left corner.
    nonisolated public static func unitRectInUIKitCoordinates(fromVisionBoundingBox boundingBox: CGRect) -> CGRect {
        return CGRect(x: boundingBox.minX, y: 1 - boundingBox.maxY, width: boundingBox.width, height: boundingBox.height)
    }

    // MARK: - Cache

    private func cacheFaceBounds(_ faceBounds: [CGRect], for url: URL) {
        let values = faceBounds.map { NSValue(cgRect: $0) }
        boundsCache.setObject(values as NSArray, forKey: Self.sizeInvariantCacheKey(for: url))
    }

    private func cachedFaceBoundsList(for url: URL?) -> [CGRect]? {
        guard let url else {
            return nil
        }
        guard let values = boundsCache.object(forKey: Self.sizeInvariantCacheKey(for: url)) as? [NSValue] else {
            return nil
        }
        return values.map { $0.cgRectValue }
    }

    /// Returns the cache key for `url`. Face rects are unit rects, so all size variants of one image share one cache entry.
    /// The key is not a valid image URL. The key only has to be unique for each host and image name.
    private static func sizeInvariantCacheKey(for url: URL) -> NSString {
        let urlString = url.absoluteString
        let pathComponents = urlString.components(separatedBy: "/")
        guard let host = url.host, pathComponents.count >= 2 else {
            return urlString as NSString
        }

        // A thumbnail URL ends with a size prefix, for example ".../Example.jpg/320px-Example.jpg".
        // The component before the last one is the name of the full image.
        let imageName = urlString.contains("/thumb/") ? pathComponents[pathComponents.count - 2] : url.lastPathComponent
        return "\(host)/\(imageName)" as NSString
    }
}

/// Runs Vision face detection off the main actor. The actor runs one request at a time.
actor WMFFaceDetector {

    /// Makes a face detection request that is pinned to revision 3.
    ///
    /// Revision 3 uses the machine learning detector. Revision 1 uses the legacy FaceCore detector, which
    /// crashed the app in libfaceCore.dylib. Apple deprecated revision 1 in iOS 16, but the framework still
    /// supports it, so the pin stops a change of the default revision from selecting it again.
    /// `WMFFaceDetectionCacheTests` checks that the framework still supports revision 3.
    nonisolated static func makeFaceRectanglesRequest() -> VNDetectFaceRectanglesRequest {
        let request = VNDetectFaceRectanglesRequest()
        request.revision = VNDetectFaceRectanglesRequestRevision3
        return request
    }

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

        let request = Self.makeFaceRectanglesRequest()
        try handler.perform([request])

        let observations = request.results ?? []
        return observations
            .map { WMFFaceDetectionCache.unitRectInUIKitCoordinates(fromVisionBoundingBox: $0.boundingBox) }
            .sorted { $0.width * $0.height > $1.width * $1.height }
    }
}

// The module defaults every declaration to MainActor isolation. This conversion needs no isolation,
// because the detector actor calls it.
private extension CGImagePropertyOrientation {
    nonisolated init(_ orientation: UIImage.Orientation) {
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
