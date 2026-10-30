import SwiftUI
import UIKit

/// The image that "Share highlights" on the end screen shares: the title, the crossword, up to five
/// highlights in rows, and the attribution with the W. From the Figma frame of the share image (T437475).
/// The layout mirrors for right-to-left languages. The crossword does not.
public struct WMFYearInReviewHighlightsShareView: View {

    private let highlights: WMFYearInReviewHighlights

    /// Laid out as on a phone this many points wide, then scaled up to the image. The same width
    /// as the slide image.
    static let size = CGSize(width: 360, height: 640)

    /// 1080 × 1920 pixels, the 9:16 size of the slide image.
    static let renderScale: CGFloat = 3

    // MARK: - Design values

    /// From the Figma design. A pale green.
    static let backgroundColor = UIColor(red: 0.90, green: 0.945, blue: 0.90, alpha: 1)

    private static let sideMargin: CGFloat = 16
    private static let crosswordWidth: CGFloat = 245
    private static let crosswordAspectRatio: CGFloat = 269 / 185
    private static let labelColumnWidth: CGFloat = 148
    private static let rowVerticalPadding: CGFloat = 9
    private static let wHeight: CGFloat = 22

    /// A fixed text size, so the image does not depend on the Dynamic Type setting of the reader.
    private static let traits = UITraitCollection(preferredContentSizeCategory: .large)

    // The design is EB Garamond. Georgia is the fallback if the font cannot load.
    private let titleFont = WMFYearInReviewEndFont.fixed(size: 42)
    private let labelFont = WMFYearInReviewEndFont.fixed(size: 15.5)
    // The design is SF Pro.
    private let numberFont = WMFFont.for(.boldTitle1, compatibleWith: Self.traits).withSize(25)
    private let valueFont = WMFFont.for(.footnote, compatibleWith: Self.traits)
    private let rankFont = WMFFont.for(.caption2, compatibleWith: Self.traits)

    private let textColor = Color(uiColor: WMFColor.black)

    public init(highlights: WMFYearInReviewHighlights) {
        self.highlights = highlights
    }

    /// How much room the content above the footer takes. Long text in some languages does not fit
    /// in the full layout, so the image uses the first of `fits` that does.
    struct Fit {
        /// The size of the crossword, as a fraction of its full size. `nil` hides it.
        let crosswordScale: CGFloat?
        let valueLineLimit: Int
    }

    /// From the most room to the least. The crossword gets smaller, then goes, before any text is
    /// cut. Below half its size, the crossword is too small to read as one.
    static let fits = [
        Fit(crosswordScale: 1, valueLineLimit: 3),
        Fit(crosswordScale: 0.9, valueLineLimit: 3),
        Fit(crosswordScale: 0.8, valueLineLimit: 3),
        Fit(crosswordScale: 0.7, valueLineLimit: 3),
        Fit(crosswordScale: 0.6, valueLineLimit: 3),
        Fit(crosswordScale: 0.5, valueLineLimit: 3),
        Fit(crosswordScale: nil, valueLineLimit: 3),
        Fit(crosswordScale: nil, valueLineLimit: 2),
        Fit(crosswordScale: nil, valueLineLimit: 1)
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .vertical) {
                ForEach(Self.fits.indices, id: \.self) { index in
                    content(fit: Self.fits[index])
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            // If even the last fit is too tall, the content is cut here and does not cover the footer.
            .clipped()

            divider
            footer
        }
        .padding(.horizontal, Self.sideMargin)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(Color(uiColor: Self.backgroundColor))
    }

    private func content(fit: Fit) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(highlights.localizedStrings.title)
                .font(Font(titleFont))
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 40)

            if let crosswordScale = fit.crosswordScale {
                crossword(scale: crosswordScale)
                    .padding(.top, 12)
            } else {
                Spacer()
                    .frame(height: 20)
            }

            rows(valueLineLimit: fit.valueLineLimit)
        }
    }

    // MARK: - Crossword

    private func crossword(scale: CGFloat) -> some View {
        let width = Self.crosswordWidth * scale
        return Image("yir-crossword", bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: width / Self.crosswordAspectRatio)
            .frame(maxWidth: .infinity)
            // The crossword reads the same in every language, so it never mirrors with the layout.
            .environment(\.layoutDirection, .leftToRight)
            .accessibilityHidden(true)
    }

    // MARK: - Rows

    @ViewBuilder
    private func rows(valueLineLimit: Int) -> some View {
        if highlights.articlesRead != nil || highlights.minutesRead != nil {
            divider
            countsRow
        }

        if !highlights.rotation.isEmpty {
            divider
            row(label: highlights.localizedStrings.rotationLabel) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(highlights.rotation.enumerated()), id: \.offset) { index, title in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(verbatim: highlights.localizedStrings.rotationRank(index + 1))
                                .font(Font(rankFont).monospacedDigit())
                            valueText(title, lineLimit: valueLineLimit)
                        }
                    }
                }
            }
        }

        if let rabbitHole = highlights.rabbitHole {
            divider
            row(label: highlights.localizedStrings.rabbitHoleLabel) {
                VStack(alignment: .leading, spacing: 0) {
                    valueText(rabbitHole.firstTitle, lineLimit: valueLineLimit)
                    valueText("↓ \(rabbitHole.lastTitle)", lineLimit: valueLineLimit)
                }
            }
        }

        if let nicheCategory = highlights.nicheCategory {
            divider
            row(label: highlights.localizedStrings.nicheCategoryLabel) {
                valueText(nicheCategory, lineLimit: valueLineLimit)
            }
        }
    }

    /// Articles read at the leading edge and minutes read at the trailing edge. With only one of
    /// them, it sits at the leading edge.
    private var countsRow: some View {
        HStack(alignment: .top, spacing: 12) {
            if let articlesRead = highlights.articlesRead {
                count(label: highlights.localizedStrings.articlesReadLabel, value: articlesRead, alignment: .leading)
            }
            if let minutesRead = highlights.minutesRead {
                count(label: highlights.localizedStrings.minutesReadLabel, value: minutesRead, alignment: highlights.articlesRead == nil ? .leading : .trailing)
            }
        }
        .padding(.vertical, Self.rowVerticalPadding)
    }

    private func count(label: String, value: Int, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 0) {
            labelText(label)
            Text(formatted(value))
                .font(Font(numberFont))
                .foregroundColor(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
    }

    private func row(label: String, @ViewBuilder value: () -> some View) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            labelText(label)
                .frame(width: Self.labelColumnWidth, alignment: .leading)
            value()
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Self.rowVerticalPadding)
    }

    private func labelText(_ text: String) -> some View {
        Text(text)
            .font(Font(labelFont))
            .foregroundColor(textColor)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func valueText(_ text: String, lineLimit: Int) -> some View {
        Text(text)
            .font(Font(valueFont))
            .foregroundColor(textColor)
            .multilineTextAlignment(.leading)
            .lineLimit(lineLimit)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(highlights.localizedStrings.createdWith)
                .font(Font(labelFont))
                .foregroundColor(textColor)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image("W", bundle: .module)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: Self.wHeight)
                .foregroundColor(textColor)
                .accessibilityHidden(true)
        }
        .padding(.top, 10)
        .padding(.bottom, 16)
    }

    // MARK: - Divider

    /// A dotted line across the content.
    private var divider: some View {
        DottedLine()
            .stroke(textColor, style: StrokeStyle(lineWidth: 1, dash: [1, 2]))
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private func formatted(_ number: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: number), number: .decimal)
    }
}

private struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Image

extension WMFYearInReviewHighlightsShareView {

    /// Draws the highlights to an opaque 1080 × 1920 image.
    /// - Parameter layoutDirection: The direction of the app language, so the layout mirrors for
    ///   right-to-left languages.
    @MainActor
    public static func image(for highlights: WMFYearInReviewHighlights, layoutDirection: LayoutDirection) -> UIImage? {
        let view = WMFYearInReviewHighlightsShareView(highlights: highlights)
            .environment(\.layoutDirection, layoutDirection)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: view)
        renderer.scale = renderScale
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

#Preview {
    WMFYearInReviewHighlightsShareView(
        highlights: WMFYearInReviewHighlights(
            articlesRead: 1_253_938,
            minutesRead: 1_253_937,
            rotation: ["Pamela Anderson", "Pamukkale", "History of US science fiction and fantasy magazines to 1950"],
            rabbitHole: .init(firstTitle: "Frida Kahlo", lastTitle: "Diego Rivera"),
            nicheCategory: "Executed female serial killers",
            localizedStrings: .init(
                title: "Wikipedia Year in Review 2026",
                articlesReadLabel: "Number of articles read:",
                minutesReadLabel: "Total minutes read:",
                rotationLabel: "Articles in my rotation:",
                rotationRank: { "(\($0))" },
                rabbitHoleLabel: "Longest rabbit hole:",
                nicheCategoryLabel: "Niche category explored:",
                createdWith: "Created with the Wikipedia app"
            )
        )
    )
}
