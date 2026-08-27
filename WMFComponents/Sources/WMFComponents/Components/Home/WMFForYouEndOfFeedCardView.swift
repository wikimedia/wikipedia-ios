import SwiftUI

/// The card at the end of the For You feed.
///
/// It is one page of the vertical paging stack in `WMFForYouView`, so the header chrome (logo,
/// tab switcher, language menu, notification bell) stays on top of it the same way it does over
/// article cards. It deliberately has no three dot menu, no page dots and no reason label.
///
/// The same layout also serves as the feed's empty state (`variant: .emptyFeed`) when there is no
/// personalized content at all, with its own illustration and copy.
///
/// Requires `WMFForYouCardMetrics` in WMFForYouView.swift to be internal rather than private,
/// so the card leaves the same room for the tab bar as every other page.
struct WMFForYouEndOfFeedCardView: View {

    @ObservedObject var viewModel: WMFForYouEndOfFeedCardViewModel

    private var variant: WMFForYouEndOfFeedCardViewModel.Variant { viewModel.variant }

    /// The For You palette, which stays dark whatever theme the app uses (`WMFTheme.forYou`).
    let theme: WMFTheme

    /// Where the header bar ends, so the content never slides under the chrome.
    @Environment(\.forYouHeaderBottom) private var headerBottom: CGFloat

    private var title: String {
        switch variant {
        case .endOfFeed: return viewModel.title
        case .emptyFeed: return viewModel.emptyTitle
        }
    }

    private var subtitle: String {
        switch variant {
        case .endOfFeed: return viewModel.subtitle
        case .emptyFeed: return viewModel.emptySubtitle
        }
    }

    private var waysTitle: String {
        switch variant {
        case .endOfFeed: return viewModel.waysToKeepLearningTitle
        case .emptyFeed: return viewModel.waysToGetStartedTitle
        }
    }

    private var addInterestsLinkText: String {
        switch variant {
        case .endOfFeed: return viewModel.addInterestsLinkText
        case .emptyFeed: return viewModel.emptyAddInterestsLinkText
        }
    }
    
    @ViewBuilder
    private var illustration: some View {
        switch variant {
        case .endOfFeed:
            WMFGIFImageView("onboarding_puzzle")
        case .emptyFeed:
            if let uiImage = UIImage(named: "empty_feed", in: Bundle.module, compatibleWith: nil) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 32) {
                illustration
                    .frame(maxWidth: .infinity)
                    .frame(height: variant == .endOfFeed ? 175 : 105)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(title)
                            .font(Font(WMFFont.for(.georgiaTitle1)))
                            .foregroundStyle(Color(uiColor: theme.text))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(subtitle)
                            .font(Font(WMFFont.for(.body)))
                            .foregroundStyle(Color(uiColor: theme.text))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(waysTitle)
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                            .foregroundStyle(Color(uiColor: theme.text))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)

                    linkRow(
                        symbol: .sliderHorizontal3,
                        format: viewModel.addInterestsFormat,
                        linkText: addInterestsLinkText,
                        action: { viewModel.onTapAddInterests?() }
                    )
                    linkRow(
                        symbol: .person2Fill,
                        format: viewModel.communityFormat,
                        linkText: viewModel.communityLinkText,
                        action: { viewModel.onTapCommunity?() }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, WMFForYouCardMetrics.contentTopInset(
                headerBottom: headerBottom,
                cardTop: geometry.frame(in: .global).minY
            ))
            .padding(.bottom, WMFForYouCardMetrics.contentBottomInset(safeAreaBottom: WMFForYouCardMetrics.windowSafeAreaBottom))
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomLeading)
            .background(Color(uiColor: WMFColor.green800))
            .ignoresSafeArea()
        }
    }

    /// One suggested action row: an icon and a sentence with an underlined tappable phrase.
    ///
    /// The format carries a `%1$@` placeholder and the link text fills it, the same split
    /// `WMFForYouHeaderLabelView` uses. Keeping them as two localized strings lets translators
    /// reorder the sentence without breaking the underline.
    @ViewBuilder
    private func linkRow(symbol: WMFSFSymbolIcon, format: String, linkText: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let image = WMFSFSymbolIcon.for(symbol: symbol, font: .body) {
                    Image(uiImage: image)
                }
                label(format: format, linkText: linkText)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(Color(uiColor: theme.text))
        }
    }

    private func label(format: String, linkText: String) -> Text {
        let font = Font(WMFFont.for(.body))

        let placeholder = format.contains("%1$@") ? "%1$@" : "%@"
        let parts = format.components(separatedBy: placeholder)

        guard parts.count == 2 else {
            return Text(String.localizedStringWithFormat(format, linkText)).font(font)
        }

        return Text(parts[0]).font(font)
            + Text(linkText).font(font).underline()
            + Text(parts[1]).font(font)
    }
}
