import SwiftUI
import WMFData

// MARK: - Card Metrics

private enum WMFForYouGamesTeaserMetrics {

    /// 16 rather than the 20 the article cards use, so the event cards line up with the ones on the
    /// game screen.
    static let horizontalPadding: CGFloat = 16
    static let titleBottomGap: CGFloat = 16
    static let cardSpacing: CGFloat = 12

    private static let compactScreenHeight: CGFloat = 700
    private static let compactCardHeight: CGFloat = 170
    private static let regularCardHeight: CGFloat = 192

    /// The same two heights `WMFWhichCameFirstView` uses, so a card is the size the reader sees a
    /// moment later in the game itself.
    static func cardHeight(forScreenHeight height: CGFloat) -> CGFloat {
        height < compactScreenHeight ? compactCardHeight : regularCardHeight
    }
}

// MARK: - Games Teaser Card

/// Card 1 of the Games Teaser module: the first question of the day's game, with a CTA into it.
///
/// The two event cards are `WMFWhichCameFirstCardView`, the same view the game screen uses, in its
/// unselected and unrevealed state — so no date pill and no result icon, and the answer stays
/// hidden.
///
/// Sized and inset like the article cards, so it pages with them: `WMFForYouCardMetrics` keeps the
/// content clear of the floating header bar and of the page dots.
public struct WMFForYouGamesTeaserCardView: View {

    @ObservedObject public var viewModel: WMFForYouGamesTeaserCardViewModel
    @Environment(\.forYouHeaderBottom) private var headerBottom: CGFloat

    /// Fixed, not taken from `WMFAppEnvironment`: the card is dark whatever the app appearance is,
    /// the same way the empty state and the end of feed card are.
    private let theme: WMFTheme = .forYou

    public init(viewModel: WMFForYouGamesTeaserCardViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color(uiColor: WMFColor.green700)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()

                content(screenHeight: geometry.size.height)
                    .padding(.horizontal, WMFForYouGamesTeaserMetrics.horizontalPadding)
                    .padding(.top, WMFForYouCardMetrics.contentTopInset(
                        headerBottom: headerBottom,
                        cardTop: geometry.frame(in: .global).minY
                    ))
                    .padding(.bottom, WMFForYouCardMetrics.contentBottomInset(safeAreaBottom: WMFForYouCardMetrics.windowSafeAreaBottom))
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .ignoresSafeArea()
            .clipped()
            .environment(\.layoutDirection, viewModel.project.isRTL ? .rightToLeft : .leftToRight)
            .contentShape(Rectangle())
            .onTapGesture { viewModel.onTapCard?() }
            .onAppear { viewModel.load() }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(viewModel.accessibilityLabel)
            .accessibilityAction { viewModel.onTapCard?() }
            .accessibilityAction(named: Text(viewModel.playButtonTitle)) { viewModel.onTapPlay?() }
            .accessibilityAction(named: Text(viewModel.shareTitle)) {
                guard viewModel.isShareAvailable else { return }
                viewModel.onShare?()
            }
            .accessibilityAction(named: Text(viewModel.hideCardTitle)) { viewModel.onHideCard?() }
            .accessibilityAction(named: Text(viewModel.hideModuleTitle)) { viewModel.onHideModule?() }
            .accessibilityAction(named: Text(viewModel.customizeInterestsTitle)) { viewModel.onCustomizeInterests?() }
        }
    }

    @ViewBuilder
    private func content(screenHeight: CGFloat) -> some View {
        switch viewModel.loadState {
        case .loading:
            ProgressView()
                .tint(Color(uiColor: WMFColor.white))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .unavailable:
            // The module hides itself off `loadState`; nothing to draw in the meantime.
            EmptyView()
        case .loaded:
            loadedContent(screenHeight: screenHeight)
        }
    }

    private func loadedContent(screenHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Text(viewModel.gameTitle)
                    .font(Font(WMFFont.for(.georgiaTitle1)))
                    .foregroundStyle(Color(uiColor: WMFColor.white))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                overflowMenu
            }

            VStack(spacing: 32) {
                ForEach(viewModel.eventCardViewModels) { cardViewModel in
                    WMFWhichCameFirstCardView(
                        viewModel: cardViewModel,
                        cardHeight: WMFForYouGamesTeaserMetrics.cardHeight(forScreenHeight: screenHeight),
                        theme: theme
                    ) {
                        viewModel.onTapCard?()
                    }
                }
            }

            playButton
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - CTA

    private var playButton: some View {
        Button {
            viewModel.onTapPlay?()
        } label: {
            Text(viewModel.playButtonTitle)
                .font(Font(WMFFont.for(.body)))
                .foregroundStyle(Color(uiColor: WMFColor.white))
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .overlay(
                    Capsule().strokeBorder(Color(uiColor: WMFColor.white), lineWidth: 1)
                )
        }
        .accessibilityHidden(true)
    }

    // MARK: - Overflow Menu

    /// Save is dropped for this module, and Share appears only once the game is finished.
    private var overflowMenu: some View {
        Menu {
            if viewModel.isShareAvailable {
                Button { viewModel.onShare?() } label: {
                    Label {
                        Text(viewModel.shareTitle)
                    } icon: {
                        Image(uiImage: WMFSFSymbolIcon.for(symbol: .squareAndArrowUp) ?? UIImage())
                    }
                }
            }
            Button(role: .destructive) { viewModel.onHideCard?() } label: {
                Label {
                    Text(viewModel.hideCardTitle)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .eyeSlash) ?? UIImage())
                }
            }
            Button(role: .destructive) { viewModel.onHideModule?() } label: {
                Label {
                    Text(viewModel.hideModuleTitle)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .xmarkCircle) ?? UIImage())
                }
            }
            Button { viewModel.onCustomizeInterests?() } label: {
                Label {
                    Text(viewModel.customizeInterestsTitle)
                } icon: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .sliderHorizontal3) ?? UIImage())
                }
            }
        } label: {
            Image(uiImage: WMFSFSymbolIcon.for(symbol: .ellipsis) ?? UIImage())
                .foregroundStyle(Color(uiColor: WMFColor.white))
                .padding(8)
        }
        .accessibilityLabel(WMFHomeLocalizedStrings.moreOptions)
    }
}
