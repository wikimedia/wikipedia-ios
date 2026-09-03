import SwiftUI

/// A slideshow card. Deliberately theme independent: the tint and the text keep the same colors in
/// light, sepia, dark and black, because the artwork they sit with is a single fixed illustration.
struct WMFSlideView: View {

    // MARK: - Properties

    let slide: WMFSlideshowViewModel.Slide

    var fillsAvailableHeight: Bool = true

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum Metrics {
        static let cornerRadius: CGFloat = 16
        static let contentPadding: CGFloat = 16
        static let textSpacing: CGFloat = 10
        static let illustrationBottomSpacing: CGFloat = 16

        /// Keeps the artwork close to its designed size on a card that is taller than the design's
        /// 417pt, rather than letting it grow into whatever space the text leaves.
        static let illustrationMaxHeight: CGFloat = 240
    }

    /// The illustration is the card's whole visual identity, so it is the first thing to go when
    /// scaled-up text needs the room.
    private var showsIllustration: Bool {
        slide.illustration != nil && !dynamicTypeSize.isAccessibilitySize
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let illustration = slide.illustration, showsIllustration {
                illustrationView(illustration)
                    // Shrinks to nothing before the text is squeezed, on a short card.
                    .frame(minHeight: 0, maxHeight: Metrics.illustrationMaxHeight)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Metrics.illustrationBottomSpacing)
                    .accessibilityHidden(true)
            }

            text
        }
        .padding(Metrics.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: fillsAvailableHeight ? .infinity : nil, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                .fill(Color(uiColor: slide.backgroundColor))
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(slide.accessibilityIdentifier ?? "")
    }

    @ViewBuilder
    private func illustrationView(_ illustration: WMFSlideshowViewModel.Slide.Illustration) -> some View {
        switch illustration {
        case .image(let image):
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(Color(uiColor: WMFColor.gray700))
        case .asset(let name):
            if let image = UIImage(named: name, in: .module, with: nil) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        case .gif(let name):
            WMFGIFImageView(name)
        }
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: Metrics.textSpacing) {
            Text(slide.title)
                .font(Font(WMFFont.for(.semiboldTitle3, sized: dynamicTypeSize)))
                .foregroundStyle(Color(uiColor: WMFColor.gray700))

            if let subtitle = slide.subtitle {
                Text(subtitle)
                    .font(Font(WMFFont.for(.body, sized: dynamicTypeSize)))
                    .foregroundStyle(Color(uiColor: WMFColor.gray700))
            }
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Slide") {
    WMFSlideView(
        slide: .init(
            illustration: .gif(name: "clock_2"),
            backgroundColor: WMFColor.yellow100,
            title: "See your [X] reading days come together in Year in Review",
            subtitle: "Once a year, your reading days come back as a look at where the year took you, ready to share."
        )
    )
    .frame(width: 320, height: 417)
    .padding()
}
