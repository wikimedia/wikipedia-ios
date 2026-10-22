import SwiftUI

/// The last screen of Year in Review: a sky with an illustration, a thank you, an optional share
/// button, and a row of cards.
public struct WMFYearInReviewEndView: View {

    @ObservedObject private var appEnvironment = WMFAppEnvironment.current
    @ObservedObject private var viewModel: WMFYearInReviewEndViewModel

    /// The puzzle piece from the design. Without it, the space stays empty.
    private let illustration: Image?

    /// The space the navigation bar takes at the top. The sky still runs under the bar.
    private let topInset: CGFloat

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    /// From the top of the screen to where the sky reaches the dark navy.
    private static let skyHeight: CGFloat = 380

    private static let illustrationSize = CGSize(width: 137, height: 133)

    public init(viewModel: WMFYearInReviewEndViewModel, illustration: Image? = nil, topInset: CGFloat = 0) {
        self.viewModel = viewModel
        self.illustration = illustration
        self.topInset = topInset
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                hero
                WMFCardCarouselView(items: viewModel.cards) { card in
                    cardView(card)
                }
                WMFCardCarouselView(items: viewModel.cards) { card in
                    cardView(card)
                }
                WMFCardCarouselView(items: viewModel.cards) { card in
                    cardView(card)
                }
                WMFCardCarouselView(items: viewModel.cards) { card in
                    cardView(card)
                }
                WMFCardCarouselView(items: viewModel.cards) { card in
                    cardView(card)
                }
                WMFCardCarouselView(items: viewModel.cards) { card in
                    cardView(card)
                }
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
                .padding(.top, 30)

            Text(viewModel.headline.localizedUppercase)
                .font(Font(WMFFont.for(.boldTitle1)))
                .foregroundColor(Color(uiColor: WMFColor.white))
                .multilineTextAlignment(.center)
                .padding(.top, 32)

            Text(viewModel.body)
                .font(Font(WMFFont.for(.body)))
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

    /// The sky, then the page color below it. It runs under the status bar and navigation bar.
    private var sky: some View {
        VStack(spacing: 0) {
            LinearGradient(
                stops: WMFYearInReviewEndViewModel.skyGradientStops.map {
                    Gradient.Stop(color: Color(uiColor: $0.color), location: $0.location)
                },
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Self.skyHeight)

            Color(uiColor: WMFYearInReviewEndViewModel.pageBackgroundColor)
        }
        .ignoresSafeArea(edges: .top)
    }

    @ViewBuilder
    private var illustrationView: some View {
        if let illustration {
            illustration
                .resizable()
                .scaledToFit()
                .frame(width: Self.illustrationSize.width, height: Self.illustrationSize.height)
                .accessibilityHidden(true)
        } else {
            Color.clear
                .frame(width: Self.illustrationSize.width, height: Self.illustrationSize.height)
        }
    }

    /// The soft light under the illustration.
    private var glow: some View {
        Ellipse()
            .fill(Color(uiColor: WMFColor.white))
            .frame(width: 108, height: 5)
            .blur(radius: 1.5)
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
                .font(Font(WMFFont.for(.boldTitle3)))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)

            Text(card.body)
                .font(Font(WMFFont.for(.callout)))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            ctaButton(
                title: card.buttonTitle,
                icon: nil,
                fill: Color(uiColor: theme.link),
                foreground: Color(uiColor: theme.paperBackground)
            ) {
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
