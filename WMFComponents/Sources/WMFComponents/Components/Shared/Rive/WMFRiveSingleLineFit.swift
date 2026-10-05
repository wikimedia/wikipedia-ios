import UIKit

/// Keeps one text run on one line. A text box in the .riv that does not grow wraps a long value,
/// and the second line draws on top of the content below it. When the value is too wide, the app
/// makes the font size and the line height smaller in a global view model of the file.
public nonisolated struct WMFRiveSingleLineFit: Sendable, Hashable {

    /// The text run to measure. Its value comes from the text of the slide.
    public let text: WMFRiveText
    /// The name of the font asset in the .riv that draws the run. The app supplies a system font for it.
    public let fontAssetName: String
    /// The width of the text box, in artboard units.
    public let maximumWidth: Double
    /// The global view model that holds the size of the run.
    public let globalViewModelName: String
    public let fontSize: WMFRiveNumber
    public let lineHeight: WMFRiveNumber

    public init(
        text: WMFRiveText,
        fontAssetName: String,
        maximumWidth: Double,
        globalViewModelName: String,
        fontSize: WMFRiveNumber,
        lineHeight: WMFRiveNumber
    ) {
        self.text = text
        self.fontAssetName = fontAssetName
        self.maximumWidth = maximumWidth
        self.globalViewModelName = globalViewModelName
        self.fontSize = fontSize
        self.lineHeight = lineHeight
    }

    /// Keep this fraction of the box free, because the shaping in Rive and in UIKit is not the same.
    /// The measured width is usually larger than the width that Rive draws. On the total articles
    /// slide (October 2026) Rive drew the number about 12% narrower, so a fitted number is a
    /// little smaller than necessary, but it does not wrap.
    static let widthMargin = 0.04

    /// The scale for the font size and the line height, from 0 to 1. It is 1 when the value fits.
    /// - Parameters:
    ///   - textWidth: The width of the value at `fontSize`, in artboard units.
    static func scale(textWidth: Double, maximumWidth: Double) -> Double {
        let availableWidth = maximumWidth * (1 - widthMargin)
        guard textWidth > availableWidth, textWidth > 0 else {
            return 1
        }
        return availableWidth / textWidth
    }

    /// The width of `value` at `fontSize` with the font that the app supplies for `fontAssetName`.
    /// Rive scales the outlines of the supplied font, so measure at the size of the supplied font
    /// and scale linearly. A larger system font would select a different optical size.
    /// `nil` if the app does not supply a font for the asset.
    @MainActor
    static func width(of value: String, fontAssetName: String, fontSize: Double) -> Double? {
        guard let font = WMFRiveWorkerProvider.substituteFont(forAssetNamed: fontAssetName), font.pointSize > 0 else {
            return nil
        }
        let measured = (value as NSString).size(withAttributes: [.font: font]).width
        return Double(measured) * fontSize / Double(font.pointSize)
    }
}
