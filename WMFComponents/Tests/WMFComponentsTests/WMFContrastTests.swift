import Testing
import SwiftUI
import UIKit
@testable import WMFComponents

/// Covers the rule that white text on a card gradient reaches the AA contrast ratio, even where the
/// photograph below the gradient is at its lightest.
@Suite
struct WMFContrastTests {

    private func components(of color: Color) -> (CGFloat, CGFloat, CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        _ = UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue)
    }

    private func contrast(of stop: WMFContrast.Stop) -> CGFloat {
        let (red, green, blue) = components(of: stop.color)
        return WMFContrast.contrastOverWhite(
            red: red,
            green: green,
            blue: blue,
            opacity: stop.opacity
        )
    }

    /// The title is white, the extract and the header label are white at 0.8. Dimmer text needs a
    /// darker background, thus a gradient measured for white text alone leaves the dimmer text short.
    @Test
    func theRatioIsMeasuredForTheDimmestTextOnTheCard() {
        let color = Color(red: 0.45, green: 0.42, blue: 0.40)
        let stop = WMFContrast.stop(for: color)
        let (red, green, blue) = components(of: stop.color)

        let forDimText = WMFContrast.contrastOverWhite(
            red: red, green: green, blue: blue, opacity: stop.opacity, textOpacity: 0.8
        )
        let forWhiteText = WMFContrast.contrastOverWhite(
            red: red, green: green, blue: blue, opacity: stop.opacity, textOpacity: 1
        )

        #expect(forDimText >= WMFContrast.minimumContrastRatio)
        #expect(forWhiteText > forDimText, "White text can only do better than the text at 0.8")
    }

    /// A backdrop chosen for white text alone is too light for text at 0.8.
    @Test
    func whiteTextAloneIsNotAStrictEnoughTest() {
        // Grey 0.465 is the lightest backdrop on which white text still reaches 4.5.
        let atTheLimit: CGFloat = 0.465

        let forWhiteText = WMFContrast.contrastOverWhite(
            red: atTheLimit, green: atTheLimit, blue: atTheLimit, opacity: 1, textOpacity: 1
        )
        let forDimText = WMFContrast.contrastOverWhite(
            red: atTheLimit, green: atTheLimit, blue: atTheLimit, opacity: 1, textOpacity: 0.8
        )

        #expect(forWhiteText >= 4.5)
        #expect(forDimText < 4.5)
    }

    /// The case the designer reported: this colour reaches 5.2 on its own, which passes the target of
    /// the sampler, but only 3.2 once the gradient lets a light photograph through.
    @Test
    func aColourThatPassesOnItsOwnCanStillFailInTheGradient() {
        let color = Color(red: 0.45, green: 0.42, blue: 0.40)

        let raw = WMFContrast.contrastOverWhite(red: 0.45, green: 0.42, blue: 0.40, opacity: 0.75)

        #expect(raw < WMFContrast.minimumContrastRatio)
        #expect(contrast(of: WMFContrast.stop(for: color)) >= WMFContrast.minimumContrastRatio)
    }

    @Test
    func aColourThatFailsIsDarkened() {
        let color = Color(red: 0.45, green: 0.42, blue: 0.40)
        let (red, green, blue) = components(of: WMFContrast.stop(for: color).color)

        #expect(red < 0.45)
        #expect(green < 0.42)
        #expect(blue < 0.40)
    }

    /// Darkening a colour that already passes would take contrast the app does not need and hide the
    /// photograph for nothing.
    @Test
    func aColourThatAlreadyPassesKeepsItsColourAndOpacity() {
        let color = Color(red: 0.20, green: 0.18, blue: 0.22)
        let stop = WMFContrast.stop(for: color)
        let (red, green, blue) = components(of: stop.color)

        #expect(abs(red - 0.20) < 0.001)
        #expect(abs(green - 0.18) < 0.001)
        #expect(abs(blue - 0.22) < 0.001)
        #expect(stop.opacity == WMFContrast.preferredOpacity)
    }

    /// Below about 0.55 opacity, a white photograph beats even black. Darkening cannot answer that,
    /// thus the gradient must cover more of the photograph.
    @Test
    func theOpacityRisesWhenDarkeningCannotReachTheRatio() {
        let stop = WMFContrast.stop(
            for: Color(red: 0.45, green: 0.42, blue: 0.40),
            preferredOpacity: 0.4
        )

        #expect(stop.opacity > 0.4)
        #expect(contrast(of: stop) >= WMFContrast.minimumContrastRatio)
    }

    @Test
    func theOpacityNeverGoesAboveFull() {
        let stop = WMFContrast.stop(for: Color(red: 1, green: 1, blue: 1), preferredOpacity: 0.1)

        #expect(stop.opacity <= 1)
    }

    /// Every colour a photograph can produce must come back readable.
    @Test(arguments: [
        (1.0, 1.0, 1.0),
        (0.95, 0.92, 0.80),
        (0.60, 0.55, 0.50),
        (0.45, 0.42, 0.40),
        (0.20, 0.18, 0.22),
        (0.0, 0.0, 0.0),
        (0.90, 0.10, 0.10),
        (0.10, 0.90, 0.10),
        (0.10, 0.10, 0.90)
    ])
    func everyColourReachesTheRatio(red: Double, green: Double, blue: Double) {
        let stop = WMFContrast.stop(for: Color(red: red, green: green, blue: blue))

        #expect(contrast(of: stop) >= WMFContrast.minimumContrastRatio)
    }
}
