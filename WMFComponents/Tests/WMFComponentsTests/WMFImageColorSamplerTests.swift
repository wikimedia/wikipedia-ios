import Testing
import UIKit
import SwiftUI
@testable import WMFComponents

/// The colour rules behind the For You card backgrounds. The readability floor is the part that
/// must not regress: white text sits on whatever this returns.
@MainActor
@Suite
struct WMFImageColorSamplerTests {

    private let contrastTarget: CGFloat = 5
    private let maxBrightness: CGFloat = 0.55

    private func image(_ color: UIColor, size: CGSize = CGSize(width: 20, height: 20)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func components(of color: Color) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }

    // MARK: - Contrast maths

    @Test
    func contrastAgainstWhiteMatchesTheWCAGRange() {
        let white = WMFImageColorSampler.contrastAgainstWhite(r: 1, g: 1, b: 1)
        let black = WMFImageColorSampler.contrastAgainstWhite(r: 0, g: 0, b: 0)

        #expect(abs(white - 1) < 0.01, "White on white is 1:1")
        #expect(abs(black - 21) < 0.1, "Black on white is 21:1")
    }

    // MARK: - Readability floor

    @Test(arguments: [
        (CGFloat(1), CGFloat(0), CGFloat(0)),     // vivid red
        (CGFloat(0), CGFloat(0.2), CGFloat(1)),   // vivid blue
        (CGFloat(1), CGFloat(1), CGFloat(0)),     // yellow, the hardest case
        (CGFloat(0), CGFloat(0.8), CGFloat(0.2)), // green
        (CGFloat(0.9), CGFloat(0.8), CGFloat(0.85)), // pale pastel
        (CGFloat(0.5), CGFloat(0.5), CGFloat(0.5))   // mid grey
    ])
    func everyHueEndsUpReadableUnderWhiteText(input: (CGFloat, CGFloat, CGFloat)) {
        let (r, g, b) = WMFImageColorSampler.darkenToMeetContrast(r: input.0, g: input.1, b: input.2, targetRatio: contrastTarget)
        let contrast = WMFImageColorSampler.contrastAgainstWhite(r: r, g: g, b: b)

        #expect(contrast >= contrastTarget - 0.01, "Got \(contrast):1 for \(input)")
    }

    @Test
    func aVividHueIsCappedRatherThanLeftBright() {
        let (r, g, b) = WMFImageColorSampler.darkenToMeetContrast(r: 1, g: 0, b: 0, targetRatio: contrastTarget)

        #expect(max(r, g, b) <= maxBrightness + 0.001)
        #expect(r > 0.4, "The hue must survive - crushing it to near-black was the old behaviour")
    }

    @Test
    func anAlreadyDarkColourIsLeftAlone() {
        let input: (CGFloat, CGFloat, CGFloat) = (0.05, 0.05, 0.1)
        let (r, g, b) = WMFImageColorSampler.darkenToMeetContrast(r: input.0, g: input.1, b: input.2, targetRatio: contrastTarget)

        #expect(abs(r - input.0) < 0.001)
        #expect(abs(g - input.1) < 0.001)
        #expect(abs(b - input.2) < 0.001)
    }

    // MARK: - Sampling whole images

    @Test
    func aSolidColourImageKeepsItsHue() throws {
        let sampled = try #require(WMFImageColorSampler.sampledColor(from: image(.red)))
        let (r, g, b) = components(of: sampled)

        #expect(r > g && r > b, "A red image must give a red card")
        #expect(WMFImageColorSampler.contrastAgainstWhite(r: r, g: g, b: b) >= contrastTarget - 0.01)
    }

    @Test
    func aGreyscaleImageGivesANeutralColourRatherThanAnInventedHue() throws {
        let sampled = try #require(WMFImageColorSampler.sampledColor(from: image(.gray)))
        let (r, g, b) = components(of: sampled)

        #expect(abs(r - g) < 0.02)
        #expect(abs(g - b) < 0.02)
    }

    @Test
    func aFullyTransparentImageStillProducesAUsableColour() throws {
        let sampled = try #require(WMFImageColorSampler.sampledColor(from: image(.clear)))
        let (r, g, b) = components(of: sampled)

        #expect(WMFImageColorSampler.contrastAgainstWhite(r: r, g: g, b: b) >= contrastTarget - 0.01)
    }

    @Test
    func aSmallVividAreaBeatsALargeDullOne() throws {
        // Mostly light grey with a strip of vivid blue: the weighting is meant to favour the blue.
        let size = CGSize(width: 40, height: 40)
        let composed = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.lightGray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 6))
        }

        let sampled = try #require(WMFImageColorSampler.sampledColor(from: composed))
        let (r, g, b) = components(of: sampled)

        #expect(b > r && b > g, "The vivid strip should set the colour, not the dull majority")
    }
}
