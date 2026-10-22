import SwiftUI

/// The last screen of Year in Review: a sky with an illustration, a thank you, an optional share
/// button, and a row of cards.
public struct WMFYearInReviewEndView: View {

    @ObservedObject private var appEnvironment = WMFAppEnvironment.current
    @ObservedObject private var viewModel: WMFYearInReviewEndViewModel

    /// The space the navigation bar takes at the top. The sky still runs under the bar.
    private let topInset: CGFloat

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    /// The width of the puzzle piece, from the design: the width of the box around the tilted piece.
    /// The height follows from the aspect ratio of the image.
    private static let illustrationWidth: CGFloat = 141.73

    /// How far the puzzle piece sits from the center of the screen, as a fraction of its width.
    ///
    /// In the design, on a screen 360 wide, the box around the tilted piece is 141.73 wide. It sits
    /// 96.22 from the left edge and 122.05 from the right edge, so its center is
    /// (96.22 - 122.05) / 2 = -12.915 from the center of the screen. A fraction of the width stays
    /// right for any width and any screen. Negative is to the left.
    private static let illustrationOffsetRatio: CGFloat = ((96.22 - 122.05) / 2) / 141.73

    public init(viewModel: WMFYearInReviewEndViewModel, topInset: CGFloat = 0) {
        self.viewModel = viewModel
        self.topInset = topInset
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                hero
                WMFCardCarouselView(items: viewModel.cards) { card in
                    cardView(card)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: WMFYearInReviewEndViewModel.pageBackgroundColor).ignoresSafeArea())
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 0) {
            illustrationView
                .padding(.top, topInset + 80)

            glow
                .padding(.top, 16)

            Text(viewModel.headline.localizedUppercase)
                // The design is SF Pro bold 36. xxlTitleBold is 40, the closest style.
                .font(Font(WMFFont.for(.xxlTitleBold)))
                .foregroundColor(Color(uiColor: WMFColor.white))
                .multilineTextAlignment(.center)
                .padding(.top, 32)

            Text(viewModel.body)
                // The design is EB Garamond 16. georgiaCallout is Georgia 16, the closest serif in the app.
                .font(Font(WMFFont.for(.georgiaCallout)))
                .kerning(0.5)
                .foregroundColor(Color(uiColor: WMFColor.white))
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            if viewModel.showsShareHighlights {
                shareButton
                    .padding(.top, 40)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            sky
        }
    }

    /// The sky, then the page color below it. This screen sits inside the slides, which already run
    /// under the status bar and navigation bar, so the sky starts at the top of the page.
    private var sky: some View {
        VStack(spacing: 0) {
            skyGradient
                .frame(height: WMFYearInReviewEndViewModel.skyHeight)

            Color(uiColor: WMFYearInReviewEndViewModel.pageBackgroundColor)
        }
    }

    /// A circular gradient stretched into the ellipse of the design. The circle is 200 points wide,
    /// so scaling by `radius / 100` gives the ellipse its radii.
    private var skyGradient: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = WMFYearInReviewEndViewModel.skyHeight
            let center = WMFYearInReviewEndViewModel.skyGradientCenter
            let radius = WMFYearInReviewEndViewModel.skyGradientRadius

            RadialGradient(
                stops: WMFYearInReviewEndViewModel.skyGradientStops.map {
                    Gradient.Stop(color: Color(uiColor: $0.color), location: $0.location)
                },
                center: .center,
                startRadius: 0,
                endRadius: 100
            )
            .frame(width: 200, height: 200)
            .scaleEffect(x: radius.width * width / 100, y: radius.height * height / 100)
            .position(x: center.x * width, y: center.y * height)
            .frame(width: width, height: height)
            .clipped()
        }
    }

    /// The tilted puzzle piece, from the asset catalog of this module.
    private var illustrationView: some View {
        Image("tiltedpuzzlepiece", bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: Self.illustrationWidth)
            .offset(x: Self.illustrationWidth * Self.illustrationOffsetRatio)
            .accessibilityHidden(true)
    }

    /// The soft light under the illustration, from Figma: an ellipse with a white to light gray
    /// gradient and a slight blur.
    /// Super specific dimensions taken directly from Figma
    private var glow: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(uiColor: WMFColor.white), location: 0.38),
                        Gradient.Stop(color: Color(uiColor: WMFYearInReviewEndViewModel.glowBottomColor), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 98.44653, height: 5.00046)
            .blur(radius: 1.12125)
            .accessibilityHidden(true)
    }

    private var shareButton: some View {
        ctaButton(
            title: viewModel.shareHighlightsButtonTitle,
            icon: WMFSFSymbolIcon.for(symbol: .share),
            fill: Color(uiColor: WMFYearInReviewEndViewModel.shareButtonColor),
            foreground: Color(uiColor: WMFColor.white)
        ) {
            viewModel.didTapShareHighlights?()
        }
    }

    // MARK: - Cards

    private func cardView(_ card: WMFYearInReviewEndViewModel.Card) -> some View {
        VStack(spacing: 16) {
            Text(card.title.localizedUppercase)
                // The design is SF Pro bold 26. boldTitle1 is 28, the closest style.
                .font(Font(WMFFont.for(.boldTitle1)))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)

            Text(card.body)
                // The design is EB Garamond 16. georgiaCallout is Georgia 16, the closest serif in the app.
                .font(Font(WMFFont.for(.georgiaCallout)))
                .kerning(0.5)
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            WMFSmallButton(configuration: .init(style: .primary), title: card.buttonTitle) {
                viewModel.didTap(card)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: theme.midBackground))
        )
    }

    // MARK: - Button

    private func ctaButton(title: String, icon: UIImage?, fill: Color, foreground: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(uiImage: icon)
                        .renderingMode(.template)
                }
                Text(title)
                    .font(Font(WMFFont.for(.boldCallout)))
            }
            .foregroundColor(foreground)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Capsule().fill(fill))
        }
        .buttonStyle(.plain)
    }
}
