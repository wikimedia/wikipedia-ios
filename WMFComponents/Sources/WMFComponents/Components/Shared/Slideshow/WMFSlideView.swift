import SwiftUI

struct WMFSlideView: View {

    // MARK: - Properties

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let slide: WMFSlideshowViewModel.Slide
    var theme: WMFTheme?

    var fillsAvailableHeight: Bool = true

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum Metrics {
        static let cornerRadius: CGFloat = 12
        static let contentPadding: CGFloat = 16
        static let textSpacing: CGFloat = 4
        static let imageBottomSpacing: CGFloat = 16
    }

    private var resolvedTheme: WMFTheme {
        theme ?? appEnvironment.theme
    }

    private var backgroundUIColor: UIColor {
        slide.backgroundColor ?? resolvedTheme.midBackground
    }
// TEMP code to be fixed
    private var cardTheme: WMFTheme {
        let resolved = backgroundUIColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: resolvedTheme.userInterfaceStyle))

        return resolved.wmfIsLight ? .light : .dark
    }

    private var showsImage: Bool {
        slide.image != nil && !dynamicTypeSize.isAccessibilitySize
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let image = slide.image, showsImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(minHeight: 0, maxHeight: fillsAvailableHeight ? .infinity : nil)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color(uiColor: cardTheme.text))
                    .padding(.bottom, Metrics.imageBottomSpacing)
                    .accessibilityHidden(true)
            }

            text
        }
        .padding(Metrics.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: fillsAvailableHeight ? .infinity : nil, alignment: .bottom)
        .background(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                .fill(Color(uiColor: backgroundUIColor))
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(slide.accessibilityIdentifier ?? "")
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: Metrics.textSpacing) {
            Text(slide.title)
                .font(Font(WMFFont.for(.boldCallout, sized: dynamicTypeSize)))
                .foregroundStyle(Color(uiColor: cardTheme.text))

            if let subtitle = slide.subtitle {
                Text(subtitle)
                    .font(Font(WMFFont.for(.subheadline, sized: dynamicTypeSize)))
                    .foregroundStyle(Color(uiColor: cardTheme.secondaryText))
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
            image: WMFSFSymbolIcon.for(symbol: .clock, font: .xxlTitleBold),
            backgroundColor: WMFColor.beige300,
            title: "See your [X] reading days come together in Year in Review",
            subtitle: "Once a year, your reading days come back as a look at where the year took you, ready to share."
        )
    )
    .frame(width: 320, height: 420)
    .padding()
}

private extension UIColor {

    var wmfIsLight: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return true }

        return (0.299 * red + 0.587 * green + 0.114 * blue) > 0.6
    }
}
