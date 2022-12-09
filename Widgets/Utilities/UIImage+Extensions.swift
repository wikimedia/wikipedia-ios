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

}
