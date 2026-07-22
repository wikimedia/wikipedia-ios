import UIKit
import ImageIO

extension UIImage {
    /// Widget extensions have a ~30MB memory ceiling, so full-size UIImage(data:)
    /// decodes can get the process jetsammed. This decodes via ImageIO at (or near)
    /// the target size; sources much larger than the target are decoded subsampled,
    /// so their full-size bitmap is never materialized. Results may land slightly
    /// below the target — the rendering view's scaledToFill covers the difference.
    static func downsampled(from data: Data, targetSize: CGSize) -> UIImage? {
        guard targetSize.width > 0, targetSize.height > 0 else { return nil }
        
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }

        let maxPixelSize = max(targetSize.width, targetSize.height)

        // Header-only read, no decode
        var pixelWidth: CGFloat = 0
        var pixelHeight: CGFloat = 0
        if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            pixelWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat ?? 0
            pixelHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat ?? 0
        }

        // JPEG can only decode cheaply at 1/2, 1/4, 1/8 of full size. When the target
        // is more than half the source, CreateThumbnailAtIndex decodes the full-size
        // bitmap transiently — enough to breach the widget extension's ~30MB limit for
        // large portrait images. It also ignores kCGImageSourceSubsampleFactor;
        // CreateImageAtIndex honors it, so use that when the source is much larger
        // than the target. The resulting image may land slightly below the target;
        // the view's scaledToFill covers the difference.
        let ratio = max(pixelWidth, pixelHeight) / maxPixelSize
        if ratio >= 1.5 {
            let factor = ratio >= 6 ? 8 : (ratio >= 3 ? 4 : 2)
            let imageOptions = [
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceSubsampleFactor: factor
            ] as CFDictionary
            if let cgImage = CGImageSourceCreateImageAtIndex(source, 0, imageOptions) {
                return UIImage(cgImage: cgImage)
            }
            // Formats that don't support subsampling fall through to the thumbnail path.
        }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}
