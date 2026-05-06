import UIKit
import AVFoundation

extension UIImage {

    /// Scale image to fit within target size while maintaining aspect ratio
    func scaleImageToFit(targetSize: CGSize) -> UIImage? {
        let aspectRatioRect = AVFoundation.AVMakeRect(aspectRatio: size, insideRect: CGRect(origin: .zero, size: targetSize))
        let availableSize = aspectRatioRect.size

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: availableSize, format: format)
        let resizedImage = renderer.image { context in
            draw(in: CGRect(origin: .zero, size: availableSize))
        }

        return resizedImage
    }

    func scaleImageToFill(targetSize: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0,
              targetSize.width > 0, targetSize.height > 0 else { return nil }

        let widthScale = targetSize.width / size.width
        let heightScale = targetSize.height / size.height
        let fillScale = min(max(widthScale, heightScale), 1.0)
        let scaledSize = CGSize(width: size.width * fillScale, height: size.height * fillScale)
        let drawOrigin = CGPoint(
            x: (targetSize.width - scaledSize.width) / 2,
            y: (targetSize.height - scaledSize.height) / 2
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: drawOrigin, size: scaledSize))
        }
    }

}
