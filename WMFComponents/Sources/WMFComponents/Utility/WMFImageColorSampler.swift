import SwiftUI
import UIKit
import ImageIO

/// Picks a background colour from a photograph that white text stays readable on.
actor WMFImageColorSampler {

    static let shared = WMFImageColorSampler()

    // MARK: - Tuning

    /// Contrast the resulting colour must reach against white text.
    private static let whiteTextContrastTarget: CGFloat = 5

    /// Ceiling for the brightest channel, so a vivid hue cannot overpower the photograph.
    private static let maxBrightness: CGFloat = 0.55

    /// Read one pixel in every `samplingStride` x `samplingStride` block rather than all of them.
    private static let samplingStride = 2

    /// The maximum length of the longest side of the decoded image.
    private static let samplingMaxPixelSize = 128

    private static let colorCacheLimit = 24
    private var colorCache: [Data: Color] = [:]
    private var colorCacheInsertionOrder: [Data] = []

    // MARK: - Public

    /// Takes image `Data` rather than a `UIImage` because `UIImage` is not `Sendable` and so cannot
    /// be handed to another concurrency domain. The image is decoded here instead.
    func sampledColor(from imageData: Data) -> Color? {
        if let cachedColor = colorCache[imageData] {
            return cachedColor
        }

        guard let cgImage = Self.downsampledCGImage(from: imageData) else { return nil }
        guard let color = Self.sampledColor(from: cgImage) else { return nil }

        colorCache[imageData] = color
        colorCacheInsertionOrder.append(imageData)
        if colorCacheInsertionOrder.count > Self.colorCacheLimit {
            let oldestKey = colorCacheInsertionOrder.removeFirst()
            colorCache[oldestKey] = nil
        }

        return color
    }

    private static func downsampledCGImage(from imageData: Data) -> CGImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(imageData as CFData, sourceOptions) else {
            return nil
        }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: samplingMaxPixelSize
        ] as [CFString: Any] as CFDictionary
        return CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions)
    }

    // MARK: - Image sampling algorithm

    static func sampledColor(from image: UIImage) -> Color? {
        guard let cgImage = image.cgImage else { return nil }
        return sampledColor(from: cgImage)
    }

    static func sampledColor(from cgImage: CGImage) -> Color? {
        guard let totals = pixelTotals(of: cgImage), totals.count > 0 else {
            return nil
        }

        var r: CGFloat
        var g: CGFloat
        var b: CGFloat

        if totals.weight > 0 {
            r = totals.weightedR / totals.weight
            g = totals.weightedG / totals.weight
            b = totals.weightedB / totals.weight
        } else {
            // Nothing colourful at all - greyscale, or fully transparent. Fall back to a plain
            // average, halved, so these images settle on a neutral dark rather than an invented hue.
            let pixelCount = CGFloat(totals.count)
            r = (totals.plainR / pixelCount) * 0.5
            g = (totals.plainG / pixelCount) * 0.5
            b = (totals.plainB / pixelCount) * 0.5
        }

        (r, g, b) = darkenToMeetContrast(r: r, g: g, b: b, targetRatio: whiteTextContrastTarget)
        return Color(red: r, green: g, blue: b)
    }

    /// What one pass over the image collected.
    private struct PixelTotals {
        /// Sums weighted by how colourful each pixel is.
        var weightedR: CGFloat = 0
        var weightedG: CGFloat = 0
        var weightedB: CGFloat = 0
        var weight: CGFloat = 0

        /// Unweighted sums, used only when nothing in the image is colourful.
        var plainR: CGFloat = 0
        var plainG: CGFloat = 0
        var plainB: CGFloat = 0

        var count = 0
    }

    /// Draws the image into a pixel buffer and walks it once.
    private static func pixelTotals(of cgImage: CGImage) -> PixelTotals? {
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)

        return rawData.withUnsafeMutableBytes { buffer -> PixelTotals? in
            guard let baseAddress = buffer.baseAddress else { return nil }

            guard let context = CGContext(
                data: baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return nil }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

            // Colourful pixels count for more than dull ones, so a small vivid area beats a large
            // flat one. Squaring the saturation sharpens that preference.
            var totals = PixelTotals()
            let step = samplingStride * bytesPerPixel

            for y in stride(from: 0, to: height, by: samplingStride) {
                let rowStart = y * bytesPerRow
                for i in stride(from: rowStart, to: rowStart + bytesPerRow, by: step) {
                    let r = CGFloat(buffer[i]) / 255
                    let g = CGFloat(buffer[i + 1]) / 255
                    let b = CGFloat(buffer[i + 2]) / 255

                    let maxC = max(r, g, b)
                    let minC = min(r, g, b)
                    let saturation = maxC == 0 ? 0 : (maxC - minC) / maxC
                    let weight = saturation * saturation

                    totals.weightedR += r * weight
                    totals.weightedG += g * weight
                    totals.weightedB += b * weight
                    totals.weight += weight

                    totals.plainR += r
                    totals.plainG += g
                    totals.plainB += b
                    totals.count += 1
                }
            }

            return totals
        }
    }

    /// Darkens a sampled colour until white text is readable on it.
    ///
    /// Two rules, in order:
    ///
    /// 1. Darken until the colour reaches `targetRatio` against white. This is the readability
    ///    floor and it does the real work.
    /// 2. Cap the brightest channel. Hues with a low luminance weight - reds and blues - can pass
    ///    the contrast test while still being vivid enough to fight the photograph behind them, so
    ///    this stops those washing the card out.
    ///
    /// The cap only ever scales down, so it cannot undo rule 1.
    static func darkenToMeetContrast(r: CGFloat, g: CGFloat, b: CGFloat, targetRatio: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        var (r, g, b) = WMFContrast.darkened(red: r, green: g, blue: b) { red, green, blue in
            WMFContrast.ratioAgainstWhite(red: red, green: green, blue: blue) >= targetRatio
        }

        let maxComponent = max(r, g, b)
        if maxComponent > maxBrightness {
            let scale = maxBrightness / maxComponent
            r *= scale
            g *= scale
            b *= scale
        }

        return (r, g, b)
    }

    /// WCAG contrast ratio of a colour against white. See `WMFContrast`.
    static func contrastAgainstWhite(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
        WMFContrast.ratioAgainstWhite(red: r, green: g, blue: b)
    }
}
