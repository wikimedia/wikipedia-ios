import UIKit
import WMFData

extension UIImage {
    /// The largest square of the image centered on the face, clamped to the image bounds.
    nonisolated static func squareCropRect(imageSize: CGSize, faceUnitRect: CGRect) -> CGRect {
        let side = min(imageSize.width, imageSize.height)
        let faceCenter = CGPoint(x: faceUnitRect.midX * imageSize.width, y: faceUnitRect.midY * imageSize.height)
        let x = min(max(0, faceCenter.x - side / 2), imageSize.width - side)
        let y = min(max(0, faceCenter.y - side / 2), imageSize.height - side)

        return CGRect(x: x, y: y, width: side, height: side)
    }

    /// A square crop around the face. Returns the image unchanged when it cannot be cropped.
    nonisolated func croppedToSquare(around faceUnitRect: CGRect) -> UIImage {
        guard imageOrientation == .up, let cgImage else {
            return self
        }
        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        let cropRect = Self.squareCropRect(imageSize: pixelSize, faceUnitRect: faceUnitRect)
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return self
        }

        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: .up)
    }

    /// Loads an image and, when it shows a face, crops a square around it, like the legacy
    /// `wmf_setImage(with:detectFaces:)`.
    nonisolated static func loadFaceCropped(from url: URL) async -> UIImage? {
        guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url),
              let image = UIImage(data: data) else {
            return nil
        }
        guard let faceUnitRect = try? await WMFFaceDetectionCache.shared.faceBounds(in: image, for: url) else {
            return image
        }
        return image.croppedToSquare(around: faceUnitRect)
    }
}
