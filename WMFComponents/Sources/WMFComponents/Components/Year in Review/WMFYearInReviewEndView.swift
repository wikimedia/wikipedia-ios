import SwiftUI

/// The last screen of Year in Review: a sky with an illustration, a thank you, and a row of cards.
public struct WMFYearInReviewEndView: View {

    @ObservedObject private var viewModel: WMFYearInReviewEndViewModel

    /// The space the navigation bar takes at the top. The sky still runs under the bar.
    private let topInset: CGFloat

    // The design is SF Pro bold 36. xxlTitleBold is 40, the closest style.
    private let headlineFont = WMFFont.for(.xxlTitleBold)
    // The design is EB Garamond 16. Georgia is the fallback if the font cannot load.
    private let bodyFont = WMFYearInReviewEndFont.body()
    // The design sets the line height of the body copy to 1.25 times the font size.
    private static let bodyLineHeightMultiple: CGFloat = 1.25
    // The design is SF Pro bold 26. boldTitle1 is 28, the closest style.
    private let cardTitleFont = WMFFont.for(.boldTitle1)

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

    /// The part of the screen width that one card uses. On a wide screen, the hero text uses the same width.
    /// The space on each side is 10%. Thus, on a wide screen the text lines up with the cards.
    private static let contentWidthFraction: CGFloat = 0.8

    /// SwiftUI `lineSpacing` adds space between the lines. Thus, the value is the line height
    /// from the design minus the line height of the font.
    private var bodyLineSpacing: CGFloat {
        max(0, bodyFont.pointSize * Self.bodyLineHeightMultiple - bodyFont.lineHeight)
    }

    /// A regular width covers iPad full screen, and not iPad Split View with a narrow window.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isWide: Bool {
        horizontalSizeClass == .regular
    }

    /// Called when the controls above the screen need another color, because the light part of the
    /// sky scrolled away from under them.
    private let onUsesLightContentChange: ((Bool) -> Void)?

    private static let scrollSpaceName = "yearInReviewEndScroll"

    /// The controls are dark on the light top of the sky. They become light when the part of the sky
    /// under them is darker than this fraction of the sky height, measured from the top.
    private static let lightContentSkyFraction: CGFloat = 0.2

    /// The height of the fade at the bottom of the screen, which hides the cut of the text.
    private static let bottomFadeHeight: CGFloat = 36

    public init(viewModel: WMFYearInReviewEndViewModel, topInset: CGFloat = 0, onUsesLightContentChange: ((Bool) -> Void)? = nil) {
        self.viewModel = viewModel
        self.topInset = topInset
        self.onUsesLightContentChange = onUsesLightContentChange
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                hero
                WMFCardCarouselView(
                    items: viewModel.cards,
                    cardWidthFraction: Self.contentWidthFraction
                ) { card in
                    cardView(card)
                }
            }
            .padding(.bottom, Self.bottomFadeHeight + 24)
            .background(alignment: .top) {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: -proxy.frame(in: .named(Self.scrollSpaceName)).minY
                    )
                }
            }
        }
        .coordinateSpace(name: Self.scrollSpaceName)
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            // The controls sit about `topInset` below the top of the screen.
            let usesLightContent = offset + topInset > WMFYearInReviewEndViewModel.skyHeight * Self.lightContentSkyFraction
            onUsesLightContentChange?(usesLightContent)
        }
        .overlay(alignment: .bottom) {
            // The toolbar has the color of the page, so nothing else marks the bottom edge.
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(uiColor: WMFYearInReviewEndViewModel.pageBackgroundColor).opacity(0), location: 0),
                    Gradient.Stop(color: Color(uiColor: WMFYearInReviewEndViewModel.pageBackgroundColor).opacity(0.6), location: 0.6),
                    Gradient.Stop(color: Color(uiColor: WMFYearInReviewEndViewModel.pageBackgroundColor), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Self.bottomFadeHeight)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        // This scroll view is in the vertical pager. If the content fits, it does not bounce.
        // Thus, a pull down goes to the pager, and the pager shows the last slide.
        // This applies only to the vertical axis. The horizontal card carousel does not change.
        .scrollBounceBehavior(.basedOnSize)
        .background(Color(uiColor: WMFYearInReviewEndViewModel.pageBackgroundColor).ignoresSafeArea())
    }

    // MARK: - Hero

    private var hero: some View {
        horizontalInset(heroContent)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                sky
            }
    }

    /// On a wide screen, the content uses `contentWidthFraction` of the width, in the center.
    /// On a narrow screen, the content has 32 points of space on each side.
    @ViewBuilder
    private func horizontalInset(_ content: some View) -> some View {
        if isWide {
            content
                .containerRelativeFrame(.horizontal) { width, _ in
                    width * Self.contentWidthFraction
                }
        } else {
            content
                .padding(.horizontal, 32)
        }
    }

    private var heroContent: some View {
        VStack(spacing: 0) {
            illustrationView
                .padding(.top, topInset + 80)

            glow
                .padding(.top, 16)

            // The text shows in capital letters. VoiceOver reads the text as written.
            Text(viewModel.headline.localizedUppercase)
                .accessibilityLabel(viewModel.headline)
                .font(Font(headlineFont))
                .foregroundColor(Color(uiColor: WMFColor.white))
                .multilineTextAlignment(.center)
                .padding(.top, 32)

            Text(viewModel.body)
                .font(Font(bodyFont))
                .kerning(0.5)
                .lineSpacing(bodyLineSpacing)
                .foregroundColor(Color(uiColor: WMFColor.white))
                .multilineTextAlignment(.center)
                .padding(.top, 24)
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

    // MARK: - Cards

    private func cardView(_ card: WMFYearInReviewEndViewModel.Card) -> some View {
        VStack(spacing: 18) {
            // The text shows in capital letters. VoiceOver reads the text as written.
            Text(card.title.localizedUppercase)
                .accessibilityLabel(card.title)
                .font(Font(cardTitleFont))
                .foregroundColor(Color(uiColor: WMFTheme.light.text))
                .multilineTextAlignment(.center)

            Text(card.body)
                .font(Font(bodyFont))
                .kerning(0.5)
                .lineSpacing(bodyLineSpacing)
                .foregroundColor(Color(uiColor: WMFTheme.light.text))
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            WMFSmallButton(
                configuration: .init(style: .primary),
                title: card.buttonTitle,
                forceBackgroundColor: WMFTheme.light.link,
                forceForegroundColor: WMFTheme.light.paperBackground
            ) {
                viewModel.didTap(card)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: WMFTheme.light.midBackground))
        )
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


/// EB Garamond for the body copy of the end screen and the highlights image. It is the file that
/// the slides use (#6328). It is registered for this process the first time it is used.
enum WMFYearInReviewEndFont {

    private static let postScriptName = "EBGaramond-Regular"

    private static let isRegistered: Bool = {
        guard let url = Bundle.module.url(forResource: "EBGaramond-Regular", withExtension: "ttf") else {
            return false
        }
        // A font that is already registered gives an error, but `UIFont(name:size:)` still finds it.
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        return true
    }()

    /// 16 pt, scaled with Dynamic Type like the callout style.
    static func body(compatibleWith traitCollection: UITraitCollection = WMFAppEnvironment.current.traitCollection) -> UIFont {
        guard isRegistered, let font = UIFont(name: postScriptName, size: 16) else {
            return WMFFont.for(.georgiaCallout, compatibleWith: traitCollection)
        }
        return UIFontMetrics(forTextStyle: .callout).scaledFont(for: font, compatibleWith: traitCollection)
    }

    /// A fixed size that does not follow Dynamic Type, for images that are shared.
    static func fixed(size: CGFloat) -> UIFont {
        guard isRegistered, let font = UIFont(name: postScriptName, size: size) else {
            return UIFont(name: "Georgia", size: size) ?? UIFont.systemFont(ofSize: size)
        }
        return font
    }
}
