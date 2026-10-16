import UIKit

/// Keeps a text run in the .riv to a maximum number of lines. When the value has too many lines,
/// the app makes the font size and the line height smaller in a global view model of the file.
///
/// A text box that does not grow wraps a long value on top of the content below it. A text box
/// that grows can push the content past the bottom of the slide.
public nonisolated struct WMFRiveTextFit: Sendable, Hashable {

    /// The text run to measure. Its value comes from the text of the slide.
    public let text: WMFRiveText
    /// The name of the font asset in the .riv that draws the run. The app supplies a system font for it.
    public let fontAssetName: String
    /// The width of the text box, in artboard units.
    public let maximumWidth: Double
    public let maximumLines: Int
    /// The smallest scale. A value that does not fit at this scale uses it anyway.
    public let minimumScale: Double
    /// Fits in the same group use the smallest scale of the group, so their runs keep their proportions.
    public let group: String?
    /// The global view model that holds the size of the run.
    public let globalViewModelName: String
    public let fontSize: WMFRiveNumber
    public let lineHeight: WMFRiveNumber

    public init(
        text: WMFRiveText,
        fontAssetName: String,
        maximumWidth: Double,
        maximumLines: Int,
        minimumScale: Double = 0,
        group: String? = nil,
        globalViewModelName: String,
        fontSize: WMFRiveNumber,
        lineHeight: WMFRiveNumber
    ) {
        self.text = text
        self.fontAssetName = fontAssetName
        self.maximumWidth = maximumWidth
        self.maximumLines = maximumLines
        self.minimumScale = minimumScale
        self.group = group
        self.globalViewModelName = globalViewModelName
        self.fontSize = fontSize
        self.lineHeight = lineHeight
    }

    /// Keep this fraction of the box free, because the shaping in Rive and in UIKit is not the same.
    /// The measured width is usually larger than the width that Rive draws. On the total articles
    /// slide (October 2026) Rive drew the number about 12% narrower, so a fitted number is a
    /// little smaller than necessary, but it does not wrap.
    static let widthMargin = 0.04

    /// The step of the search for a scale that fits more than one line.
    static let scaleStep = 0.02

    /// The scale for the font size and the line height, from `minimumScale` to 1. It is 1 when the
    /// value fits at `fontSize`. `nil` if the app does not supply a font for the asset.
    @MainActor
    func scale(for value: String, fontSize: Double) -> Double? {
        guard let font = WMFRiveWorkerProvider.substituteFont(forAssetNamed: fontAssetName), font.pointSize > 0 else {
            return nil
        }
        let availableWidth = maximumWidth * (1 - Self.widthMargin)

        if maximumLines == 1 {
            let width = Self.width(of: value, font: font, fontSize: fontSize)
            return max(minimumScale, Self.singleLineScale(textWidth: width, availableWidth: availableWidth))
        }

        var scale = 1.0
        while scale > minimumScale,
              Self.lineCount(of: value, font: font, fontSize: fontSize * scale, availableWidth: availableWidth) > maximumLines {
            scale -= Self.scaleStep
        }
        return max(minimumScale, scale)
    }

    /// The scale that makes a line of `textWidth` as wide as `availableWidth`, or 1 if it fits.
    static func singleLineScale(textWidth: Double, availableWidth: Double) -> Double {
        guard textWidth > availableWidth, textWidth > 0 else {
            return 1
        }
        return availableWidth / textWidth
    }

    /// Rive scales the outlines of the supplied font, so measure at the size of the supplied font
    /// and scale linearly. A larger system font would select a different optical size.
    static func width(of value: String, font: UIFont, fontSize: Double) -> Double {
        let measured = (value as NSString).size(withAttributes: [.font: font]).width
        return Double(measured) * fontSize / Double(font.pointSize)
    }

    /// The number of lines of `value` at `fontSize` in a box of `availableWidth`. The box width
    /// scales the other way to the font, so the measurement stays at the size of the supplied font.
    static func lineCount(of value: String, font: UIFont, fontSize: Double, availableWidth: Double) -> Int {
        guard !value.isEmpty, fontSize > 0 else {
            return 0
        }
        let width = availableWidth * Double(font.pointSize) / fontSize
        let bounds = (value as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: [.font: font],
            context: nil
        )
        return Int((bounds.height / font.lineHeight).rounded())
    }
}
