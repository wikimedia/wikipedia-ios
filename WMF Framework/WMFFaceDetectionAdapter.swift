import UIKit
import WMFComponents
import CocoaLumberjackSwift

/// Gives the legacy Objective-C image views access to `WMFFaceDetectionCache`.
///
/// Objective-C cannot import a Swift package, so this class forwards the calls and converts the types.
/// It also logs the Vision framework failures, because the logging stays outside of WMFComponents.
@objc(WMFFaceDetectionAdapter) @MainActor public final class WMFFaceDetectionAdapter: NSObject {

    @objc public static let shared = WMFFaceDetectionAdapter()

    private let cache = WMFFaceDetectionCache.shared

    /// Returns `true` if the cache has no result for `url`. An empty result also counts as a result.
    @objc(imageAtURLRequiresFaceDetection:)
    public func imageAtURLRequiresFaceDetection(_ url: URL?) -> Bool {
        return cache.requiresFaceDetection(for: url)
    }

    /// Returns the cached unit rect of the largest face for `url`. Returns `nil` if the cache has no result or the image has no face.
    @objc(faceBoundsForURL:)
    public func faceBounds(for url: URL?) -> NSValue? {
        return cache.cachedFaceBounds(for: url).map { NSValue(cgRect: $0) }
    }

    /// Finds the faces in `image` and stores the result for `url`.
    ///
    /// The `success` callback receives the unit rect of the largest face. It receives `nil` if the image has no face.
    /// If the Vision framework fails, for example because of memory pressure, the callback also receives `nil`. This lets the caller show the image.
    /// After `cancelFaceDetection(for:)`, the adapter calls no callback.
    /// The adapter calls the callbacks on the main actor.
    @objc(detectFaceBoundsInImage:URL:failure:success:)
    public func detectFaceBounds(in image: UIImage, url: URL?, failure: @escaping (Error) -> Void, success: @escaping (NSValue?) -> Void) {
        Task {
            do {
                let faceBounds = try await cache.faceBounds(in: image, for: url)
                success(faceBounds.map { NSValue(cgRect: $0) })
            } catch is CancellationError {
                // The caller cancelled the request. Call no callback.
            } catch WMFFaceDetectionError.missingURL {
                failure(WMFFaceDetectionError.missingURL)
            } catch {
                DDLogWarn("Face detection failed for \(String(describing: url)): \(error)")
                success(nil)
            }
        }
    }

    /// Cancels the most recent active detection for `url`. The adapter calls no callback for that request.
    @objc(cancelFaceDetectionForURL:)
    public func cancelFaceDetection(for url: URL?) {
        cache.cancelFaceDetection(for: url)
    }

    @objc public func clearCache() {
        cache.clearCache()
    }
}
