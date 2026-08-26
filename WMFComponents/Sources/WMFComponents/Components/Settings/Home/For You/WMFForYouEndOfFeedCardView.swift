import SwiftUI

/// The card at the end of the For You feed.
///
/// It is one page of the vertical paging stack in `WMFForYouView`, so the header chrome (logo,
/// tab switcher, language menu, notification bell) stays on top of it the same way it does over
/// article cards. It deliberately has no three dot menu, no page dots and no reason label.
///
/// Requires `WMFForYouCardMetrics` in WMFForYouView.swift to be internal rather than private,
/// so the card leaves the same room for the tab bar as every other page.
struct WMFForYouEndOfFeedCardView: View {

    @ObservedObject var viewModel: WMFForYouEndOfFeedViewModel

    /// The For You palette, which stays dark whatever theme the app uses (`WMFTheme.forYou`).
    let theme: WMFTheme

    /// Where the header bar ends, so the content never slides under the chrome.
    @Environment(\.forYouHeaderBottom) private var headerBottom: CGFloat

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)

                WMFGIFImageView("comp")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)

                Spacer(minLength: 32)

                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.title)
                        .font(Font(WMFFont.for(.georgiaTitle1)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer().frame(height: 16)

                    Text(viewModel.subtitle)
                        .font(Font(WMFFont.for(.body)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer().frame(height: 24)

                    Text(viewModel.waysToKeepLearningTitle)
                        .font(Font(WMFFont.for(.boldBody)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)

                Spacer().frame(height: 20)

                VStack(alignment: .leading, spacing: 20) {
                    linkRow(
                        symbol: .sliderHorizontal3,
                        format: viewModel.addInterestsFormat,
                        linkText: viewModel.addInterestsLinkText,
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
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
            .background(Color(uiColor: WMFColor.green800))
            .ignoresSafeArea()
        }
    }

    /// One "Ways to keep learning" row: an icon and a sentence with an underlined tappable phrase.
    ///
    /// The format carries a `%1$@` placeholder and the link text fills it, the same split
    /// `WMFForYouHeaderLabelView` uses. Keeping them as two localized strings lets translators
    /// reorder the sentence without breaking the underline.
    @ViewBuilder
    private func linkRow(symbol: WMFSFSymbolIcon, format: String, linkText: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
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
