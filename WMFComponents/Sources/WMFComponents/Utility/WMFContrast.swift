import SwiftUI
import UIKit

/// The WCAG contrast arithmetic, and the rule it serves on a For You card.

/// The package puts every type on the main actor by default. This enum holds no state and only does
/// arithmetic, thus it is `nonisolated`: the image sampler is an actor and calls it away from the
/// main actor, and a view calls it on the main actor.
///
/// Enum so it can't be instantiated
nonisolated enum WMFContrast {

    // MARK: - The rule on a card

    /// WCAG AA for text smaller than 18 points.
    static let minimumContrastRatio: CGFloat = 4.5


    static let preferredOpacity: CGFloat = 0.75

    /// The dimmest text drawn on the gradient. The header label and the extract use white at 0.8.
    static let textOpacity: CGFloat = 0.8

    private static let opacityStep: CGFloat = 0.05

    struct Stop: Equatable {
        let color: Color
        let opacity: CGFloat
    }

    /// The stop to use where the text begins.
    static func stop(
        for color: Color,
        minimumRatio: CGFloat = minimumContrastRatio,
        preferredOpacity: CGFloat = preferredOpacity,
        textOpacity: CGFloat = textOpacity
    ) -> Stop {
        var (red, green, blue) = components(of: color)
        var opacity = min(max(preferredOpacity, 0), 1)

        func passes(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> Bool {
            contrastOverWhite(
                red: red,
                green: green,
                blue: blue,
                opacity: opacity,
                textOpacity: textOpacity
            ) >= minimumRatio
        }

        (red, green, blue) = darkened(red: red, green: green, blue: blue, until: passes)

        while !passes(red, green, blue) && opacity < 1 {
            opacity = min(1, opacity + opacityStep)
        }

        return Stop(color: Color(red: red, green: green, blue: blue), opacity: opacity)
    }

    static func contrastOverWhite(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        opacity: CGFloat,
        textOpacity: CGFloat = textOpacity
    ) -> CGFloat {
        let backdropRed = red * opacity + (1 - opacity)
        let backdropGreen = green * opacity + (1 - opacity)
        let backdropBlue = blue * opacity + (1 - opacity)

        let text = { (channel: CGFloat) in textOpacity + (1 - textOpacity) * channel }

        return ratio(
            relativeLuminance(red: text(backdropRed), green: text(backdropGreen), blue: text(backdropBlue)),
            relativeLuminance(red: backdropRed, green: backdropGreen, blue: backdropBlue)
        )
    }

    // MARK: - WCAG arithmetic

    /// How much a colour loses on each pass of `darkened(red:green:blue:until:)`.
    static let darkeningStep: CGFloat = 0.95
    
    static let maxDarkeningSteps = 200

    static func relativeLuminance(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
        func linearize(_ channel: CGFloat) -> CGFloat {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(red) + 0.7152 * linearize(green) + 0.0722 * linearize(blue)
    }

    static func ratio(_ first: CGFloat, _ second: CGFloat) -> CGFloat {
        let lighter = max(first, second) + 0.05
        let darker = min(first, second) + 0.05
        return lighter / darker
    }

    /// The contrast white text reaches on a colour.
    static func ratioAgainstWhite(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
        ratio(1, relativeLuminance(red: red, green: green, blue: blue))
    }

    static func darkened(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        until passes: (CGFloat, CGFloat, CGFloat) -> Bool
    ) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        var red = red
        var green = green
        var blue = blue

        var steps = 0
        while !passes(red, green, blue) && steps < maxDarkeningSteps {
            red *= darkeningStep
            green *= darkeningStep
            blue *= darkeningStep
            steps += 1
        }

        return (red, green, blue)
    }

    private static func components(of color: Color) -> (CGFloat, CGFloat, CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return (0, 0, 0)
        }

        return (red, green, blue)
    }
}
