import SwiftUI
import UIKit

/// Picks a background colour from a photograph that white text stays readable on.
///
/// Kept here rather than inline in a feature so the colour rules live in one place and can be unit
/// tested. Not an extension on `UIImage`: this is one opinionated algorithm, not a general
/// capability of images, and offering it as `someImage.sampledColor()` would invite callers to
/// expect "the average colour" and get something quite different.
///
/// An actor for two reasons. First, an actor never runs on the main actor, so the pixel work cannot
/// drift back onto the main thread if the package's concurrency defaults change later. Second, it
/// serialises the sampling: several cards can scroll in at once, and we do not want each of them
/// walking a large image at the same time.
actor WMFImageColorSampler {

    static let shared = WMFImageColorSampler()

    // MARK: - Tuning

    /// Contrast the resulting colour must reach against white text.
    ///
    /// Slightly stricter than WCAG AA for large text, which asks for 4.5:1.
    private static let whiteTextContrastTarget: CGFloat = 5

    /// Ceiling for the brightest channel, so a vivid hue cannot overpower the photograph.
    ///
    /// Deliberately high enough for the sampled hue to read: the point of the feature is that the
    /// card takes its colour from the image. A low cap makes every card look the same near-black.
    private static let maxBrightness: CGFloat = 0.55

    /// Read one pixel in every `samplingStride` x `samplingStride` block rather than all of them.
    ///
    /// Averaged over hundreds of thousands of pixels this is indistinguishable from reading every
    /// one, and it keeps the cost of covering the whole image low.
    private static let samplingStride = 2

    private static let darkeningStep: CGFloat = 0.95
    private static let maxDarkeningSteps = 200

    // MARK: - Public

    /// Takes image `Data` rather than a `UIImage` because `UIImage` is not `Sendable` and so cannot
    /// be handed to another concurrency domain. The image is decoded here instead.
    func sampledColor(from imageData: Data) -> Color? {
        guard let image = UIImage(data: imageData) else { return nil }
        return Self.sampledColor(from: image)
    }

    // MARK: - The algorithm
    //
    // Static and self-contained so it can be exercised directly from tests without an actor hop.

    /// The whole image is sampled, not a crop of it: the colour should represent the article's
    /// photograph rather than only the part behind the text.
    static func sampledColor(from image: UIImage) -> Color? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Colourful pixels count for more than dull ones, so a small vivid area beats a large flat
        // one. Squaring the saturation sharpens that preference.
        var weightedR: CGFloat = 0
        var weightedG: CGFloat = 0
        var weightedB: CGFloat = 0
        var totalWeight: CGFloat = 0

        var totalR: CGFloat = 0
        var totalG: CGFloat = 0
        var totalB: CGFloat = 0
        var sampledPixelCount = 0

        let step = samplingStride * bytesPerPixel

        for y in stride(from: 0, to: height, by: samplingStride) {
            let rowStart = y * bytesPerRow
            for i in stride(from: rowStart, to: rowStart + bytesPerRow, by: step) {
                let r = CGFloat(rawData[i]) / 255
                let g = CGFloat(rawData[i + 1]) / 255
                let b = CGFloat(rawData[i + 2]) / 255

                let maxC = max(r, g, b)
                let minC = min(r, g, b)
                let saturation = maxC == 0 ? 0 : (maxC - minC) / maxC
                let weight = saturation * saturation

                weightedR += r * weight
                weightedG += g * weight
                weightedB += b * weight
                totalWeight += weight

                totalR += r
                totalG += g
                totalB += b
                sampledPixelCount += 1
            }
        }

        guard sampledPixelCount > 0 else { return nil }

        var r: CGFloat
        var g: CGFloat
        var b: CGFloat

        if totalWeight > 0 {
            r = weightedR / totalWeight
            g = weightedG / totalWeight
            b = weightedB / totalWeight
        } else {
            // Nothing colourful at all - greyscale, or fully transparent. Fall back to a plain
            // average, halved, so these images settle on a neutral dark rather than an invented hue.
            let pixelCount = CGFloat(sampledPixelCount)
            r = (totalR / pixelCount) * 0.5
            g = (totalG / pixelCount) * 0.5
            b = (totalB / pixelCount) * 0.5
        }

        (r, g, b) = darkenToMeetContrast(r: r, g: g, b: b, targetRatio: whiteTextContrastTarget)
        return Color(red: r, green: g, blue: b)
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
        var r = r, g = g, b = b

        // Bounded: darkening always raises contrast towards its 21:1 ceiling, so this terminates
        // for any reachable target. The limit only guards against a target above that ceiling.
        var iterations = 0
        while contrastAgainstWhite(r: r, g: g, b: b) < targetRatio && iterations < maxDarkeningSteps {
            r *= darkeningStep
            g *= darkeningStep
            b *= darkeningStep
            iterations += 1
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

    /// WCAG contrast ratio of a colour against white.
    static func contrastAgainstWhite(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
        1.05 / (relativeLuminance(r: r, g: g, b: b) + 0.05)
    }

    /// WCAG relative luminance.
    private static func relativeLuminance(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
        func linearize(_ c: CGFloat) -> CGFloat {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }
}
